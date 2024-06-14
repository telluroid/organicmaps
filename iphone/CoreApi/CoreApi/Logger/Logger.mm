#import "Logger.h"
#import <OSLog/OSLog.h>

#include "base/logging.hpp"

@interface Logger ()

@property (nonatomic) BOOL fileLoggingEnabled;
@property (nullable, nonatomic, strong) NSString * filePath;
@property (nullable, nonatomic, strong) NSFileHandle * fileHandle;

+ (void)setup;
+ (Logger *)logger;
+ (void)logMessageWithLevel:(base::LogLevel)level src:(base::SrcPoint const &)src message:(std::string const &)message;
+ (base::LogLevel)baseLevel:(LogLevel)level;

@end

NSString * const kLoggerSubsystem = [[NSBundle mainBundle] bundleIdentifier];
NSString * const kLoggerCategory = @"OM";
NSString * const kLogFileName = @"Log.log";

@implementation Logger

+ (void)initialize
{
  if (self == [Logger class])
    [self setup];
}

+ (Logger *)logger {
  static Logger * logger;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    logger = [[self alloc] init];
  });
  return logger;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _fileLoggingEnabled = NO;
    _filePath = nil;
    _fileHandle = nil;
  }
  return self;
}


// MARK: - Public

+ (void)setup {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    SetLogMessageFn(&LogMessage);
    SetAssertFunction(&AssertMessage);
  });
}

+ (void)setFileLoggingEnabled:(BOOL)fileLoggingEnabled {
  LOG(LINFO, ("Set file logging enabled: %@", fileLoggingEnabled ? @"YES" : @"NO"));
  Logger * logger = [self logger];
  NSFileManager * fileManager = [NSFileManager defaultManager];

  if (fileLoggingEnabled) {
    NSString * filePath = [[fileManager temporaryDirectory] URLByAppendingPathComponent:kLogFileName].path;
    if (![fileManager fileExistsAtPath:filePath]) {
      [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    NSFileHandle * fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (fileHandle == nil) {
      LOG(LERROR, ("Failed to open log file for writing"));
      [self setFileLoggingEnabled:NO];
      return;
    }
    logger.filePath = filePath;
    logger.fileHandle = fileHandle;
  } else {
    NSError * error;
    [fileManager removeItemAtPath:logger.filePath error:&error];
    if (error)
      LOG(LERROR, ("Failed to remove log file"));
    [logger.fileHandle closeFile];
    logger.fileHandle = nil;
  }
  logger.fileLoggingEnabled = fileLoggingEnabled;
}

+ (void)log:(LogLevel)level message:(NSString *)message {
  LOG_SHORT([self baseLevel:level], (message.UTF8String));
}

+ (BOOL)canLog:(LogLevel)level {
  return [Logger baseLevel:level] >= base::g_LogLevel;
}

+ (nullable NSURL *)getLogsFileURL {
  Logger * logger = [self logger];
  return logger.fileLoggingEnabled ? [NSURL fileURLWithPath:logger.filePath] : nil;
}

// MARK: - C++ injection

void LogMessage(base::LogLevel level, base::SrcPoint const & src, std::string const & message)
{
  [Logger logMessageWithLevel:level src:src message:message];
  CHECK_LESS(level, base::g_LogAbortLevel, ("Abort. Log level is too serious", level));
}

bool AssertMessage(base::SrcPoint const & src, std::string const & message)
{
  [Logger logMessageWithLevel:base::LCRITICAL src:src message:message];
  return true;
}

// MARK: - Private

+ (void)logMessageWithLevel:(base::LogLevel)level src:(base::SrcPoint const &)src message:(std::string const &)message {

  LogLevel logLevel;
  switch (level) {
    case base::LDEBUG: logLevel = LogLevelDebug; break;
    case base::LINFO: logLevel = LogLevelInfo; break;
    case base::LWARNING: logLevel = LogLevelWarning; break;
    case base::LERROR: logLevel = LogLevelError; break;
    case base::LCRITICAL: logLevel = LogLevelCritical; break;
    case base::NUM_LOG_LEVELS:
      CHECK(false, ("Invalid log level: base::NUM_LOG_LEVELS should not be used in this context."));
      return;
  }

  // Build the log message string.
  auto & logHelper = base::LogHelper::Instance();
  std::ostringstream output;
  logHelper.WriteProlog(output, level);
  logHelper.WriteLog(output, src, message);
  NSString * logMessage = [NSString stringWithUTF8String:output.str().c_str()];

  // Log the message into the system log.
  static os_log_t osLogger = os_log_create(kLoggerCategory.UTF8String, kLoggerSubsystem.UTF8String);
  os_log(osLogger, "%{public}s", logMessage.UTF8String);

  // Write the log message into the file.
  Logger * logger = [self logger];
  if ([logger fileLoggingEnabled]) {
    NSFileHandle * fileHandle = logger.fileHandle;
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
  }
}

+ (base::LogLevel)baseLevel:(LogLevel)level {
  switch (level) {
    case LogLevelDebug: return LDEBUG;
    case LogLevelInfo: return LINFO;
    case LogLevelWarning: return LWARNING;
    case LogLevelError: return LERROR;
    case LogLevelCritical: return LCRITICAL;
  }
}

@end
