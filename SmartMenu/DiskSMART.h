#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A snapshot of the NVMe SMART / Health Information log (log page 0x02).
@interface DiskSMARTReading : NSObject
@property (nonatomic, copy) NSString *model;
@property (nonatomic) uint16_t temperatureKelvin;
@property (nonatomic) uint8_t availableSpare;       // percent remaining
@property (nonatomic) uint8_t percentageUsed;       // estimated wear, percent
@property (nonatomic) uint64_t dataUnitsRead;       // in 512000-byte units
@property (nonatomic) uint64_t dataUnitsWritten;    // in 512000-byte units
@property (nonatomic) uint64_t powerCycles;
@property (nonatomic) uint64_t powerOnHours;
@property (nonatomic) uint64_t unsafeShutdowns;
@property (nonatomic) uint64_t mediaErrors;
@property (nonatomic) uint64_t errorLogEntries;
@end

/// Reads NVMe SMART data directly via IOKit — no external tools required.
@interface DiskSMART : NSObject
+ (nullable DiskSMARTReading *)readWithError:(NSError * _Nullable * _Nullable)error;
@end

NS_ASSUME_NONNULL_END
