
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudWatch Logs
## version: 2014-03-28
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>You can use Amazon CloudWatch Logs to monitor, store, and access your log files from Amazon EC2 instances, AWS CloudTrail, or other sources. You can then retrieve the associated log data from CloudWatch Logs using the CloudWatch console, CloudWatch Logs commands in the AWS CLI, CloudWatch Logs API, or CloudWatch Logs SDK.</p> <p>You can use CloudWatch Logs to:</p> <ul> <li> <p> <b>Monitor logs from EC2 instances in real-time</b>: You can use CloudWatch Logs to monitor applications and systems using log data. For example, CloudWatch Logs can track the number of errors that occur in your application logs and send you a notification whenever the rate of errors exceeds a threshold that you specify. CloudWatch Logs uses your log data for monitoring; so, no code changes are required. For example, you can monitor application logs for specific literal terms (such as "NullReferenceException") or count the number of occurrences of a literal term at a particular position in log data (such as "404" status codes in an Apache access log). When the term you are searching for is found, CloudWatch Logs reports the data to a CloudWatch metric that you specify.</p> </li> <li> <p> <b>Monitor AWS CloudTrail logged events</b>: You can create alarms in CloudWatch and receive notifications of particular API activity as captured by CloudTrail and use the notification to perform troubleshooting.</p> </li> <li> <p> <b>Archive log data</b>: You can use CloudWatch Logs to store your log data in highly durable storage. You can change the log retention setting so that any log events older than this setting are automatically deleted. The CloudWatch Logs agent makes it easy to quickly send both rotated and non-rotated log data off of a host and into the log service. You can then access the raw log data when you need it.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/logs/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "logs.ap-northeast-1.amazonaws.com", "ap-southeast-1": "logs.ap-southeast-1.amazonaws.com",
                           "us-west-2": "logs.us-west-2.amazonaws.com",
                           "eu-west-2": "logs.eu-west-2.amazonaws.com", "ap-northeast-3": "logs.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "logs.eu-central-1.amazonaws.com",
                           "us-east-2": "logs.us-east-2.amazonaws.com",
                           "us-east-1": "logs.us-east-1.amazonaws.com", "cn-northwest-1": "logs.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "logs.ap-south-1.amazonaws.com",
                           "eu-north-1": "logs.eu-north-1.amazonaws.com", "ap-northeast-2": "logs.ap-northeast-2.amazonaws.com",
                           "us-west-1": "logs.us-west-1.amazonaws.com",
                           "us-gov-east-1": "logs.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "logs.eu-west-3.amazonaws.com",
                           "cn-north-1": "logs.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "logs.sa-east-1.amazonaws.com",
                           "eu-west-1": "logs.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "logs.us-gov-west-1.amazonaws.com", "ap-southeast-2": "logs.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "logs.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "logs.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "logs.ap-southeast-1.amazonaws.com",
      "us-west-2": "logs.us-west-2.amazonaws.com",
      "eu-west-2": "logs.eu-west-2.amazonaws.com",
      "ap-northeast-3": "logs.ap-northeast-3.amazonaws.com",
      "eu-central-1": "logs.eu-central-1.amazonaws.com",
      "us-east-2": "logs.us-east-2.amazonaws.com",
      "us-east-1": "logs.us-east-1.amazonaws.com",
      "cn-northwest-1": "logs.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "logs.ap-south-1.amazonaws.com",
      "eu-north-1": "logs.eu-north-1.amazonaws.com",
      "ap-northeast-2": "logs.ap-northeast-2.amazonaws.com",
      "us-west-1": "logs.us-west-1.amazonaws.com",
      "us-gov-east-1": "logs.us-gov-east-1.amazonaws.com",
      "eu-west-3": "logs.eu-west-3.amazonaws.com",
      "cn-north-1": "logs.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "logs.sa-east-1.amazonaws.com",
      "eu-west-1": "logs.eu-west-1.amazonaws.com",
      "us-gov-west-1": "logs.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "logs.ap-southeast-2.amazonaws.com",
      "ca-central-1": "logs.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "logs"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AssociateKmsKey_600768 = ref object of OpenApiRestCall_600426
