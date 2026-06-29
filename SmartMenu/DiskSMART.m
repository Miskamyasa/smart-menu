#import "DiskSMART.h"

#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/storage/nvme/NVMeSMARTLibExternal.h>

@implementation DiskSMARTReading
@end

static NSError *MakeError(NSString *message) {
    return [NSError errorWithDomain:@"SmartMenu.DiskSMART"
                               code:1
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

// NVMe SMART counters are 128-bit; we keep the low 64 bits, which is plenty
// for the lifetime of any consumer drive.
static uint64_t Low64(const uint64_t value[2]) { return value[0]; }

@implementation DiskSMART

+ (DiskSMARTReading *)readWithError:(NSError **)error {
    // Find NVMe SMART-capable devices by property, not by class, so this works
    // across Intel and Apple Silicon controllers.
    CFMutableDictionaryRef subMatch = CFDictionaryCreateMutable(
        kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(subMatch, CFSTR(kIOPropertyNVMeSMARTCapableKey), kCFBooleanTrue);

    CFMutableDictionaryRef matching = CFDictionaryCreateMutable(
        kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(matching, CFSTR(kIOPropertyMatchKey), subMatch);
    CFRelease(subMatch);

    io_iterator_t iterator = IO_OBJECT_NULL;
    // Consumes a reference to `matching`.
    kern_return_t kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator);
    if (kr != KERN_SUCCESS) {
        if (error) *error = MakeError(@"No NVMe SMART-capable device found.");
        return nil;
    }

    DiskSMARTReading *reading = nil;
    io_object_t device = IO_OBJECT_NULL;
    while ((device = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
        reading = [self readFromService:device error:error];
        IOObjectRelease(device);
        if (reading) break;
    }
    IOObjectRelease(iterator);

    if (!reading && error && *error == nil) {
        *error = MakeError(@"Could not read SMART data from the NVMe controller.");
    }
    return reading;
}

+ (DiskSMARTReading *)readFromService:(io_object_t)device error:(NSError **)error {
    IOCFPlugInInterface **plugin = NULL;
    SInt32 score = 0;
    kern_return_t kr = IOCreatePlugInInterfaceForService(
        device, kIONVMeSMARTUserClientTypeID, kIOCFPlugInInterfaceID, &plugin, &score);
    if (kr != KERN_SUCCESS || plugin == NULL) {
        return nil;
    }

    IONVMeSMARTInterface **interface = NULL;
    HRESULT hr = (*plugin)->QueryInterface(
        plugin, CFUUIDGetUUIDBytes(kIONVMeSMARTInterfaceID), (LPVOID *)&interface);
    if (hr != S_OK || interface == NULL) {
        IODestroyPlugInInterface(plugin);
        return nil;
    }

    DiskSMARTReading *reading = nil;
    NVMeSMARTData smart;
    memset(&smart, 0, sizeof(smart));
    if ((*interface)->SMARTReadData(interface, &smart) == kIOReturnSuccess) {
        reading = [DiskSMARTReading new];
        reading.temperatureKelvin = smart.TEMPERATURE;
        reading.availableSpare = smart.AVAILABLE_SPARE;
        reading.percentageUsed = smart.PERCENTAGE_USED;
        reading.dataUnitsRead = Low64(smart.DATA_UNITS_READ);
        reading.dataUnitsWritten = Low64(smart.DATA_UNITS_WRITTEN);
        reading.powerCycles = Low64(smart.POWER_CYCLES);
        reading.powerOnHours = Low64(smart.POWER_ON_HOURS);
        reading.unsafeShutdowns = Low64(smart.UNSAFE_SHUTDOWNS);
        reading.mediaErrors = Low64(smart.MEDIA_ERRORS);
        reading.errorLogEntries = Low64(smart.NUM_ERROR_INFO_LOG_ENTRIES);
        reading.model = [self modelFromInterface:interface];
    }

    (*interface)->Release(interface);
    IODestroyPlugInInterface(plugin);
    return reading;
}

+ (NSString *)modelFromInterface:(IONVMeSMARTInterface **)interface {
    NVMeIdentifyControllerStruct identify;
    memset(&identify, 0, sizeof(identify));
    if ((*interface)->GetIdentifyData(interface, &identify, 0) != kIOReturnSuccess) {
        return @"NVMe SSD";
    }
    NSString *model = [[NSString alloc] initWithBytes:identify.MODEL_NUMBER
                                               length:sizeof(identify.MODEL_NUMBER)
                                             encoding:NSASCIIStringEncoding];
    model = [model stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return model.length > 0 ? model : @"NVMe SSD";
}

@end