proc url_AssociateKmsKey_600770(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateKmsKey_600769(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Associates the specified AWS Key Management Service (AWS KMS) customer master key (CMK) with the specified log group.</p> <p>Associating an AWS KMS CMK with a log group overrides any existing associations between the log group and a CMK. After a CMK is associated with a log group, all newly ingested data for the log group is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p> <p>If you attempt to associate a CMK with a log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "Logs_20140328.AssociateKmsKey"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_AssociateKmsKey_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified AWS Key Management Service (AWS KMS) customer master key (CMK) with the specified log group.</p> <p>Associating an AWS KMS CMK with a log group overrides any existing associations between the log group and a CMK. After a CMK is associated with a log group, all newly ingested data for the log group is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p> <p>If you attempt to associate a CMK with a log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_AssociateKmsKey_600768; body: JsonNode): Recallable =
  ## associateKmsKey
  ## <p>Associates the specified AWS Key Management Service (AWS KMS) customer master key (CMK) with the specified log group.</p> <p>Associating an AWS KMS CMK with a log group overrides any existing associations between the log group and a CMK. After a CMK is associated with a log group, all newly ingested data for the log group is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p> <p>If you attempt to associate a CMK with a log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var associateKmsKey* = Call_AssociateKmsKey_600768(name: "associateKmsKey",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.AssociateKmsKey",
    validator: validate_AssociateKmsKey_600769, base: "/", url: url_AssociateKmsKey_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelExportTask_601037 = ref object of OpenApiRestCall_600426
proc url_CancelExportTask_601039(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelExportTask_601038(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Cancels the specified export task.</p> <p>The task must be in the <code>PENDING</code> or <code>RUNNING</code> state.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "Logs_20140328.CancelExportTask"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_CancelExportTask_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels the specified export task.</p> <p>The task must be in the <code>PENDING</code> or <code>RUNNING</code> state.</p>
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_CancelExportTask_601037; body: JsonNode): Recallable =
  ## cancelExportTask
  ## <p>Cancels the specified export task.</p> <p>The task must be in the <code>PENDING</code> or <code>RUNNING</code> state.</p>
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var cancelExportTask* = Call_CancelExportTask_601037(name: "cancelExportTask",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CancelExportTask",
    validator: validate_CancelExportTask_601038, base: "/",
    url: url_CancelExportTask_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportTask_601052 = ref object of OpenApiRestCall_600426
proc url_CreateExportTask_601054(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateExportTask_601053(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates an export task, which allows you to efficiently export data from a log group to an Amazon S3 bucket.</p> <p>This is an asynchronous call. If all the required information is provided, this operation initiates an export task and responds with the ID of the task. After the task has started, you can use <a>DescribeExportTasks</a> to get the status of the export task. Each account can only have one active (<code>RUNNING</code> or <code>PENDING</code>) export task at a time. To cancel an export task, use <a>CancelExportTask</a>.</p> <p>You can export logs from multiple log groups or multiple time ranges to the same S3 bucket. To separate out log data for each export task, you can specify a prefix to be used as the Amazon S3 key prefix for all exported objects.</p> <p>Exporting to S3 buckets that are encrypted with AES-256 is supported. Exporting to S3 buckets encrypted with SSE-KMS is not supported. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "Logs_20140328.CreateExportTask"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_CreateExportTask_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an export task, which allows you to efficiently export data from a log group to an Amazon S3 bucket.</p> <p>This is an asynchronous call. If all the required information is provided, this operation initiates an export task and responds with the ID of the task. After the task has started, you can use <a>DescribeExportTasks</a> to get the status of the export task. Each account can only have one active (<code>RUNNING</code> or <code>PENDING</code>) export task at a time. To cancel an export task, use <a>CancelExportTask</a>.</p> <p>You can export logs from multiple log groups or multiple time ranges to the same S3 bucket. To separate out log data for each export task, you can specify a prefix to be used as the Amazon S3 key prefix for all exported objects.</p> <p>Exporting to S3 buckets that are encrypted with AES-256 is supported. Exporting to S3 buckets encrypted with SSE-KMS is not supported. </p>
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_CreateExportTask_601052; body: JsonNode): Recallable =
  ## createExportTask
  ## <p>Creates an export task, which allows you to efficiently export data from a log group to an Amazon S3 bucket.</p> <p>This is an asynchronous call. If all the required information is provided, this operation initiates an export task and responds with the ID of the task. After the task has started, you can use <a>DescribeExportTasks</a> to get the status of the export task. Each account can only have one active (<code>RUNNING</code> or <code>PENDING</code>) export task at a time. To cancel an export task, use <a>CancelExportTask</a>.</p> <p>You can export logs from multiple log groups or multiple time ranges to the same S3 bucket. To separate out log data for each export task, you can specify a prefix to be used as the Amazon S3 key prefix for all exported objects.</p> <p>Exporting to S3 buckets that are encrypted with AES-256 is supported. Exporting to S3 buckets encrypted with SSE-KMS is not supported. </p>
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var createExportTask* = Call_CreateExportTask_601052(name: "createExportTask",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CreateExportTask",
    validator: validate_CreateExportTask_601053, base: "/",
    url: url_CreateExportTask_601054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogGroup_601067 = ref object of OpenApiRestCall_600426
proc url_CreateLogGroup_601069(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateLogGroup_601068(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a log group with the specified name.</p> <p>You can create up to 5000 log groups per account.</p> <p>You must use the following guidelines when naming a log group:</p> <ul> <li> <p>Log group names must be unique within a region for an AWS account.</p> </li> <li> <p>Log group names can be between 1 and 512 characters long.</p> </li> <li> <p>Log group names consist of the following characters: a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), '/' (forward slash), and '.' (period).</p> </li> </ul> <p>If you associate a AWS Key Management Service (AWS KMS) customer master key (CMK) with the log group, ingested data is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>If you attempt to associate a CMK with the log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "Logs_20140328.CreateLogGroup"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_CreateLogGroup_601067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a log group with the specified name.</p> <p>You can create up to 5000 log groups per account.</p> <p>You must use the following guidelines when naming a log group:</p> <ul> <li> <p>Log group names must be unique within a region for an AWS account.</p> </li> <li> <p>Log group names can be between 1 and 512 characters long.</p> </li> <li> <p>Log group names consist of the following characters: a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), '/' (forward slash), and '.' (period).</p> </li> </ul> <p>If you associate a AWS Key Management Service (AWS KMS) customer master key (CMK) with the log group, ingested data is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>If you attempt to associate a CMK with the log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_CreateLogGroup_601067; body: JsonNode): Recallable =
  ## createLogGroup
  ## <p>Creates a log group with the specified name.</p> <p>You can create up to 5000 log groups per account.</p> <p>You must use the following guidelines when naming a log group:</p> <ul> <li> <p>Log group names must be unique within a region for an AWS account.</p> </li> <li> <p>Log group names can be between 1 and 512 characters long.</p> </li> <li> <p>Log group names consist of the following characters: a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), '/' (forward slash), and '.' (period).</p> </li> </ul> <p>If you associate a AWS Key Management Service (AWS KMS) customer master key (CMK) with the log group, ingested data is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>If you attempt to associate a CMK with the log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var createLogGroup* = Call_CreateLogGroup_601067(name: "createLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CreateLogGroup",
    validator: validate_CreateLogGroup_601068, base: "/", url: url_CreateLogGroup_601069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogStream_601082 = ref object of OpenApiRestCall_600426
proc url_CreateLogStream_601084(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateLogStream_601083(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a log stream for the specified log group.</p> <p>There is no limit on the number of log streams that you can create for a log group.</p> <p>You must use the following guidelines when naming a log stream:</p> <ul> <li> <p>Log stream names must be unique within the log group.</p> </li> <li> <p>Log stream names can be between 1 and 512 characters long.</p> </li> <li> <p>The ':' (colon) and '*' (asterisk) characters are not allowed.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "Logs_20140328.CreateLogStream"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_CreateLogStream_601082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a log stream for the specified log group.</p> <p>There is no limit on the number of log streams that you can create for a log group.</p> <p>You must use the following guidelines when naming a log stream:</p> <ul> <li> <p>Log stream names must be unique within the log group.</p> </li> <li> <p>Log stream names can be between 1 and 512 characters long.</p> </li> <li> <p>The ':' (colon) and '*' (asterisk) characters are not allowed.</p> </li> </ul>
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_CreateLogStream_601082; body: JsonNode): Recallable =
  ## createLogStream
  ## <p>Creates a log stream for the specified log group.</p> <p>There is no limit on the number of log streams that you can create for a log group.</p> <p>You must use the following guidelines when naming a log stream:</p> <ul> <li> <p>Log stream names must be unique within the log group.</p> </li> <li> <p>Log stream names can be between 1 and 512 characters long.</p> </li> <li> <p>The ':' (colon) and '*' (asterisk) characters are not allowed.</p> </li> </ul>
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var createLogStream* = Call_CreateLogStream_601082(name: "createLogStream",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CreateLogStream",
    validator: validate_CreateLogStream_601083, base: "/", url: url_CreateLogStream_601084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDestination_601097 = ref object of OpenApiRestCall_600426
proc url_DeleteDestination_601099(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDestination_601098(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes the specified destination, and eventually disables all the subscription filters that publish to it. This operation does not delete the physical resource encapsulated by the destination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "Logs_20140328.DeleteDestination"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_DeleteDestination_601097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified destination, and eventually disables all the subscription filters that publish to it. This operation does not delete the physical resource encapsulated by the destination.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_DeleteDestination_601097; body: JsonNode): Recallable =
  ## deleteDestination
  ## Deletes the specified destination, and eventually disables all the subscription filters that publish to it. This operation does not delete the physical resource encapsulated by the destination.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var deleteDestination* = Call_DeleteDestination_601097(name: "deleteDestination",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteDestination",
    validator: validate_DeleteDestination_601098, base: "/",
    url: url_DeleteDestination_601099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogGroup_601112 = ref object of OpenApiRestCall_600426
proc url_DeleteLogGroup_601114(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteLogGroup_601113(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes the specified log group and permanently deletes all the archived log events associated with the log group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "Logs_20140328.DeleteLogGroup"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_DeleteLogGroup_601112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified log group and permanently deletes all the archived log events associated with the log group.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_DeleteLogGroup_601112; body: JsonNode): Recallable =
  ## deleteLogGroup
  ## Deletes the specified log group and permanently deletes all the archived log events associated with the log group.
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var deleteLogGroup* = Call_DeleteLogGroup_601112(name: "deleteLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteLogGroup",
    validator: validate_DeleteLogGroup_601113, base: "/", url: url_DeleteLogGroup_601114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogStream_601127 = ref object of OpenApiRestCall_600426
proc url_DeleteLogStream_601129(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteLogStream_601128(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes the specified log stream and permanently deletes all the archived log events associated with the log stream.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "Logs_20140328.DeleteLogStream"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_DeleteLogStream_601127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified log stream and permanently deletes all the archived log events associated with the log stream.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_DeleteLogStream_601127; body: JsonNode): Recallable =
  ## deleteLogStream
  ## Deletes the specified log stream and permanently deletes all the archived log events associated with the log stream.
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var deleteLogStream* = Call_DeleteLogStream_601127(name: "deleteLogStream",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteLogStream",
    validator: validate_DeleteLogStream_601128, base: "/", url: url_DeleteLogStream_601129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMetricFilter_601142 = ref object of OpenApiRestCall_600426
proc url_DeleteMetricFilter_601144(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteMetricFilter_601143(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes the specified metric filter.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601147 = header.getOrDefault("X-Amz-Target")
  valid_601147 = validateParameter(valid_601147, JString, required = true, default = newJString(
      "Logs_20140328.DeleteMetricFilter"))
  if valid_601147 != nil:
    section.add "X-Amz-Target", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_DeleteMetricFilter_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified metric filter.
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_DeleteMetricFilter_601142; body: JsonNode): Recallable =
  ## deleteMetricFilter
  ## Deletes the specified metric filter.
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var deleteMetricFilter* = Call_DeleteMetricFilter_601142(
    name: "deleteMetricFilter", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteMetricFilter",
    validator: validate_DeleteMetricFilter_601143, base: "/",
    url: url_DeleteMetricFilter_601144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_601157 = ref object of OpenApiRestCall_600426
proc url_DeleteResourcePolicy_601159(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteResourcePolicy_601158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a resource policy from this account. This revokes the access of the identities in that policy to put log events to this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601162 = header.getOrDefault("X-Amz-Target")
  valid_601162 = validateParameter(valid_601162, JString, required = true, default = newJString(
      "Logs_20140328.DeleteResourcePolicy"))
  if valid_601162 != nil:
    section.add "X-Amz-Target", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_DeleteResourcePolicy_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource policy from this account. This revokes the access of the identities in that policy to put log events to this account.
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_DeleteResourcePolicy_601157; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a resource policy from this account. This revokes the access of the identities in that policy to put log events to this account.
  ##   body: JObject (required)
  var body_601171 = newJObject()
  if body != nil:
    body_601171 = body
  result = call_601170.call(nil, nil, nil, nil, body_601171)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_601157(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_601158, base: "/",
    url: url_DeleteResourcePolicy_601159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRetentionPolicy_601172 = ref object of OpenApiRestCall_600426
proc url_DeleteRetentionPolicy_601174(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteRetentionPolicy_601173(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified retention policy.</p> <p>Log events do not expire if they belong to log groups without a retention policy.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601175 = header.getOrDefault("X-Amz-Date")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Date", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Security-Token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Security-Token", valid_601176
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601177 = header.getOrDefault("X-Amz-Target")
  valid_601177 = validateParameter(valid_601177, JString, required = true, default = newJString(
      "Logs_20140328.DeleteRetentionPolicy"))
  if valid_601177 != nil:
    section.add "X-Amz-Target", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_DeleteRetentionPolicy_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified retention policy.</p> <p>Log events do not expire if they belong to log groups without a retention policy.</p>
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"))
  result = hook(call_601184, url, valid)

proc call*(call_601185: Call_DeleteRetentionPolicy_601172; body: JsonNode): Recallable =
  ## deleteRetentionPolicy
  ## <p>Deletes the specified retention policy.</p> <p>Log events do not expire if they belong to log groups without a retention policy.</p>
  ##   body: JObject (required)
  var body_601186 = newJObject()
  if body != nil:
    body_601186 = body
  result = call_601185.call(nil, nil, nil, nil, body_601186)

var deleteRetentionPolicy* = Call_DeleteRetentionPolicy_601172(
    name: "deleteRetentionPolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteRetentionPolicy",
    validator: validate_DeleteRetentionPolicy_601173, base: "/",
    url: url_DeleteRetentionPolicy_601174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionFilter_601187 = ref object of OpenApiRestCall_600426
proc url_DeleteSubscriptionFilter_601189(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSubscriptionFilter_601188(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified subscription filter.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601192 = header.getOrDefault("X-Amz-Target")
  valid_601192 = validateParameter(valid_601192, JString, required = true, default = newJString(
      "Logs_20140328.DeleteSubscriptionFilter"))
  if valid_601192 != nil:
    section.add "X-Amz-Target", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_DeleteSubscriptionFilter_601187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription filter.
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"))
  result = hook(call_601199, url, valid)

proc call*(call_601200: Call_DeleteSubscriptionFilter_601187; body: JsonNode): Recallable =
  ## deleteSubscriptionFilter
  ## Deletes the specified subscription filter.
  ##   body: JObject (required)
  var body_601201 = newJObject()
  if body != nil:
    body_601201 = body
  result = call_601200.call(nil, nil, nil, nil, body_601201)

var deleteSubscriptionFilter* = Call_DeleteSubscriptionFilter_601187(
    name: "deleteSubscriptionFilter", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteSubscriptionFilter",
    validator: validate_DeleteSubscriptionFilter_601188, base: "/",
    url: url_DeleteSubscriptionFilter_601189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDestinations_601202 = ref object of OpenApiRestCall_600426
proc url_DescribeDestinations_601204(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDestinations_601203(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all your destinations. The results are ASCII-sorted by destination name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_601205 = query.getOrDefault("nextToken")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "nextToken", valid_601205
  var valid_601206 = query.getOrDefault("limit")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "limit", valid_601206
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601207 = header.getOrDefault("X-Amz-Date")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Date", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Security-Token")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Security-Token", valid_601208
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601209 = header.getOrDefault("X-Amz-Target")
  valid_601209 = validateParameter(valid_601209, JString, required = true, default = newJString(
      "Logs_20140328.DescribeDestinations"))
  if valid_601209 != nil:
    section.add "X-Amz-Target", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Content-Sha256", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Algorithm")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Algorithm", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Signature")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Signature", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-SignedHeaders", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Credential")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Credential", valid_601214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601216: Call_DescribeDestinations_601202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all your destinations. The results are ASCII-sorted by destination name.
  ## 
  let valid = call_601216.validator(path, query, header, formData, body)
  let scheme = call_601216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601216.url(scheme.get, call_601216.host, call_601216.base,
                         call_601216.route, valid.getOrDefault("path"))
  result = hook(call_601216, url, valid)

proc call*(call_601217: Call_DescribeDestinations_601202; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeDestinations
  ## Lists all your destinations. The results are ASCII-sorted by destination name.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601218 = newJObject()
  var body_601219 = newJObject()
  add(query_601218, "nextToken", newJString(nextToken))
  if body != nil:
    body_601219 = body
  add(query_601218, "limit", newJString(limit))
  result = call_601217.call(nil, query_601218, nil, nil, body_601219)

var describeDestinations* = Call_DescribeDestinations_601202(
    name: "describeDestinations", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeDestinations",
    validator: validate_DescribeDestinations_601203, base: "/",
    url: url_DescribeDestinations_601204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportTasks_601221 = ref object of OpenApiRestCall_600426
proc url_DescribeExportTasks_601223(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeExportTasks_601222(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the specified export tasks. You can list all your export tasks or filter the results based on task ID or task status.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601224 = header.getOrDefault("X-Amz-Date")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Date", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Security-Token")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Security-Token", valid_601225
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601226 = header.getOrDefault("X-Amz-Target")
  valid_601226 = validateParameter(valid_601226, JString, required = true, default = newJString(
      "Logs_20140328.DescribeExportTasks"))
  if valid_601226 != nil:
    section.add "X-Amz-Target", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Content-Sha256", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Algorithm")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Algorithm", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Signature")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Signature", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-SignedHeaders", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Credential")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Credential", valid_601231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601233: Call_DescribeExportTasks_601221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified export tasks. You can list all your export tasks or filter the results based on task ID or task status.
  ## 
  let valid = call_601233.validator(path, query, header, formData, body)
  let scheme = call_601233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601233.url(scheme.get, call_601233.host, call_601233.base,
                         call_601233.route, valid.getOrDefault("path"))
  result = hook(call_601233, url, valid)

proc call*(call_601234: Call_DescribeExportTasks_601221; body: JsonNode): Recallable =
  ## describeExportTasks
  ## Lists the specified export tasks. You can list all your export tasks or filter the results based on task ID or task status.
  ##   body: JObject (required)
  var body_601235 = newJObject()
  if body != nil:
    body_601235 = body
  result = call_601234.call(nil, nil, nil, nil, body_601235)

var describeExportTasks* = Call_DescribeExportTasks_601221(
    name: "describeExportTasks", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeExportTasks",
    validator: validate_DescribeExportTasks_601222, base: "/",
    url: url_DescribeExportTasks_601223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLogGroups_601236 = ref object of OpenApiRestCall_600426
proc url_DescribeLogGroups_601238(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeLogGroups_601237(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the specified log groups. You can list all your log groups or filter the results by prefix. The results are ASCII-sorted by log group name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_601239 = query.getOrDefault("nextToken")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "nextToken", valid_601239
  var valid_601240 = query.getOrDefault("limit")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "limit", valid_601240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601241 = header.getOrDefault("X-Amz-Date")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Date", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Security-Token")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Security-Token", valid_601242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601243 = header.getOrDefault("X-Amz-Target")
  valid_601243 = validateParameter(valid_601243, JString, required = true, default = newJString(
      "Logs_20140328.DescribeLogGroups"))
  if valid_601243 != nil:
    section.add "X-Amz-Target", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Content-Sha256", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Algorithm")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Algorithm", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Signature")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Signature", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-SignedHeaders", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Credential")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Credential", valid_601248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601250: Call_DescribeLogGroups_601236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified log groups. You can list all your log groups or filter the results by prefix. The results are ASCII-sorted by log group name.
  ## 
  let valid = call_601250.validator(path, query, header, formData, body)
  let scheme = call_601250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601250.url(scheme.get, call_601250.host, call_601250.base,
                         call_601250.route, valid.getOrDefault("path"))
  result = hook(call_601250, url, valid)

proc call*(call_601251: Call_DescribeLogGroups_601236; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeLogGroups
  ## Lists the specified log groups. You can list all your log groups or filter the results by prefix. The results are ASCII-sorted by log group name.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601252 = newJObject()
  var body_601253 = newJObject()
  add(query_601252, "nextToken", newJString(nextToken))
  if body != nil:
    body_601253 = body
  add(query_601252, "limit", newJString(limit))
  result = call_601251.call(nil, query_601252, nil, nil, body_601253)

var describeLogGroups* = Call_DescribeLogGroups_601236(name: "describeLogGroups",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeLogGroups",
    validator: validate_DescribeLogGroups_601237, base: "/",
    url: url_DescribeLogGroups_601238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLogStreams_601254 = ref object of OpenApiRestCall_600426
proc url_DescribeLogStreams_601256(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeLogStreams_601255(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Lists the log streams for the specified log group. You can list all the log streams or filter the results by prefix. You can also control how the results are ordered.</p> <p>This operation has a limit of five transactions per second, after which transactions are throttled.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_601257 = query.getOrDefault("nextToken")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "nextToken", valid_601257
  var valid_601258 = query.getOrDefault("limit")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "limit", valid_601258
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601259 = header.getOrDefault("X-Amz-Date")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Date", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Security-Token")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Security-Token", valid_601260
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601261 = header.getOrDefault("X-Amz-Target")
  valid_601261 = validateParameter(valid_601261, JString, required = true, default = newJString(
      "Logs_20140328.DescribeLogStreams"))
  if valid_601261 != nil:
    section.add "X-Amz-Target", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Content-Sha256", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Algorithm")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Algorithm", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Signature")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Signature", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-SignedHeaders", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Credential")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Credential", valid_601266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601268: Call_DescribeLogStreams_601254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the log streams for the specified log group. You can list all the log streams or filter the results by prefix. You can also control how the results are ordered.</p> <p>This operation has a limit of five transactions per second, after which transactions are throttled.</p>
  ## 
  let valid = call_601268.validator(path, query, header, formData, body)
  let scheme = call_601268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601268.url(scheme.get, call_601268.host, call_601268.base,
                         call_601268.route, valid.getOrDefault("path"))
  result = hook(call_601268, url, valid)

proc call*(call_601269: Call_DescribeLogStreams_601254; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeLogStreams
  ## <p>Lists the log streams for the specified log group. You can list all the log streams or filter the results by prefix. You can also control how the results are ordered.</p> <p>This operation has a limit of five transactions per second, after which transactions are throttled.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601270 = newJObject()
  var body_601271 = newJObject()
  add(query_601270, "nextToken", newJString(nextToken))
  if body != nil:
    body_601271 = body
  add(query_601270, "limit", newJString(limit))
  result = call_601269.call(nil, query_601270, nil, nil, body_601271)

var describeLogStreams* = Call_DescribeLogStreams_601254(
    name: "describeLogStreams", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeLogStreams",
    validator: validate_DescribeLogStreams_601255, base: "/",
    url: url_DescribeLogStreams_601256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMetricFilters_601272 = ref object of OpenApiRestCall_600426
proc url_DescribeMetricFilters_601274(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMetricFilters_601273(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the specified metric filters. You can list all the metric filters or filter the results by log name, prefix, metric name, or metric namespace. The results are ASCII-sorted by filter name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_601275 = query.getOrDefault("nextToken")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "nextToken", valid_601275
  var valid_601276 = query.getOrDefault("limit")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "limit", valid_601276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601277 = header.getOrDefault("X-Amz-Date")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Date", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Security-Token")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Security-Token", valid_601278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601279 = header.getOrDefault("X-Amz-Target")
  valid_601279 = validateParameter(valid_601279, JString, required = true, default = newJString(
      "Logs_20140328.DescribeMetricFilters"))
  if valid_601279 != nil:
    section.add "X-Amz-Target", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Content-Sha256", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Algorithm")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Algorithm", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Signature")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Signature", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-SignedHeaders", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Credential")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Credential", valid_601284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601286: Call_DescribeMetricFilters_601272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified metric filters. You can list all the metric filters or filter the results by log name, prefix, metric name, or metric namespace. The results are ASCII-sorted by filter name.
  ## 
  let valid = call_601286.validator(path, query, header, formData, body)
  let scheme = call_601286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601286.url(scheme.get, call_601286.host, call_601286.base,
                         call_601286.route, valid.getOrDefault("path"))
  result = hook(call_601286, url, valid)

proc call*(call_601287: Call_DescribeMetricFilters_601272; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeMetricFilters
  ## Lists the specified metric filters. You can list all the metric filters or filter the results by log name, prefix, metric name, or metric namespace. The results are ASCII-sorted by filter name.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601288 = newJObject()
  var body_601289 = newJObject()
  add(query_601288, "nextToken", newJString(nextToken))
  if body != nil:
    body_601289 = body
  add(query_601288, "limit", newJString(limit))
  result = call_601287.call(nil, query_601288, nil, nil, body_601289)

var describeMetricFilters* = Call_DescribeMetricFilters_601272(
    name: "describeMetricFilters", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeMetricFilters",
    validator: validate_DescribeMetricFilters_601273, base: "/",
    url: url_DescribeMetricFilters_601274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeQueries_601290 = ref object of OpenApiRestCall_600426
proc url_DescribeQueries_601292(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeQueries_601291(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a list of CloudWatch Logs Insights queries that are scheduled, executing, or have been executed recently in this account. You can request all queries, or limit it to queries of a specific log group or queries with a certain status.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601293 = header.getOrDefault("X-Amz-Date")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Date", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Security-Token")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Security-Token", valid_601294
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601295 = header.getOrDefault("X-Amz-Target")
  valid_601295 = validateParameter(valid_601295, JString, required = true, default = newJString(
      "Logs_20140328.DescribeQueries"))
  if valid_601295 != nil:
    section.add "X-Amz-Target", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Content-Sha256", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Algorithm")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Algorithm", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Signature")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Signature", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-SignedHeaders", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Credential")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Credential", valid_601300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601302: Call_DescribeQueries_601290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of CloudWatch Logs Insights queries that are scheduled, executing, or have been executed recently in this account. You can request all queries, or limit it to queries of a specific log group or queries with a certain status.
  ## 
  let valid = call_601302.validator(path, query, header, formData, body)
  let scheme = call_601302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601302.url(scheme.get, call_601302.host, call_601302.base,
                         call_601302.route, valid.getOrDefault("path"))
  result = hook(call_601302, url, valid)

proc call*(call_601303: Call_DescribeQueries_601290; body: JsonNode): Recallable =
  ## describeQueries
  ## Returns a list of CloudWatch Logs Insights queries that are scheduled, executing, or have been executed recently in this account. You can request all queries, or limit it to queries of a specific log group or queries with a certain status.
  ##   body: JObject (required)
  var body_601304 = newJObject()
  if body != nil:
    body_601304 = body
  result = call_601303.call(nil, nil, nil, nil, body_601304)

var describeQueries* = Call_DescribeQueries_601290(name: "describeQueries",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeQueries",
    validator: validate_DescribeQueries_601291, base: "/", url: url_DescribeQueries_601292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePolicies_601305 = ref object of OpenApiRestCall_600426
proc url_DescribeResourcePolicies_601307(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeResourcePolicies_601306(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resource policies in this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601308 = header.getOrDefault("X-Amz-Date")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Date", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Security-Token")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Security-Token", valid_601309
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601310 = header.getOrDefault("X-Amz-Target")
  valid_601310 = validateParameter(valid_601310, JString, required = true, default = newJString(
      "Logs_20140328.DescribeResourcePolicies"))
  if valid_601310 != nil:
    section.add "X-Amz-Target", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Content-Sha256", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Algorithm")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Algorithm", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Signature")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Signature", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-SignedHeaders", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Credential")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Credential", valid_601315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601317: Call_DescribeResourcePolicies_601305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resource policies in this account.
  ## 
  let valid = call_601317.validator(path, query, header, formData, body)
  let scheme = call_601317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601317.url(scheme.get, call_601317.host, call_601317.base,
                         call_601317.route, valid.getOrDefault("path"))
  result = hook(call_601317, url, valid)

proc call*(call_601318: Call_DescribeResourcePolicies_601305; body: JsonNode): Recallable =
  ## describeResourcePolicies
  ## Lists the resource policies in this account.
  ##   body: JObject (required)
  var body_601319 = newJObject()
  if body != nil:
    body_601319 = body
  result = call_601318.call(nil, nil, nil, nil, body_601319)

var describeResourcePolicies* = Call_DescribeResourcePolicies_601305(
    name: "describeResourcePolicies", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeResourcePolicies",
    validator: validate_DescribeResourcePolicies_601306, base: "/",
    url: url_DescribeResourcePolicies_601307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscriptionFilters_601320 = ref object of OpenApiRestCall_600426
proc url_DescribeSubscriptionFilters_601322(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSubscriptionFilters_601321(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the subscription filters for the specified log group. You can list all the subscription filters or filter the results by prefix. The results are ASCII-sorted by filter name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_601323 = query.getOrDefault("nextToken")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "nextToken", valid_601323
  var valid_601324 = query.getOrDefault("limit")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "limit", valid_601324
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601325 = header.getOrDefault("X-Amz-Date")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Date", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Security-Token")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Security-Token", valid_601326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601327 = header.getOrDefault("X-Amz-Target")
  valid_601327 = validateParameter(valid_601327, JString, required = true, default = newJString(
      "Logs_20140328.DescribeSubscriptionFilters"))
  if valid_601327 != nil:
    section.add "X-Amz-Target", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Content-Sha256", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Algorithm")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Algorithm", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Signature")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Signature", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-SignedHeaders", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Credential")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Credential", valid_601332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601334: Call_DescribeSubscriptionFilters_601320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the subscription filters for the specified log group. You can list all the subscription filters or filter the results by prefix. The results are ASCII-sorted by filter name.
  ## 
  let valid = call_601334.validator(path, query, header, formData, body)
  let scheme = call_601334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601334.url(scheme.get, call_601334.host, call_601334.base,
                         call_601334.route, valid.getOrDefault("path"))
  result = hook(call_601334, url, valid)

proc call*(call_601335: Call_DescribeSubscriptionFilters_601320; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeSubscriptionFilters
  ## Lists the subscription filters for the specified log group. You can list all the subscription filters or filter the results by prefix. The results are ASCII-sorted by filter name.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601336 = newJObject()
  var body_601337 = newJObject()
  add(query_601336, "nextToken", newJString(nextToken))
  if body != nil:
    body_601337 = body
  add(query_601336, "limit", newJString(limit))
  result = call_601335.call(nil, query_601336, nil, nil, body_601337)

var describeSubscriptionFilters* = Call_DescribeSubscriptionFilters_601320(
    name: "describeSubscriptionFilters", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeSubscriptionFilters",
    validator: validate_DescribeSubscriptionFilters_601321, base: "/",
    url: url_DescribeSubscriptionFilters_601322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateKmsKey_601338 = ref object of OpenApiRestCall_600426
proc url_DisassociateKmsKey_601340(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateKmsKey_601339(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Disassociates the associated AWS Key Management Service (AWS KMS) customer master key (CMK) from the specified log group.</p> <p>After the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601341 = header.getOrDefault("X-Amz-Date")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Date", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Security-Token")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Security-Token", valid_601342
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601343 = header.getOrDefault("X-Amz-Target")
  valid_601343 = validateParameter(valid_601343, JString, required = true, default = newJString(
      "Logs_20140328.DisassociateKmsKey"))
  if valid_601343 != nil:
    section.add "X-Amz-Target", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Content-Sha256", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Algorithm")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Algorithm", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Signature")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Signature", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-SignedHeaders", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Credential")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Credential", valid_601348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601350: Call_DisassociateKmsKey_601338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the associated AWS Key Management Service (AWS KMS) customer master key (CMK) from the specified log group.</p> <p>After the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p>
  ## 
  let valid = call_601350.validator(path, query, header, formData, body)
  let scheme = call_601350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601350.url(scheme.get, call_601350.host, call_601350.base,
                         call_601350.route, valid.getOrDefault("path"))
  result = hook(call_601350, url, valid)

proc call*(call_601351: Call_DisassociateKmsKey_601338; body: JsonNode): Recallable =
  ## disassociateKmsKey
  ## <p>Disassociates the associated AWS Key Management Service (AWS KMS) customer master key (CMK) from the specified log group.</p> <p>After the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p>
  ##   body: JObject (required)
  var body_601352 = newJObject()
  if body != nil:
    body_601352 = body
  result = call_601351.call(nil, nil, nil, nil, body_601352)

var disassociateKmsKey* = Call_DisassociateKmsKey_601338(
    name: "disassociateKmsKey", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DisassociateKmsKey",
    validator: validate_DisassociateKmsKey_601339, base: "/",
    url: url_DisassociateKmsKey_601340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FilterLogEvents_601353 = ref object of OpenApiRestCall_600426
proc url_FilterLogEvents_601355(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_FilterLogEvents_601354(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Lists log events from the specified log group. You can list all the log events or filter the results using a filter pattern, a time range, and the name of the log stream.</p> <p>By default, this operation returns as many log events as can fit in 1 MB (up to 10,000 log events), or all the events found within the time range that you specify. If the results include a token, then there are more log events available, and you can get additional results by specifying the token in a subsequent call.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_601356 = query.getOrDefault("nextToken")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "nextToken", valid_601356
  var valid_601357 = query.getOrDefault("limit")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "limit", valid_601357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601358 = header.getOrDefault("X-Amz-Date")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Date", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Security-Token")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Security-Token", valid_601359
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601360 = header.getOrDefault("X-Amz-Target")
  valid_601360 = validateParameter(valid_601360, JString, required = true, default = newJString(
      "Logs_20140328.FilterLogEvents"))
  if valid_601360 != nil:
    section.add "X-Amz-Target", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Content-Sha256", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Algorithm")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Algorithm", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Signature")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Signature", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-SignedHeaders", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Credential")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Credential", valid_601365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601367: Call_FilterLogEvents_601353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists log events from the specified log group. You can list all the log events or filter the results using a filter pattern, a time range, and the name of the log stream.</p> <p>By default, this operation returns as many log events as can fit in 1 MB (up to 10,000 log events), or all the events found within the time range that you specify. If the results include a token, then there are more log events available, and you can get additional results by specifying the token in a subsequent call.</p>
  ## 
  let valid = call_601367.validator(path, query, header, formData, body)
  let scheme = call_601367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601367.url(scheme.get, call_601367.host, call_601367.base,
                         call_601367.route, valid.getOrDefault("path"))
  result = hook(call_601367, url, valid)

proc call*(call_601368: Call_FilterLogEvents_601353; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## filterLogEvents
  ## <p>Lists log events from the specified log group. You can list all the log events or filter the results using a filter pattern, a time range, and the name of the log stream.</p> <p>By default, this operation returns as many log events as can fit in 1 MB (up to 10,000 log events), or all the events found within the time range that you specify. If the results include a token, then there are more log events available, and you can get additional results by specifying the token in a subsequent call.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601369 = newJObject()
  var body_601370 = newJObject()
  add(query_601369, "nextToken", newJString(nextToken))
  if body != nil:
    body_601370 = body
  add(query_601369, "limit", newJString(limit))
  result = call_601368.call(nil, query_601369, nil, nil, body_601370)

var filterLogEvents* = Call_FilterLogEvents_601353(name: "filterLogEvents",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.FilterLogEvents",
    validator: validate_FilterLogEvents_601354, base: "/", url: url_FilterLogEvents_601355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLogEvents_601371 = ref object of OpenApiRestCall_600426
proc url_GetLogEvents_601373(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetLogEvents_601372(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists log events from the specified log stream. You can list all the log events or filter using a time range.</p> <p>By default, this operation returns as many log events as can fit in a response size of 1MB (up to 10,000 log events). You can get additional log events by specifying one of the tokens in a subsequent call.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_601374 = query.getOrDefault("nextToken")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "nextToken", valid_601374
  var valid_601375 = query.getOrDefault("limit")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "limit", valid_601375
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601376 = header.getOrDefault("X-Amz-Date")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Date", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Security-Token")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Security-Token", valid_601377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601378 = header.getOrDefault("X-Amz-Target")
  valid_601378 = validateParameter(valid_601378, JString, required = true, default = newJString(
      "Logs_20140328.GetLogEvents"))
  if valid_601378 != nil:
    section.add "X-Amz-Target", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Content-Sha256", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Algorithm")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Algorithm", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Signature")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Signature", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-SignedHeaders", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Credential")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Credential", valid_601383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601385: Call_GetLogEvents_601371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists log events from the specified log stream. You can list all the log events or filter using a time range.</p> <p>By default, this operation returns as many log events as can fit in a response size of 1MB (up to 10,000 log events). You can get additional log events by specifying one of the tokens in a subsequent call.</p>
  ## 
  let valid = call_601385.validator(path, query, header, formData, body)
  let scheme = call_601385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601385.url(scheme.get, call_601385.host, call_601385.base,
                         call_601385.route, valid.getOrDefault("path"))
  result = hook(call_601385, url, valid)

proc call*(call_601386: Call_GetLogEvents_601371; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## getLogEvents
  ## <p>Lists log events from the specified log stream. You can list all the log events or filter using a time range.</p> <p>By default, this operation returns as many log events as can fit in a response size of 1MB (up to 10,000 log events). You can get additional log events by specifying one of the tokens in a subsequent call.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601387 = newJObject()
  var body_601388 = newJObject()
  add(query_601387, "nextToken", newJString(nextToken))
  if body != nil:
    body_601388 = body
  add(query_601387, "limit", newJString(limit))
  result = call_601386.call(nil, query_601387, nil, nil, body_601388)

var getLogEvents* = Call_GetLogEvents_601371(name: "getLogEvents",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetLogEvents",
    validator: validate_GetLogEvents_601372, base: "/", url: url_GetLogEvents_601373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLogGroupFields_601389 = ref object of OpenApiRestCall_600426
proc url_GetLogGroupFields_601391(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetLogGroupFields_601390(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Returns a list of the fields that are included in log events in the specified log group, along with the percentage of log events that contain each field. The search is limited to a time period that you specify.</p> <p>In the results, fields that start with @ are fields generated by CloudWatch Logs. For example, <code>@timestamp</code> is the timestamp of each log event.</p> <p>The response results are sorted by the frequency percentage, starting with the highest percentage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601392 = header.getOrDefault("X-Amz-Date")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Date", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Security-Token")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Security-Token", valid_601393
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601394 = header.getOrDefault("X-Amz-Target")
  valid_601394 = validateParameter(valid_601394, JString, required = true, default = newJString(
      "Logs_20140328.GetLogGroupFields"))
  if valid_601394 != nil:
    section.add "X-Amz-Target", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Content-Sha256", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Algorithm")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Algorithm", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Signature")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Signature", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-SignedHeaders", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Credential")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Credential", valid_601399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601401: Call_GetLogGroupFields_601389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the fields that are included in log events in the specified log group, along with the percentage of log events that contain each field. The search is limited to a time period that you specify.</p> <p>In the results, fields that start with @ are fields generated by CloudWatch Logs. For example, <code>@timestamp</code> is the timestamp of each log event.</p> <p>The response results are sorted by the frequency percentage, starting with the highest percentage.</p>
  ## 
  let valid = call_601401.validator(path, query, header, formData, body)
  let scheme = call_601401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601401.url(scheme.get, call_601401.host, call_601401.base,
                         call_601401.route, valid.getOrDefault("path"))
  result = hook(call_601401, url, valid)

proc call*(call_601402: Call_GetLogGroupFields_601389; body: JsonNode): Recallable =
  ## getLogGroupFields
  ## <p>Returns a list of the fields that are included in log events in the specified log group, along with the percentage of log events that contain each field. The search is limited to a time period that you specify.</p> <p>In the results, fields that start with @ are fields generated by CloudWatch Logs. For example, <code>@timestamp</code> is the timestamp of each log event.</p> <p>The response results are sorted by the frequency percentage, starting with the highest percentage.</p>
  ##   body: JObject (required)
  var body_601403 = newJObject()
  if body != nil:
    body_601403 = body
  result = call_601402.call(nil, nil, nil, nil, body_601403)

var getLogGroupFields* = Call_GetLogGroupFields_601389(name: "getLogGroupFields",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetLogGroupFields",
    validator: validate_GetLogGroupFields_601390, base: "/",
    url: url_GetLogGroupFields_601391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLogRecord_601404 = ref object of OpenApiRestCall_600426
proc url_GetLogRecord_601406(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetLogRecord_601405(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves all the fields and values of a single log event. All fields are retrieved, even if the original query that produced the <code>logRecordPointer</code> retrieved only a subset of fields. Fields are returned as field name/field value pairs.</p> <p>Additionally, the entire unparsed log event is returned within <code>@message</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601407 = header.getOrDefault("X-Amz-Date")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Date", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Security-Token")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Security-Token", valid_601408
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601409 = header.getOrDefault("X-Amz-Target")
  valid_601409 = validateParameter(valid_601409, JString, required = true, default = newJString(
      "Logs_20140328.GetLogRecord"))
  if valid_601409 != nil:
    section.add "X-Amz-Target", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Content-Sha256", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Algorithm")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Algorithm", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-Signature")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Signature", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-SignedHeaders", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Credential")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Credential", valid_601414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601416: Call_GetLogRecord_601404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the fields and values of a single log event. All fields are retrieved, even if the original query that produced the <code>logRecordPointer</code> retrieved only a subset of fields. Fields are returned as field name/field value pairs.</p> <p>Additionally, the entire unparsed log event is returned within <code>@message</code>.</p>
  ## 
  let valid = call_601416.validator(path, query, header, formData, body)
  let scheme = call_601416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601416.url(scheme.get, call_601416.host, call_601416.base,
                         call_601416.route, valid.getOrDefault("path"))
  result = hook(call_601416, url, valid)

proc call*(call_601417: Call_GetLogRecord_601404; body: JsonNode): Recallable =
  ## getLogRecord
  ## <p>Retrieves all the fields and values of a single log event. All fields are retrieved, even if the original query that produced the <code>logRecordPointer</code> retrieved only a subset of fields. Fields are returned as field name/field value pairs.</p> <p>Additionally, the entire unparsed log event is returned within <code>@message</code>.</p>
  ##   body: JObject (required)
  var body_601418 = newJObject()
  if body != nil:
    body_601418 = body
  result = call_601417.call(nil, nil, nil, nil, body_601418)

var getLogRecord* = Call_GetLogRecord_601404(name: "getLogRecord",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetLogRecord",
    validator: validate_GetLogRecord_601405, base: "/", url: url_GetLogRecord_601406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryResults_601419 = ref object of OpenApiRestCall_600426
proc url_GetQueryResults_601421(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetQueryResults_601420(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Returns the results from the specified query.</p> <p>Only the fields requested in the query are returned, along with a <code>@ptr</code> field which is the identifier for the log record. You can use the value of <code>@ptr</code> in a operation to get the full log record.</p> <p> <code>GetQueryResults</code> does not start a query execution. To run a query, use .</p> <p>If the value of the <code>Status</code> field in the output is <code>Running</code>, this operation returns only partial results. If you see a value of <code>Scheduled</code> or <code>Running</code> for the status, you can retry the operation later to see the final results. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601422 = header.getOrDefault("X-Amz-Date")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Date", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Security-Token")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Security-Token", valid_601423
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601424 = header.getOrDefault("X-Amz-Target")
  valid_601424 = validateParameter(valid_601424, JString, required = true, default = newJString(
      "Logs_20140328.GetQueryResults"))
  if valid_601424 != nil:
    section.add "X-Amz-Target", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Content-Sha256", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Algorithm")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Algorithm", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-Signature")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-Signature", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-SignedHeaders", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Credential")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Credential", valid_601429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601431: Call_GetQueryResults_601419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the results from the specified query.</p> <p>Only the fields requested in the query are returned, along with a <code>@ptr</code> field which is the identifier for the log record. You can use the value of <code>@ptr</code> in a operation to get the full log record.</p> <p> <code>GetQueryResults</code> does not start a query execution. To run a query, use .</p> <p>If the value of the <code>Status</code> field in the output is <code>Running</code>, this operation returns only partial results. If you see a value of <code>Scheduled</code> or <code>Running</code> for the status, you can retry the operation later to see the final results. </p>
  ## 
  let valid = call_601431.validator(path, query, header, formData, body)
  let scheme = call_601431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601431.url(scheme.get, call_601431.host, call_601431.base,
                         call_601431.route, valid.getOrDefault("path"))
  result = hook(call_601431, url, valid)

proc call*(call_601432: Call_GetQueryResults_601419; body: JsonNode): Recallable =
  ## getQueryResults
  ## <p>Returns the results from the specified query.</p> <p>Only the fields requested in the query are returned, along with a <code>@ptr</code> field which is the identifier for the log record. You can use the value of <code>@ptr</code> in a operation to get the full log record.</p> <p> <code>GetQueryResults</code> does not start a query execution. To run a query, use .</p> <p>If the value of the <code>Status</code> field in the output is <code>Running</code>, this operation returns only partial results. If you see a value of <code>Scheduled</code> or <code>Running</code> for the status, you can retry the operation later to see the final results. </p>
  ##   body: JObject (required)
  var body_601433 = newJObject()
  if body != nil:
    body_601433 = body
  result = call_601432.call(nil, nil, nil, nil, body_601433)

var getQueryResults* = Call_GetQueryResults_601419(name: "getQueryResults",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetQueryResults",
    validator: validate_GetQueryResults_601420, base: "/", url: url_GetQueryResults_601421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsLogGroup_601434 = ref object of OpenApiRestCall_600426
proc url_ListTagsLogGroup_601436(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsLogGroup_601435(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the tags for the specified log group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601437 = header.getOrDefault("X-Amz-Date")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Date", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Security-Token")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Security-Token", valid_601438
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601439 = header.getOrDefault("X-Amz-Target")
  valid_601439 = validateParameter(valid_601439, JString, required = true, default = newJString(
      "Logs_20140328.ListTagsLogGroup"))
  if valid_601439 != nil:
    section.add "X-Amz-Target", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Content-Sha256", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Algorithm")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Algorithm", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Signature")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Signature", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-SignedHeaders", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Credential")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Credential", valid_601444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601446: Call_ListTagsLogGroup_601434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified log group.
  ## 
  let valid = call_601446.validator(path, query, header, formData, body)
  let scheme = call_601446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601446.url(scheme.get, call_601446.host, call_601446.base,
                         call_601446.route, valid.getOrDefault("path"))
  result = hook(call_601446, url, valid)

proc call*(call_601447: Call_ListTagsLogGroup_601434; body: JsonNode): Recallable =
  ## listTagsLogGroup
  ## Lists the tags for the specified log group.
  ##   body: JObject (required)
  var body_601448 = newJObject()
  if body != nil:
    body_601448 = body
  result = call_601447.call(nil, nil, nil, nil, body_601448)

var listTagsLogGroup* = Call_ListTagsLogGroup_601434(name: "listTagsLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.ListTagsLogGroup",
    validator: validate_ListTagsLogGroup_601435, base: "/",
    url: url_ListTagsLogGroup_601436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDestination_601449 = ref object of OpenApiRestCall_600426
proc url_PutDestination_601451(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutDestination_601450(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates or updates a destination. A destination encapsulates a physical resource (such as an Amazon Kinesis stream) and enables you to subscribe to a real-time stream of log events for a different account, ingested using <a>PutLogEvents</a>. A destination can be an Amazon Kinesis stream, Amazon Kinesis Data Firehose strea, or an AWS Lambda function.</p> <p>Through an access policy, a destination controls what is written to it. By default, <code>PutDestination</code> does not set any access policy with the destination, which means a cross-account user cannot call <a>PutSubscriptionFilter</a> against this destination. To enable this, the destination owner must call <a>PutDestinationPolicy</a> after <code>PutDestination</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601452 = header.getOrDefault("X-Amz-Date")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Date", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Security-Token")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Security-Token", valid_601453
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601454 = header.getOrDefault("X-Amz-Target")
  valid_601454 = validateParameter(valid_601454, JString, required = true, default = newJString(
      "Logs_20140328.PutDestination"))
  if valid_601454 != nil:
    section.add "X-Amz-Target", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Content-Sha256", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Algorithm")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Algorithm", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Signature")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Signature", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-SignedHeaders", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Credential")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Credential", valid_601459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601461: Call_PutDestination_601449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a destination. A destination encapsulates a physical resource (such as an Amazon Kinesis stream) and enables you to subscribe to a real-time stream of log events for a different account, ingested using <a>PutLogEvents</a>. A destination can be an Amazon Kinesis stream, Amazon Kinesis Data Firehose strea, or an AWS Lambda function.</p> <p>Through an access policy, a destination controls what is written to it. By default, <code>PutDestination</code> does not set any access policy with the destination, which means a cross-account user cannot call <a>PutSubscriptionFilter</a> against this destination. To enable this, the destination owner must call <a>PutDestinationPolicy</a> after <code>PutDestination</code>.</p>
  ## 
  let valid = call_601461.validator(path, query, header, formData, body)
  let scheme = call_601461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601461.url(scheme.get, call_601461.host, call_601461.base,
                         call_601461.route, valid.getOrDefault("path"))
  result = hook(call_601461, url, valid)

proc call*(call_601462: Call_PutDestination_601449; body: JsonNode): Recallable =
  ## putDestination
  ## <p>Creates or updates a destination. A destination encapsulates a physical resource (such as an Amazon Kinesis stream) and enables you to subscribe to a real-time stream of log events for a different account, ingested using <a>PutLogEvents</a>. A destination can be an Amazon Kinesis stream, Amazon Kinesis Data Firehose strea, or an AWS Lambda function.</p> <p>Through an access policy, a destination controls what is written to it. By default, <code>PutDestination</code> does not set any access policy with the destination, which means a cross-account user cannot call <a>PutSubscriptionFilter</a> against this destination. To enable this, the destination owner must call <a>PutDestinationPolicy</a> after <code>PutDestination</code>.</p>
  ##   body: JObject (required)
  var body_601463 = newJObject()
  if body != nil:
    body_601463 = body
  result = call_601462.call(nil, nil, nil, nil, body_601463)

var putDestination* = Call_PutDestination_601449(name: "putDestination",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutDestination",
    validator: validate_PutDestination_601450, base: "/", url: url_PutDestination_601451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDestinationPolicy_601464 = ref object of OpenApiRestCall_600426
proc url_PutDestinationPolicy_601466(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutDestinationPolicy_601465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates or updates an access policy associated with an existing destination. An access policy is an <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/policies_overview.html">IAM policy document</a> that is used to authorize claims to register a subscription filter against a given destination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601467 = header.getOrDefault("X-Amz-Date")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Date", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Security-Token")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Security-Token", valid_601468
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601469 = header.getOrDefault("X-Amz-Target")
  valid_601469 = validateParameter(valid_601469, JString, required = true, default = newJString(
      "Logs_20140328.PutDestinationPolicy"))
  if valid_601469 != nil:
    section.add "X-Amz-Target", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Content-Sha256", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Algorithm")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Algorithm", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Signature")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Signature", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-SignedHeaders", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Credential")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Credential", valid_601474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601476: Call_PutDestinationPolicy_601464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an access policy associated with an existing destination. An access policy is an <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/policies_overview.html">IAM policy document</a> that is used to authorize claims to register a subscription filter against a given destination.
  ## 
  let valid = call_601476.validator(path, query, header, formData, body)
  let scheme = call_601476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601476.url(scheme.get, call_601476.host, call_601476.base,
                         call_601476.route, valid.getOrDefault("path"))
  result = hook(call_601476, url, valid)

proc call*(call_601477: Call_PutDestinationPolicy_601464; body: JsonNode): Recallable =
  ## putDestinationPolicy
  ## Creates or updates an access policy associated with an existing destination. An access policy is an <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/policies_overview.html">IAM policy document</a> that is used to authorize claims to register a subscription filter against a given destination.
  ##   body: JObject (required)
  var body_601478 = newJObject()
  if body != nil:
    body_601478 = body
  result = call_601477.call(nil, nil, nil, nil, body_601478)

var putDestinationPolicy* = Call_PutDestinationPolicy_601464(
    name: "putDestinationPolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutDestinationPolicy",
    validator: validate_PutDestinationPolicy_601465, base: "/",
    url: url_PutDestinationPolicy_601466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLogEvents_601479 = ref object of OpenApiRestCall_600426
proc url_PutLogEvents_601481(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutLogEvents_601480(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Uploads a batch of log events to the specified log stream.</p> <p>You must include the sequence token obtained from the response of the previous call. An upload in a newly created log stream does not require a sequence token. You can also get the sequence token using <a>DescribeLogStreams</a>. If you call <code>PutLogEvents</code> twice within a narrow time period using the same value for <code>sequenceToken</code>, both calls may be successful, or one may be rejected.</p> <p>The batch of events must satisfy the following constraints:</p> <ul> <li> <p>The maximum batch size is 1,048,576 bytes, and this size is calculated as the sum of all event messages in UTF-8, plus 26 bytes for each log event.</p> </li> <li> <p>None of the log events in the batch can be more than 2 hours in the future.</p> </li> <li> <p>None of the log events in the batch can be older than 14 days or older than the retention period of the log group.</p> </li> <li> <p>The log events in the batch must be in chronological ordered by their timestamp. The timestamp is the time the event occurred, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC. (In AWS Tools for PowerShell and the AWS SDK for .NET, the timestamp is specified in .NET format: yyyy-mm-ddThh:mm:ss. For example, 2017-09-15T13:45:30.) </p> </li> <li> <p>The maximum number of log events in a batch is 10,000.</p> </li> <li> <p>A batch of log events in a single request cannot span more than 24 hours. Otherwise, the operation fails.</p> </li> </ul> <p>If a call to PutLogEvents returns "UnrecognizedClientException" the most likely cause is an invalid AWS access key ID or secret key. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601482 = header.getOrDefault("X-Amz-Date")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Date", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Security-Token")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Security-Token", valid_601483
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601484 = header.getOrDefault("X-Amz-Target")
  valid_601484 = validateParameter(valid_601484, JString, required = true, default = newJString(
      "Logs_20140328.PutLogEvents"))
  if valid_601484 != nil:
    section.add "X-Amz-Target", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Content-Sha256", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Algorithm")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Algorithm", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Signature")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Signature", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-SignedHeaders", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Credential")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Credential", valid_601489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601491: Call_PutLogEvents_601479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a batch of log events to the specified log stream.</p> <p>You must include the sequence token obtained from the response of the previous call. An upload in a newly created log stream does not require a sequence token. You can also get the sequence token using <a>DescribeLogStreams</a>. If you call <code>PutLogEvents</code> twice within a narrow time period using the same value for <code>sequenceToken</code>, both calls may be successful, or one may be rejected.</p> <p>The batch of events must satisfy the following constraints:</p> <ul> <li> <p>The maximum batch size is 1,048,576 bytes, and this size is calculated as the sum of all event messages in UTF-8, plus 26 bytes for each log event.</p> </li> <li> <p>None of the log events in the batch can be more than 2 hours in the future.</p> </li> <li> <p>None of the log events in the batch can be older than 14 days or older than the retention period of the log group.</p> </li> <li> <p>The log events in the batch must be in chronological ordered by their timestamp. The timestamp is the time the event occurred, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC. (In AWS Tools for PowerShell and the AWS SDK for .NET, the timestamp is specified in .NET format: yyyy-mm-ddThh:mm:ss. For example, 2017-09-15T13:45:30.) </p> </li> <li> <p>The maximum number of log events in a batch is 10,000.</p> </li> <li> <p>A batch of log events in a single request cannot span more than 24 hours. Otherwise, the operation fails.</p> </li> </ul> <p>If a call to PutLogEvents returns "UnrecognizedClientException" the most likely cause is an invalid AWS access key ID or secret key. </p>
  ## 
  let valid = call_601491.validator(path, query, header, formData, body)
  let scheme = call_601491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601491.url(scheme.get, call_601491.host, call_601491.base,
                         call_601491.route, valid.getOrDefault("path"))
  result = hook(call_601491, url, valid)

proc call*(call_601492: Call_PutLogEvents_601479; body: JsonNode): Recallable =
  ## putLogEvents
  ## <p>Uploads a batch of log events to the specified log stream.</p> <p>You must include the sequence token obtained from the response of the previous call. An upload in a newly created log stream does not require a sequence token. You can also get the sequence token using <a>DescribeLogStreams</a>. If you call <code>PutLogEvents</code> twice within a narrow time period using the same value for <code>sequenceToken</code>, both calls may be successful, or one may be rejected.</p> <p>The batch of events must satisfy the following constraints:</p> <ul> <li> <p>The maximum batch size is 1,048,576 bytes, and this size is calculated as the sum of all event messages in UTF-8, plus 26 bytes for each log event.</p> </li> <li> <p>None of the log events in the batch can be more than 2 hours in the future.</p> </li> <li> <p>None of the log events in the batch can be older than 14 days or older than the retention period of the log group.</p> </li> <li> <p>The log events in the batch must be in chronological ordered by their timestamp. The timestamp is the time the event occurred, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC. (In AWS Tools for PowerShell and the AWS SDK for .NET, the timestamp is specified in .NET format: yyyy-mm-ddThh:mm:ss. For example, 2017-09-15T13:45:30.) </p> </li> <li> <p>The maximum number of log events in a batch is 10,000.</p> </li> <li> <p>A batch of log events in a single request cannot span more than 24 hours. Otherwise, the operation fails.</p> </li> </ul> <p>If a call to PutLogEvents returns "UnrecognizedClientException" the most likely cause is an invalid AWS access key ID or secret key. </p>
  ##   body: JObject (required)
  var body_601493 = newJObject()
  if body != nil:
    body_601493 = body
  result = call_601492.call(nil, nil, nil, nil, body_601493)

var putLogEvents* = Call_PutLogEvents_601479(name: "putLogEvents",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutLogEvents",
    validator: validate_PutLogEvents_601480, base: "/", url: url_PutLogEvents_601481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMetricFilter_601494 = ref object of OpenApiRestCall_600426
proc url_PutMetricFilter_601496(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutMetricFilter_601495(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates or updates a metric filter and associates it with the specified log group. Metric filters allow you to configure rules to extract metric data from log events ingested through <a>PutLogEvents</a>.</p> <p>The maximum number of metric filters that can be associated with a log group is 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601497 = header.getOrDefault("X-Amz-Date")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Date", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Security-Token")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Security-Token", valid_601498
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601499 = header.getOrDefault("X-Amz-Target")
  valid_601499 = validateParameter(valid_601499, JString, required = true, default = newJString(
      "Logs_20140328.PutMetricFilter"))
  if valid_601499 != nil:
    section.add "X-Amz-Target", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Content-Sha256", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Algorithm")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Algorithm", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Signature")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Signature", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-SignedHeaders", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Credential")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Credential", valid_601504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601506: Call_PutMetricFilter_601494; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a metric filter and associates it with the specified log group. Metric filters allow you to configure rules to extract metric data from log events ingested through <a>PutLogEvents</a>.</p> <p>The maximum number of metric filters that can be associated with a log group is 100.</p>
  ## 
  let valid = call_601506.validator(path, query, header, formData, body)
  let scheme = call_601506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601506.url(scheme.get, call_601506.host, call_601506.base,
                         call_601506.route, valid.getOrDefault("path"))
  result = hook(call_601506, url, valid)

proc call*(call_601507: Call_PutMetricFilter_601494; body: JsonNode): Recallable =
  ## putMetricFilter
  ## <p>Creates or updates a metric filter and associates it with the specified log group. Metric filters allow you to configure rules to extract metric data from log events ingested through <a>PutLogEvents</a>.</p> <p>The maximum number of metric filters that can be associated with a log group is 100.</p>
  ##   body: JObject (required)
  var body_601508 = newJObject()
  if body != nil:
    body_601508 = body
  result = call_601507.call(nil, nil, nil, nil, body_601508)

var putMetricFilter* = Call_PutMetricFilter_601494(name: "putMetricFilter",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutMetricFilter",
    validator: validate_PutMetricFilter_601495, base: "/", url: url_PutMetricFilter_601496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_601509 = ref object of OpenApiRestCall_600426
proc url_PutResourcePolicy_601511(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutResourcePolicy_601510(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates or updates a resource policy allowing other AWS services to put log events to this account, such as Amazon Route 53. An account can have up to 10 resource policies per region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601512 = header.getOrDefault("X-Amz-Date")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Date", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Security-Token")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Security-Token", valid_601513
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601514 = header.getOrDefault("X-Amz-Target")
  valid_601514 = validateParameter(valid_601514, JString, required = true, default = newJString(
      "Logs_20140328.PutResourcePolicy"))
  if valid_601514 != nil:
    section.add "X-Amz-Target", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Content-Sha256", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Algorithm")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Algorithm", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Signature")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Signature", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-SignedHeaders", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Credential")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Credential", valid_601519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601521: Call_PutResourcePolicy_601509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a resource policy allowing other AWS services to put log events to this account, such as Amazon Route 53. An account can have up to 10 resource policies per region.
  ## 
  let valid = call_601521.validator(path, query, header, formData, body)
  let scheme = call_601521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601521.url(scheme.get, call_601521.host, call_601521.base,
                         call_601521.route, valid.getOrDefault("path"))
  result = hook(call_601521, url, valid)

proc call*(call_601522: Call_PutResourcePolicy_601509; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Creates or updates a resource policy allowing other AWS services to put log events to this account, such as Amazon Route 53. An account can have up to 10 resource policies per region.
  ##   body: JObject (required)
  var body_601523 = newJObject()
  if body != nil:
    body_601523 = body
  result = call_601522.call(nil, nil, nil, nil, body_601523)

var putResourcePolicy* = Call_PutResourcePolicy_601509(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutResourcePolicy",
    validator: validate_PutResourcePolicy_601510, base: "/",
    url: url_PutResourcePolicy_601511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRetentionPolicy_601524 = ref object of OpenApiRestCall_600426
proc url_PutRetentionPolicy_601526(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutRetentionPolicy_601525(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Sets the retention of the specified log group. A retention policy allows you to configure the number of days for which to retain log events in the specified log group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601527 = header.getOrDefault("X-Amz-Date")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Date", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Security-Token")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Security-Token", valid_601528
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601529 = header.getOrDefault("X-Amz-Target")
  valid_601529 = validateParameter(valid_601529, JString, required = true, default = newJString(
      "Logs_20140328.PutRetentionPolicy"))
  if valid_601529 != nil:
    section.add "X-Amz-Target", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Content-Sha256", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Algorithm")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Algorithm", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Signature")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Signature", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-SignedHeaders", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Credential")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Credential", valid_601534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601536: Call_PutRetentionPolicy_601524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the retention of the specified log group. A retention policy allows you to configure the number of days for which to retain log events in the specified log group.
  ## 
  let valid = call_601536.validator(path, query, header, formData, body)
  let scheme = call_601536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601536.url(scheme.get, call_601536.host, call_601536.base,
                         call_601536.route, valid.getOrDefault("path"))
  result = hook(call_601536, url, valid)

proc call*(call_601537: Call_PutRetentionPolicy_601524; body: JsonNode): Recallable =
  ## putRetentionPolicy
  ## Sets the retention of the specified log group. A retention policy allows you to configure the number of days for which to retain log events in the specified log group.
  ##   body: JObject (required)
  var body_601538 = newJObject()
  if body != nil:
    body_601538 = body
  result = call_601537.call(nil, nil, nil, nil, body_601538)

var putRetentionPolicy* = Call_PutRetentionPolicy_601524(
    name: "putRetentionPolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutRetentionPolicy",
    validator: validate_PutRetentionPolicy_601525, base: "/",
    url: url_PutRetentionPolicy_601526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSubscriptionFilter_601539 = ref object of OpenApiRestCall_600426
proc url_PutSubscriptionFilter_601541(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutSubscriptionFilter_601540(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates or updates a subscription filter and associates it with the specified log group. Subscription filters allow you to subscribe to a real-time stream of log events ingested through <a>PutLogEvents</a> and have them delivered to a specific destination. Currently, the supported destinations are:</p> <ul> <li> <p>An Amazon Kinesis stream belonging to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>A logical destination that belongs to a different account, for cross-account delivery.</p> </li> <li> <p>An Amazon Kinesis Firehose delivery stream that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>An AWS Lambda function that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> </ul> <p>There can only be one subscription filter associated with a log group. If you are updating an existing filter, you must specify the correct name in <code>filterName</code>. Otherwise, the call fails because you cannot associate a second filter with a log group.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601542 = header.getOrDefault("X-Amz-Date")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Date", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Security-Token")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Security-Token", valid_601543
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601544 = header.getOrDefault("X-Amz-Target")
  valid_601544 = validateParameter(valid_601544, JString, required = true, default = newJString(
      "Logs_20140328.PutSubscriptionFilter"))
  if valid_601544 != nil:
    section.add "X-Amz-Target", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Content-Sha256", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Algorithm")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Algorithm", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Signature")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Signature", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-SignedHeaders", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Credential")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Credential", valid_601549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601551: Call_PutSubscriptionFilter_601539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a subscription filter and associates it with the specified log group. Subscription filters allow you to subscribe to a real-time stream of log events ingested through <a>PutLogEvents</a> and have them delivered to a specific destination. Currently, the supported destinations are:</p> <ul> <li> <p>An Amazon Kinesis stream belonging to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>A logical destination that belongs to a different account, for cross-account delivery.</p> </li> <li> <p>An Amazon Kinesis Firehose delivery stream that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>An AWS Lambda function that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> </ul> <p>There can only be one subscription filter associated with a log group. If you are updating an existing filter, you must specify the correct name in <code>filterName</code>. Otherwise, the call fails because you cannot associate a second filter with a log group.</p>
  ## 
  let valid = call_601551.validator(path, query, header, formData, body)
  let scheme = call_601551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601551.url(scheme.get, call_601551.host, call_601551.base,
                         call_601551.route, valid.getOrDefault("path"))
  result = hook(call_601551, url, valid)

proc call*(call_601552: Call_PutSubscriptionFilter_601539; body: JsonNode): Recallable =
  ## putSubscriptionFilter
  ## <p>Creates or updates a subscription filter and associates it with the specified log group. Subscription filters allow you to subscribe to a real-time stream of log events ingested through <a>PutLogEvents</a> and have them delivered to a specific destination. Currently, the supported destinations are:</p> <ul> <li> <p>An Amazon Kinesis stream belonging to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>A logical destination that belongs to a different account, for cross-account delivery.</p> </li> <li> <p>An Amazon Kinesis Firehose delivery stream that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>An AWS Lambda function that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> </ul> <p>There can only be one subscription filter associated with a log group. If you are updating an existing filter, you must specify the correct name in <code>filterName</code>. Otherwise, the call fails because you cannot associate a second filter with a log group.</p>
  ##   body: JObject (required)
  var body_601553 = newJObject()
  if body != nil:
    body_601553 = body
  result = call_601552.call(nil, nil, nil, nil, body_601553)

var putSubscriptionFilter* = Call_PutSubscriptionFilter_601539(
    name: "putSubscriptionFilter", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutSubscriptionFilter",
    validator: validate_PutSubscriptionFilter_601540, base: "/",
    url: url_PutSubscriptionFilter_601541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartQuery_601554 = ref object of OpenApiRestCall_600426
proc url_StartQuery_601556(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartQuery_601555(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Schedules a query of a log group using CloudWatch Logs Insights. You specify the log group and time range to query, and the query string to use.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html">CloudWatch Logs Insights Query Syntax</a>.</p> <p>Queries time out after 15 minutes of execution. If your queries are timing out, reduce the time range being searched, or partition your query into a number of queries.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601557 = header.getOrDefault("X-Amz-Date")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Date", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Security-Token")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Security-Token", valid_601558
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601559 = header.getOrDefault("X-Amz-Target")
  valid_601559 = validateParameter(valid_601559, JString, required = true, default = newJString(
      "Logs_20140328.StartQuery"))
  if valid_601559 != nil:
    section.add "X-Amz-Target", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Content-Sha256", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Algorithm")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Algorithm", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Signature")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Signature", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-SignedHeaders", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Credential")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Credential", valid_601564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601566: Call_StartQuery_601554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Schedules a query of a log group using CloudWatch Logs Insights. You specify the log group and time range to query, and the query string to use.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html">CloudWatch Logs Insights Query Syntax</a>.</p> <p>Queries time out after 15 minutes of execution. If your queries are timing out, reduce the time range being searched, or partition your query into a number of queries.</p>
  ## 
  let valid = call_601566.validator(path, query, header, formData, body)
  let scheme = call_601566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601566.url(scheme.get, call_601566.host, call_601566.base,
                         call_601566.route, valid.getOrDefault("path"))
  result = hook(call_601566, url, valid)

proc call*(call_601567: Call_StartQuery_601554; body: JsonNode): Recallable =
  ## startQuery
  ## <p>Schedules a query of a log group using CloudWatch Logs Insights. You specify the log group and time range to query, and the query string to use.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html">CloudWatch Logs Insights Query Syntax</a>.</p> <p>Queries time out after 15 minutes of execution. If your queries are timing out, reduce the time range being searched, or partition your query into a number of queries.</p>
  ##   body: JObject (required)
  var body_601568 = newJObject()
  if body != nil:
    body_601568 = body
  result = call_601567.call(nil, nil, nil, nil, body_601568)

var startQuery* = Call_StartQuery_601554(name: "startQuery",
                                      meth: HttpMethod.HttpPost,
                                      host: "logs.amazonaws.com", route: "/#X-Amz-Target=Logs_20140328.StartQuery",
                                      validator: validate_StartQuery_601555,
                                      base: "/", url: url_StartQuery_601556,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopQuery_601569 = ref object of OpenApiRestCall_600426
proc url_StopQuery_601571(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopQuery_601570(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a CloudWatch Logs Insights query that is in progress. If the query has already ended, the operation returns an error indicating that the specified query is not running.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601572 = header.getOrDefault("X-Amz-Date")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Date", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Security-Token")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Security-Token", valid_601573
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601574 = header.getOrDefault("X-Amz-Target")
  valid_601574 = validateParameter(valid_601574, JString, required = true, default = newJString(
      "Logs_20140328.StopQuery"))
  if valid_601574 != nil:
    section.add "X-Amz-Target", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Content-Sha256", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Algorithm")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Algorithm", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-Signature")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Signature", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-SignedHeaders", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Credential")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Credential", valid_601579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601581: Call_StopQuery_601569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a CloudWatch Logs Insights query that is in progress. If the query has already ended, the operation returns an error indicating that the specified query is not running.
  ## 
  let valid = call_601581.validator(path, query, header, formData, body)
  let scheme = call_601581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601581.url(scheme.get, call_601581.host, call_601581.base,
                         call_601581.route, valid.getOrDefault("path"))
  result = hook(call_601581, url, valid)

proc call*(call_601582: Call_StopQuery_601569; body: JsonNode): Recallable =
  ## stopQuery
  ## Stops a CloudWatch Logs Insights query that is in progress. If the query has already ended, the operation returns an error indicating that the specified query is not running.
  ##   body: JObject (required)
  var body_601583 = newJObject()
  if body != nil:
    body_601583 = body
  result = call_601582.call(nil, nil, nil, nil, body_601583)

var stopQuery* = Call_StopQuery_601569(name: "stopQuery", meth: HttpMethod.HttpPost,
                                    host: "logs.amazonaws.com", route: "/#X-Amz-Target=Logs_20140328.StopQuery",
                                    validator: validate_StopQuery_601570,
                                    base: "/", url: url_StopQuery_601571,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagLogGroup_601584 = ref object of OpenApiRestCall_600426
proc url_TagLogGroup_601586(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagLogGroup_601585(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds or updates the specified tags for the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To remove tags, use <a>UntagLogGroup</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/log-group-tagging.html">Tag Log Groups in Amazon CloudWatch Logs</a> in the <i>Amazon CloudWatch Logs User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601587 = header.getOrDefault("X-Amz-Date")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Date", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Security-Token")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Security-Token", valid_601588
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601589 = header.getOrDefault("X-Amz-Target")
  valid_601589 = validateParameter(valid_601589, JString, required = true, default = newJString(
      "Logs_20140328.TagLogGroup"))
  if valid_601589 != nil:
    section.add "X-Amz-Target", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Content-Sha256", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Algorithm")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Algorithm", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Signature")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Signature", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-SignedHeaders", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Credential")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Credential", valid_601594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601596: Call_TagLogGroup_601584; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or updates the specified tags for the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To remove tags, use <a>UntagLogGroup</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/log-group-tagging.html">Tag Log Groups in Amazon CloudWatch Logs</a> in the <i>Amazon CloudWatch Logs User Guide</i>.</p>
  ## 
  let valid = call_601596.validator(path, query, header, formData, body)
  let scheme = call_601596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601596.url(scheme.get, call_601596.host, call_601596.base,
                         call_601596.route, valid.getOrDefault("path"))
  result = hook(call_601596, url, valid)

proc call*(call_601597: Call_TagLogGroup_601584; body: JsonNode): Recallable =
  ## tagLogGroup
  ## <p>Adds or updates the specified tags for the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To remove tags, use <a>UntagLogGroup</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/log-group-tagging.html">Tag Log Groups in Amazon CloudWatch Logs</a> in the <i>Amazon CloudWatch Logs User Guide</i>.</p>
  ##   body: JObject (required)
  var body_601598 = newJObject()
  if body != nil:
    body_601598 = body
  result = call_601597.call(nil, nil, nil, nil, body_601598)

var tagLogGroup* = Call_TagLogGroup_601584(name: "tagLogGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "logs.amazonaws.com", route: "/#X-Amz-Target=Logs_20140328.TagLogGroup",
                                        validator: validate_TagLogGroup_601585,
                                        base: "/", url: url_TagLogGroup_601586,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestMetricFilter_601599 = ref object of OpenApiRestCall_600426
proc url_TestMetricFilter_601601(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TestMetricFilter_601600(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Tests the filter pattern of a metric filter against a sample of log event messages. You can use this operation to validate the correctness of a metric filter pattern.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601602 = header.getOrDefault("X-Amz-Date")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Date", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Security-Token")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Security-Token", valid_601603
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601604 = header.getOrDefault("X-Amz-Target")
  valid_601604 = validateParameter(valid_601604, JString, required = true, default = newJString(
      "Logs_20140328.TestMetricFilter"))
  if valid_601604 != nil:
    section.add "X-Amz-Target", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Content-Sha256", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Algorithm")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Algorithm", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Signature")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Signature", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-SignedHeaders", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Credential")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Credential", valid_601609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601611: Call_TestMetricFilter_601599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the filter pattern of a metric filter against a sample of log event messages. You can use this operation to validate the correctness of a metric filter pattern.
  ## 
  let valid = call_601611.validator(path, query, header, formData, body)
  let scheme = call_601611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601611.url(scheme.get, call_601611.host, call_601611.base,
                         call_601611.route, valid.getOrDefault("path"))
  result = hook(call_601611, url, valid)

proc call*(call_601612: Call_TestMetricFilter_601599; body: JsonNode): Recallable =
  ## testMetricFilter
  ## Tests the filter pattern of a metric filter against a sample of log event messages. You can use this operation to validate the correctness of a metric filter pattern.
  ##   body: JObject (required)
  var body_601613 = newJObject()
  if body != nil:
    body_601613 = body
  result = call_601612.call(nil, nil, nil, nil, body_601613)

var testMetricFilter* = Call_TestMetricFilter_601599(name: "testMetricFilter",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.TestMetricFilter",
    validator: validate_TestMetricFilter_601600, base: "/",
    url: url_TestMetricFilter_601601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagLogGroup_601614 = ref object of OpenApiRestCall_600426
proc url_UntagLogGroup_601616(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagLogGroup_601615(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To add tags, use <a>UntagLogGroup</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601617 = header.getOrDefault("X-Amz-Date")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Date", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Security-Token")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Security-Token", valid_601618
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601619 = header.getOrDefault("X-Amz-Target")
  valid_601619 = validateParameter(valid_601619, JString, required = true, default = newJString(
      "Logs_20140328.UntagLogGroup"))
  if valid_601619 != nil:
    section.add "X-Amz-Target", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Content-Sha256", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Algorithm")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Algorithm", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Signature")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Signature", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-SignedHeaders", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Credential")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Credential", valid_601624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601626: Call_UntagLogGroup_601614; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To add tags, use <a>UntagLogGroup</a>.</p>
  ## 
  let valid = call_601626.validator(path, query, header, formData, body)
  let scheme = call_601626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601626.url(scheme.get, call_601626.host, call_601626.base,
                         call_601626.route, valid.getOrDefault("path"))
  result = hook(call_601626, url, valid)

proc call*(call_601627: Call_UntagLogGroup_601614; body: JsonNode): Recallable =
  ## untagLogGroup
  ## <p>Removes the specified tags from the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To add tags, use <a>UntagLogGroup</a>.</p>
  ##   body: JObject (required)
  var body_601628 = newJObject()
  if body != nil:
    body_601628 = body
  result = call_601627.call(nil, nil, nil, nil, body_601628)

var untagLogGroup* = Call_UntagLogGroup_601614(name: "untagLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.UntagLogGroup",
    validator: validate_UntagLogGroup_601615, base: "/", url: url_UntagLogGroup_601616,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
