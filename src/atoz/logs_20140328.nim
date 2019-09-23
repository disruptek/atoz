
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
  result = some(head & remainder.get)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateKmsKey_600774 = ref object of OpenApiRestCall_600437
proc url_AssociateKmsKey_600776(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateKmsKey_600775(path: JsonNode; query: JsonNode;
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
  var valid_600888 = header.getOrDefault("X-Amz-Date")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Date", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Security-Token")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Security-Token", valid_600889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600903 = header.getOrDefault("X-Amz-Target")
  valid_600903 = validateParameter(valid_600903, JString, required = true, default = newJString(
      "Logs_20140328.AssociateKmsKey"))
  if valid_600903 != nil:
    section.add "X-Amz-Target", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Content-Sha256", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Algorithm")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Algorithm", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Signature")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Signature", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-SignedHeaders", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Credential")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Credential", valid_600908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600932: Call_AssociateKmsKey_600774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified AWS Key Management Service (AWS KMS) customer master key (CMK) with the specified log group.</p> <p>Associating an AWS KMS CMK with a log group overrides any existing associations between the log group and a CMK. After a CMK is associated with a log group, all newly ingested data for the log group is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p> <p>If you attempt to associate a CMK with a log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ## 
  let valid = call_600932.validator(path, query, header, formData, body)
  let scheme = call_600932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600932.url(scheme.get, call_600932.host, call_600932.base,
                         call_600932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600932, url, valid)

proc call*(call_601003: Call_AssociateKmsKey_600774; body: JsonNode): Recallable =
  ## associateKmsKey
  ## <p>Associates the specified AWS Key Management Service (AWS KMS) customer master key (CMK) with the specified log group.</p> <p>Associating an AWS KMS CMK with a log group overrides any existing associations between the log group and a CMK. After a CMK is associated with a log group, all newly ingested data for the log group is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p> <p>If you attempt to associate a CMK with a log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ##   body: JObject (required)
  var body_601004 = newJObject()
  if body != nil:
    body_601004 = body
  result = call_601003.call(nil, nil, nil, nil, body_601004)

var associateKmsKey* = Call_AssociateKmsKey_600774(name: "associateKmsKey",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.AssociateKmsKey",
    validator: validate_AssociateKmsKey_600775, base: "/", url: url_AssociateKmsKey_600776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelExportTask_601043 = ref object of OpenApiRestCall_600437
proc url_CancelExportTask_601045(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelExportTask_601044(path: JsonNode; query: JsonNode;
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
  var valid_601046 = header.getOrDefault("X-Amz-Date")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Date", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Security-Token")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Security-Token", valid_601047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601048 = header.getOrDefault("X-Amz-Target")
  valid_601048 = validateParameter(valid_601048, JString, required = true, default = newJString(
      "Logs_20140328.CancelExportTask"))
  if valid_601048 != nil:
    section.add "X-Amz-Target", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Content-Sha256", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Algorithm")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Algorithm", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Signature")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Signature", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-SignedHeaders", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Credential")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Credential", valid_601053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601055: Call_CancelExportTask_601043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels the specified export task.</p> <p>The task must be in the <code>PENDING</code> or <code>RUNNING</code> state.</p>
  ## 
  let valid = call_601055.validator(path, query, header, formData, body)
  let scheme = call_601055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601055.url(scheme.get, call_601055.host, call_601055.base,
                         call_601055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601055, url, valid)

proc call*(call_601056: Call_CancelExportTask_601043; body: JsonNode): Recallable =
  ## cancelExportTask
  ## <p>Cancels the specified export task.</p> <p>The task must be in the <code>PENDING</code> or <code>RUNNING</code> state.</p>
  ##   body: JObject (required)
  var body_601057 = newJObject()
  if body != nil:
    body_601057 = body
  result = call_601056.call(nil, nil, nil, nil, body_601057)

var cancelExportTask* = Call_CancelExportTask_601043(name: "cancelExportTask",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CancelExportTask",
    validator: validate_CancelExportTask_601044, base: "/",
    url: url_CancelExportTask_601045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportTask_601058 = ref object of OpenApiRestCall_600437
proc url_CreateExportTask_601060(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateExportTask_601059(path: JsonNode; query: JsonNode;
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
  var valid_601061 = header.getOrDefault("X-Amz-Date")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Date", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Security-Token")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Security-Token", valid_601062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601063 = header.getOrDefault("X-Amz-Target")
  valid_601063 = validateParameter(valid_601063, JString, required = true, default = newJString(
      "Logs_20140328.CreateExportTask"))
  if valid_601063 != nil:
    section.add "X-Amz-Target", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Content-Sha256", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Algorithm")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Algorithm", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Signature")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Signature", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-SignedHeaders", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Credential")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Credential", valid_601068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601070: Call_CreateExportTask_601058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an export task, which allows you to efficiently export data from a log group to an Amazon S3 bucket.</p> <p>This is an asynchronous call. If all the required information is provided, this operation initiates an export task and responds with the ID of the task. After the task has started, you can use <a>DescribeExportTasks</a> to get the status of the export task. Each account can only have one active (<code>RUNNING</code> or <code>PENDING</code>) export task at a time. To cancel an export task, use <a>CancelExportTask</a>.</p> <p>You can export logs from multiple log groups or multiple time ranges to the same S3 bucket. To separate out log data for each export task, you can specify a prefix to be used as the Amazon S3 key prefix for all exported objects.</p> <p>Exporting to S3 buckets that are encrypted with AES-256 is supported. Exporting to S3 buckets encrypted with SSE-KMS is not supported. </p>
  ## 
  let valid = call_601070.validator(path, query, header, formData, body)
  let scheme = call_601070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601070.url(scheme.get, call_601070.host, call_601070.base,
                         call_601070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601070, url, valid)

proc call*(call_601071: Call_CreateExportTask_601058; body: JsonNode): Recallable =
  ## createExportTask
  ## <p>Creates an export task, which allows you to efficiently export data from a log group to an Amazon S3 bucket.</p> <p>This is an asynchronous call. If all the required information is provided, this operation initiates an export task and responds with the ID of the task. After the task has started, you can use <a>DescribeExportTasks</a> to get the status of the export task. Each account can only have one active (<code>RUNNING</code> or <code>PENDING</code>) export task at a time. To cancel an export task, use <a>CancelExportTask</a>.</p> <p>You can export logs from multiple log groups or multiple time ranges to the same S3 bucket. To separate out log data for each export task, you can specify a prefix to be used as the Amazon S3 key prefix for all exported objects.</p> <p>Exporting to S3 buckets that are encrypted with AES-256 is supported. Exporting to S3 buckets encrypted with SSE-KMS is not supported. </p>
  ##   body: JObject (required)
  var body_601072 = newJObject()
  if body != nil:
    body_601072 = body
  result = call_601071.call(nil, nil, nil, nil, body_601072)

var createExportTask* = Call_CreateExportTask_601058(name: "createExportTask",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CreateExportTask",
    validator: validate_CreateExportTask_601059, base: "/",
    url: url_CreateExportTask_601060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogGroup_601073 = ref object of OpenApiRestCall_600437
proc url_CreateLogGroup_601075(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLogGroup_601074(path: JsonNode; query: JsonNode;
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
  var valid_601076 = header.getOrDefault("X-Amz-Date")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Date", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Security-Token")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Security-Token", valid_601077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601078 = header.getOrDefault("X-Amz-Target")
  valid_601078 = validateParameter(valid_601078, JString, required = true, default = newJString(
      "Logs_20140328.CreateLogGroup"))
  if valid_601078 != nil:
    section.add "X-Amz-Target", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Content-Sha256", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Algorithm")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Algorithm", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Signature")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Signature", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-SignedHeaders", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Credential")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Credential", valid_601083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601085: Call_CreateLogGroup_601073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a log group with the specified name.</p> <p>You can create up to 5000 log groups per account.</p> <p>You must use the following guidelines when naming a log group:</p> <ul> <li> <p>Log group names must be unique within a region for an AWS account.</p> </li> <li> <p>Log group names can be between 1 and 512 characters long.</p> </li> <li> <p>Log group names consist of the following characters: a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), '/' (forward slash), and '.' (period).</p> </li> </ul> <p>If you associate a AWS Key Management Service (AWS KMS) customer master key (CMK) with the log group, ingested data is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>If you attempt to associate a CMK with the log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ## 
  let valid = call_601085.validator(path, query, header, formData, body)
  let scheme = call_601085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601085.url(scheme.get, call_601085.host, call_601085.base,
                         call_601085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601085, url, valid)

proc call*(call_601086: Call_CreateLogGroup_601073; body: JsonNode): Recallable =
  ## createLogGroup
  ## <p>Creates a log group with the specified name.</p> <p>You can create up to 5000 log groups per account.</p> <p>You must use the following guidelines when naming a log group:</p> <ul> <li> <p>Log group names must be unique within a region for an AWS account.</p> </li> <li> <p>Log group names can be between 1 and 512 characters long.</p> </li> <li> <p>Log group names consist of the following characters: a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), '/' (forward slash), and '.' (period).</p> </li> </ul> <p>If you associate a AWS Key Management Service (AWS KMS) customer master key (CMK) with the log group, ingested data is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>If you attempt to associate a CMK with the log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ##   body: JObject (required)
  var body_601087 = newJObject()
  if body != nil:
    body_601087 = body
  result = call_601086.call(nil, nil, nil, nil, body_601087)

var createLogGroup* = Call_CreateLogGroup_601073(name: "createLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CreateLogGroup",
    validator: validate_CreateLogGroup_601074, base: "/", url: url_CreateLogGroup_601075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogStream_601088 = ref object of OpenApiRestCall_600437
proc url_CreateLogStream_601090(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLogStream_601089(path: JsonNode; query: JsonNode;
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
  var valid_601091 = header.getOrDefault("X-Amz-Date")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Date", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Security-Token")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Security-Token", valid_601092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601093 = header.getOrDefault("X-Amz-Target")
  valid_601093 = validateParameter(valid_601093, JString, required = true, default = newJString(
      "Logs_20140328.CreateLogStream"))
  if valid_601093 != nil:
    section.add "X-Amz-Target", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Content-Sha256", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Algorithm")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Algorithm", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Signature")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Signature", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-SignedHeaders", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Credential")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Credential", valid_601098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_CreateLogStream_601088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a log stream for the specified log group.</p> <p>There is no limit on the number of log streams that you can create for a log group.</p> <p>You must use the following guidelines when naming a log stream:</p> <ul> <li> <p>Log stream names must be unique within the log group.</p> </li> <li> <p>Log stream names can be between 1 and 512 characters long.</p> </li> <li> <p>The ':' (colon) and '*' (asterisk) characters are not allowed.</p> </li> </ul>
  ## 
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601100, url, valid)

proc call*(call_601101: Call_CreateLogStream_601088; body: JsonNode): Recallable =
  ## createLogStream
  ## <p>Creates a log stream for the specified log group.</p> <p>There is no limit on the number of log streams that you can create for a log group.</p> <p>You must use the following guidelines when naming a log stream:</p> <ul> <li> <p>Log stream names must be unique within the log group.</p> </li> <li> <p>Log stream names can be between 1 and 512 characters long.</p> </li> <li> <p>The ':' (colon) and '*' (asterisk) characters are not allowed.</p> </li> </ul>
  ##   body: JObject (required)
  var body_601102 = newJObject()
  if body != nil:
    body_601102 = body
  result = call_601101.call(nil, nil, nil, nil, body_601102)

var createLogStream* = Call_CreateLogStream_601088(name: "createLogStream",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CreateLogStream",
    validator: validate_CreateLogStream_601089, base: "/", url: url_CreateLogStream_601090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDestination_601103 = ref object of OpenApiRestCall_600437
proc url_DeleteDestination_601105(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDestination_601104(path: JsonNode; query: JsonNode;
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
  var valid_601106 = header.getOrDefault("X-Amz-Date")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Date", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Security-Token")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Security-Token", valid_601107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601108 = header.getOrDefault("X-Amz-Target")
  valid_601108 = validateParameter(valid_601108, JString, required = true, default = newJString(
      "Logs_20140328.DeleteDestination"))
  if valid_601108 != nil:
    section.add "X-Amz-Target", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Content-Sha256", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Algorithm")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Algorithm", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Signature")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Signature", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-SignedHeaders", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Credential")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Credential", valid_601113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601115: Call_DeleteDestination_601103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified destination, and eventually disables all the subscription filters that publish to it. This operation does not delete the physical resource encapsulated by the destination.
  ## 
  let valid = call_601115.validator(path, query, header, formData, body)
  let scheme = call_601115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601115.url(scheme.get, call_601115.host, call_601115.base,
                         call_601115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601115, url, valid)

proc call*(call_601116: Call_DeleteDestination_601103; body: JsonNode): Recallable =
  ## deleteDestination
  ## Deletes the specified destination, and eventually disables all the subscription filters that publish to it. This operation does not delete the physical resource encapsulated by the destination.
  ##   body: JObject (required)
  var body_601117 = newJObject()
  if body != nil:
    body_601117 = body
  result = call_601116.call(nil, nil, nil, nil, body_601117)

var deleteDestination* = Call_DeleteDestination_601103(name: "deleteDestination",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteDestination",
    validator: validate_DeleteDestination_601104, base: "/",
    url: url_DeleteDestination_601105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogGroup_601118 = ref object of OpenApiRestCall_600437
proc url_DeleteLogGroup_601120(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLogGroup_601119(path: JsonNode; query: JsonNode;
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
  var valid_601121 = header.getOrDefault("X-Amz-Date")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Date", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Security-Token")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Security-Token", valid_601122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601123 = header.getOrDefault("X-Amz-Target")
  valid_601123 = validateParameter(valid_601123, JString, required = true, default = newJString(
      "Logs_20140328.DeleteLogGroup"))
  if valid_601123 != nil:
    section.add "X-Amz-Target", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Content-Sha256", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Algorithm")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Algorithm", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Signature")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Signature", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-SignedHeaders", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Credential")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Credential", valid_601128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_DeleteLogGroup_601118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified log group and permanently deletes all the archived log events associated with the log group.
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601130, url, valid)

proc call*(call_601131: Call_DeleteLogGroup_601118; body: JsonNode): Recallable =
  ## deleteLogGroup
  ## Deletes the specified log group and permanently deletes all the archived log events associated with the log group.
  ##   body: JObject (required)
  var body_601132 = newJObject()
  if body != nil:
    body_601132 = body
  result = call_601131.call(nil, nil, nil, nil, body_601132)

var deleteLogGroup* = Call_DeleteLogGroup_601118(name: "deleteLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteLogGroup",
    validator: validate_DeleteLogGroup_601119, base: "/", url: url_DeleteLogGroup_601120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogStream_601133 = ref object of OpenApiRestCall_600437
proc url_DeleteLogStream_601135(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLogStream_601134(path: JsonNode; query: JsonNode;
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
  var valid_601136 = header.getOrDefault("X-Amz-Date")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Date", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Security-Token")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Security-Token", valid_601137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601138 = header.getOrDefault("X-Amz-Target")
  valid_601138 = validateParameter(valid_601138, JString, required = true, default = newJString(
      "Logs_20140328.DeleteLogStream"))
  if valid_601138 != nil:
    section.add "X-Amz-Target", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601145: Call_DeleteLogStream_601133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified log stream and permanently deletes all the archived log events associated with the log stream.
  ## 
  let valid = call_601145.validator(path, query, header, formData, body)
  let scheme = call_601145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601145.url(scheme.get, call_601145.host, call_601145.base,
                         call_601145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601145, url, valid)

proc call*(call_601146: Call_DeleteLogStream_601133; body: JsonNode): Recallable =
  ## deleteLogStream
  ## Deletes the specified log stream and permanently deletes all the archived log events associated with the log stream.
  ##   body: JObject (required)
  var body_601147 = newJObject()
  if body != nil:
    body_601147 = body
  result = call_601146.call(nil, nil, nil, nil, body_601147)

var deleteLogStream* = Call_DeleteLogStream_601133(name: "deleteLogStream",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteLogStream",
    validator: validate_DeleteLogStream_601134, base: "/", url: url_DeleteLogStream_601135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMetricFilter_601148 = ref object of OpenApiRestCall_600437
proc url_DeleteMetricFilter_601150(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMetricFilter_601149(path: JsonNode; query: JsonNode;
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
  var valid_601151 = header.getOrDefault("X-Amz-Date")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Date", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Security-Token")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Security-Token", valid_601152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601153 = header.getOrDefault("X-Amz-Target")
  valid_601153 = validateParameter(valid_601153, JString, required = true, default = newJString(
      "Logs_20140328.DeleteMetricFilter"))
  if valid_601153 != nil:
    section.add "X-Amz-Target", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_DeleteMetricFilter_601148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified metric filter.
  ## 
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601160, url, valid)

proc call*(call_601161: Call_DeleteMetricFilter_601148; body: JsonNode): Recallable =
  ## deleteMetricFilter
  ## Deletes the specified metric filter.
  ##   body: JObject (required)
  var body_601162 = newJObject()
  if body != nil:
    body_601162 = body
  result = call_601161.call(nil, nil, nil, nil, body_601162)

var deleteMetricFilter* = Call_DeleteMetricFilter_601148(
    name: "deleteMetricFilter", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteMetricFilter",
    validator: validate_DeleteMetricFilter_601149, base: "/",
    url: url_DeleteMetricFilter_601150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_601163 = ref object of OpenApiRestCall_600437
proc url_DeleteResourcePolicy_601165(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResourcePolicy_601164(path: JsonNode; query: JsonNode;
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
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601168 = header.getOrDefault("X-Amz-Target")
  valid_601168 = validateParameter(valid_601168, JString, required = true, default = newJString(
      "Logs_20140328.DeleteResourcePolicy"))
  if valid_601168 != nil:
    section.add "X-Amz-Target", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Content-Sha256", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Algorithm")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Algorithm", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Signature")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Signature", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-SignedHeaders", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Credential")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Credential", valid_601173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601175: Call_DeleteResourcePolicy_601163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource policy from this account. This revokes the access of the identities in that policy to put log events to this account.
  ## 
  let valid = call_601175.validator(path, query, header, formData, body)
  let scheme = call_601175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601175.url(scheme.get, call_601175.host, call_601175.base,
                         call_601175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601175, url, valid)

proc call*(call_601176: Call_DeleteResourcePolicy_601163; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a resource policy from this account. This revokes the access of the identities in that policy to put log events to this account.
  ##   body: JObject (required)
  var body_601177 = newJObject()
  if body != nil:
    body_601177 = body
  result = call_601176.call(nil, nil, nil, nil, body_601177)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_601163(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_601164, base: "/",
    url: url_DeleteResourcePolicy_601165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRetentionPolicy_601178 = ref object of OpenApiRestCall_600437
proc url_DeleteRetentionPolicy_601180(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRetentionPolicy_601179(path: JsonNode; query: JsonNode;
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
  var valid_601181 = header.getOrDefault("X-Amz-Date")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Date", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Security-Token")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Security-Token", valid_601182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601183 = header.getOrDefault("X-Amz-Target")
  valid_601183 = validateParameter(valid_601183, JString, required = true, default = newJString(
      "Logs_20140328.DeleteRetentionPolicy"))
  if valid_601183 != nil:
    section.add "X-Amz-Target", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601190: Call_DeleteRetentionPolicy_601178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified retention policy.</p> <p>Log events do not expire if they belong to log groups without a retention policy.</p>
  ## 
  let valid = call_601190.validator(path, query, header, formData, body)
  let scheme = call_601190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601190.url(scheme.get, call_601190.host, call_601190.base,
                         call_601190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601190, url, valid)

proc call*(call_601191: Call_DeleteRetentionPolicy_601178; body: JsonNode): Recallable =
  ## deleteRetentionPolicy
  ## <p>Deletes the specified retention policy.</p> <p>Log events do not expire if they belong to log groups without a retention policy.</p>
  ##   body: JObject (required)
  var body_601192 = newJObject()
  if body != nil:
    body_601192 = body
  result = call_601191.call(nil, nil, nil, nil, body_601192)

var deleteRetentionPolicy* = Call_DeleteRetentionPolicy_601178(
    name: "deleteRetentionPolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteRetentionPolicy",
    validator: validate_DeleteRetentionPolicy_601179, base: "/",
    url: url_DeleteRetentionPolicy_601180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionFilter_601193 = ref object of OpenApiRestCall_600437
proc url_DeleteSubscriptionFilter_601195(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSubscriptionFilter_601194(path: JsonNode; query: JsonNode;
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
  var valid_601196 = header.getOrDefault("X-Amz-Date")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Date", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Security-Token")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Security-Token", valid_601197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601198 = header.getOrDefault("X-Amz-Target")
  valid_601198 = validateParameter(valid_601198, JString, required = true, default = newJString(
      "Logs_20140328.DeleteSubscriptionFilter"))
  if valid_601198 != nil:
    section.add "X-Amz-Target", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601205: Call_DeleteSubscriptionFilter_601193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription filter.
  ## 
  let valid = call_601205.validator(path, query, header, formData, body)
  let scheme = call_601205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601205.url(scheme.get, call_601205.host, call_601205.base,
                         call_601205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601205, url, valid)

proc call*(call_601206: Call_DeleteSubscriptionFilter_601193; body: JsonNode): Recallable =
  ## deleteSubscriptionFilter
  ## Deletes the specified subscription filter.
  ##   body: JObject (required)
  var body_601207 = newJObject()
  if body != nil:
    body_601207 = body
  result = call_601206.call(nil, nil, nil, nil, body_601207)

var deleteSubscriptionFilter* = Call_DeleteSubscriptionFilter_601193(
    name: "deleteSubscriptionFilter", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteSubscriptionFilter",
    validator: validate_DeleteSubscriptionFilter_601194, base: "/",
    url: url_DeleteSubscriptionFilter_601195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDestinations_601208 = ref object of OpenApiRestCall_600437
proc url_DescribeDestinations_601210(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDestinations_601209(path: JsonNode; query: JsonNode;
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
  var valid_601211 = query.getOrDefault("nextToken")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "nextToken", valid_601211
  var valid_601212 = query.getOrDefault("limit")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "limit", valid_601212
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
  var valid_601213 = header.getOrDefault("X-Amz-Date")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Date", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Security-Token")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Security-Token", valid_601214
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601215 = header.getOrDefault("X-Amz-Target")
  valid_601215 = validateParameter(valid_601215, JString, required = true, default = newJString(
      "Logs_20140328.DescribeDestinations"))
  if valid_601215 != nil:
    section.add "X-Amz-Target", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Content-Sha256", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Algorithm")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Algorithm", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Signature")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Signature", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-SignedHeaders", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Credential")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Credential", valid_601220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601222: Call_DescribeDestinations_601208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all your destinations. The results are ASCII-sorted by destination name.
  ## 
  let valid = call_601222.validator(path, query, header, formData, body)
  let scheme = call_601222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601222.url(scheme.get, call_601222.host, call_601222.base,
                         call_601222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601222, url, valid)

proc call*(call_601223: Call_DescribeDestinations_601208; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeDestinations
  ## Lists all your destinations. The results are ASCII-sorted by destination name.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601224 = newJObject()
  var body_601225 = newJObject()
  add(query_601224, "nextToken", newJString(nextToken))
  if body != nil:
    body_601225 = body
  add(query_601224, "limit", newJString(limit))
  result = call_601223.call(nil, query_601224, nil, nil, body_601225)

var describeDestinations* = Call_DescribeDestinations_601208(
    name: "describeDestinations", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeDestinations",
    validator: validate_DescribeDestinations_601209, base: "/",
    url: url_DescribeDestinations_601210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportTasks_601227 = ref object of OpenApiRestCall_600437
proc url_DescribeExportTasks_601229(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeExportTasks_601228(path: JsonNode; query: JsonNode;
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
  var valid_601230 = header.getOrDefault("X-Amz-Date")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Date", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Security-Token")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Security-Token", valid_601231
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601232 = header.getOrDefault("X-Amz-Target")
  valid_601232 = validateParameter(valid_601232, JString, required = true, default = newJString(
      "Logs_20140328.DescribeExportTasks"))
  if valid_601232 != nil:
    section.add "X-Amz-Target", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Content-Sha256", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Algorithm")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Algorithm", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Signature")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Signature", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-SignedHeaders", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Credential")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Credential", valid_601237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601239: Call_DescribeExportTasks_601227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified export tasks. You can list all your export tasks or filter the results based on task ID or task status.
  ## 
  let valid = call_601239.validator(path, query, header, formData, body)
  let scheme = call_601239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601239.url(scheme.get, call_601239.host, call_601239.base,
                         call_601239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601239, url, valid)

proc call*(call_601240: Call_DescribeExportTasks_601227; body: JsonNode): Recallable =
  ## describeExportTasks
  ## Lists the specified export tasks. You can list all your export tasks or filter the results based on task ID or task status.
  ##   body: JObject (required)
  var body_601241 = newJObject()
  if body != nil:
    body_601241 = body
  result = call_601240.call(nil, nil, nil, nil, body_601241)

var describeExportTasks* = Call_DescribeExportTasks_601227(
    name: "describeExportTasks", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeExportTasks",
    validator: validate_DescribeExportTasks_601228, base: "/",
    url: url_DescribeExportTasks_601229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLogGroups_601242 = ref object of OpenApiRestCall_600437
proc url_DescribeLogGroups_601244(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLogGroups_601243(path: JsonNode; query: JsonNode;
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
  var valid_601245 = query.getOrDefault("nextToken")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "nextToken", valid_601245
  var valid_601246 = query.getOrDefault("limit")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "limit", valid_601246
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
  var valid_601247 = header.getOrDefault("X-Amz-Date")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Date", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Security-Token")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Security-Token", valid_601248
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601249 = header.getOrDefault("X-Amz-Target")
  valid_601249 = validateParameter(valid_601249, JString, required = true, default = newJString(
      "Logs_20140328.DescribeLogGroups"))
  if valid_601249 != nil:
    section.add "X-Amz-Target", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Content-Sha256", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Algorithm")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Algorithm", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Signature")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Signature", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-SignedHeaders", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Credential")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Credential", valid_601254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601256: Call_DescribeLogGroups_601242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified log groups. You can list all your log groups or filter the results by prefix. The results are ASCII-sorted by log group name.
  ## 
  let valid = call_601256.validator(path, query, header, formData, body)
  let scheme = call_601256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601256.url(scheme.get, call_601256.host, call_601256.base,
                         call_601256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601256, url, valid)

proc call*(call_601257: Call_DescribeLogGroups_601242; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeLogGroups
  ## Lists the specified log groups. You can list all your log groups or filter the results by prefix. The results are ASCII-sorted by log group name.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601258 = newJObject()
  var body_601259 = newJObject()
  add(query_601258, "nextToken", newJString(nextToken))
  if body != nil:
    body_601259 = body
  add(query_601258, "limit", newJString(limit))
  result = call_601257.call(nil, query_601258, nil, nil, body_601259)

var describeLogGroups* = Call_DescribeLogGroups_601242(name: "describeLogGroups",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeLogGroups",
    validator: validate_DescribeLogGroups_601243, base: "/",
    url: url_DescribeLogGroups_601244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLogStreams_601260 = ref object of OpenApiRestCall_600437
proc url_DescribeLogStreams_601262(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLogStreams_601261(path: JsonNode; query: JsonNode;
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
  var valid_601263 = query.getOrDefault("nextToken")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "nextToken", valid_601263
  var valid_601264 = query.getOrDefault("limit")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "limit", valid_601264
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
  var valid_601265 = header.getOrDefault("X-Amz-Date")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Date", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Security-Token")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Security-Token", valid_601266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601267 = header.getOrDefault("X-Amz-Target")
  valid_601267 = validateParameter(valid_601267, JString, required = true, default = newJString(
      "Logs_20140328.DescribeLogStreams"))
  if valid_601267 != nil:
    section.add "X-Amz-Target", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Content-Sha256", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Algorithm")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Algorithm", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Signature")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Signature", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-SignedHeaders", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Credential")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Credential", valid_601272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601274: Call_DescribeLogStreams_601260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the log streams for the specified log group. You can list all the log streams or filter the results by prefix. You can also control how the results are ordered.</p> <p>This operation has a limit of five transactions per second, after which transactions are throttled.</p>
  ## 
  let valid = call_601274.validator(path, query, header, formData, body)
  let scheme = call_601274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601274.url(scheme.get, call_601274.host, call_601274.base,
                         call_601274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601274, url, valid)

proc call*(call_601275: Call_DescribeLogStreams_601260; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeLogStreams
  ## <p>Lists the log streams for the specified log group. You can list all the log streams or filter the results by prefix. You can also control how the results are ordered.</p> <p>This operation has a limit of five transactions per second, after which transactions are throttled.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601276 = newJObject()
  var body_601277 = newJObject()
  add(query_601276, "nextToken", newJString(nextToken))
  if body != nil:
    body_601277 = body
  add(query_601276, "limit", newJString(limit))
  result = call_601275.call(nil, query_601276, nil, nil, body_601277)

var describeLogStreams* = Call_DescribeLogStreams_601260(
    name: "describeLogStreams", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeLogStreams",
    validator: validate_DescribeLogStreams_601261, base: "/",
    url: url_DescribeLogStreams_601262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMetricFilters_601278 = ref object of OpenApiRestCall_600437
proc url_DescribeMetricFilters_601280(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMetricFilters_601279(path: JsonNode; query: JsonNode;
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
  var valid_601281 = query.getOrDefault("nextToken")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "nextToken", valid_601281
  var valid_601282 = query.getOrDefault("limit")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "limit", valid_601282
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
  var valid_601283 = header.getOrDefault("X-Amz-Date")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Date", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Security-Token")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Security-Token", valid_601284
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601285 = header.getOrDefault("X-Amz-Target")
  valid_601285 = validateParameter(valid_601285, JString, required = true, default = newJString(
      "Logs_20140328.DescribeMetricFilters"))
  if valid_601285 != nil:
    section.add "X-Amz-Target", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Content-Sha256", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Algorithm")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Algorithm", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Signature")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Signature", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-SignedHeaders", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Credential")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Credential", valid_601290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601292: Call_DescribeMetricFilters_601278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified metric filters. You can list all the metric filters or filter the results by log name, prefix, metric name, or metric namespace. The results are ASCII-sorted by filter name.
  ## 
  let valid = call_601292.validator(path, query, header, formData, body)
  let scheme = call_601292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601292.url(scheme.get, call_601292.host, call_601292.base,
                         call_601292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601292, url, valid)

proc call*(call_601293: Call_DescribeMetricFilters_601278; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeMetricFilters
  ## Lists the specified metric filters. You can list all the metric filters or filter the results by log name, prefix, metric name, or metric namespace. The results are ASCII-sorted by filter name.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601294 = newJObject()
  var body_601295 = newJObject()
  add(query_601294, "nextToken", newJString(nextToken))
  if body != nil:
    body_601295 = body
  add(query_601294, "limit", newJString(limit))
  result = call_601293.call(nil, query_601294, nil, nil, body_601295)

var describeMetricFilters* = Call_DescribeMetricFilters_601278(
    name: "describeMetricFilters", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeMetricFilters",
    validator: validate_DescribeMetricFilters_601279, base: "/",
    url: url_DescribeMetricFilters_601280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeQueries_601296 = ref object of OpenApiRestCall_600437
proc url_DescribeQueries_601298(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeQueries_601297(path: JsonNode; query: JsonNode;
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
  var valid_601299 = header.getOrDefault("X-Amz-Date")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Date", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Security-Token")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Security-Token", valid_601300
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601301 = header.getOrDefault("X-Amz-Target")
  valid_601301 = validateParameter(valid_601301, JString, required = true, default = newJString(
      "Logs_20140328.DescribeQueries"))
  if valid_601301 != nil:
    section.add "X-Amz-Target", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Content-Sha256", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Algorithm")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Algorithm", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Signature")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Signature", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-SignedHeaders", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Credential")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Credential", valid_601306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601308: Call_DescribeQueries_601296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of CloudWatch Logs Insights queries that are scheduled, executing, or have been executed recently in this account. You can request all queries, or limit it to queries of a specific log group or queries with a certain status.
  ## 
  let valid = call_601308.validator(path, query, header, formData, body)
  let scheme = call_601308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601308.url(scheme.get, call_601308.host, call_601308.base,
                         call_601308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601308, url, valid)

proc call*(call_601309: Call_DescribeQueries_601296; body: JsonNode): Recallable =
  ## describeQueries
  ## Returns a list of CloudWatch Logs Insights queries that are scheduled, executing, or have been executed recently in this account. You can request all queries, or limit it to queries of a specific log group or queries with a certain status.
  ##   body: JObject (required)
  var body_601310 = newJObject()
  if body != nil:
    body_601310 = body
  result = call_601309.call(nil, nil, nil, nil, body_601310)

var describeQueries* = Call_DescribeQueries_601296(name: "describeQueries",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeQueries",
    validator: validate_DescribeQueries_601297, base: "/", url: url_DescribeQueries_601298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePolicies_601311 = ref object of OpenApiRestCall_600437
proc url_DescribeResourcePolicies_601313(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeResourcePolicies_601312(path: JsonNode; query: JsonNode;
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
  var valid_601314 = header.getOrDefault("X-Amz-Date")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Date", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Security-Token")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Security-Token", valid_601315
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601316 = header.getOrDefault("X-Amz-Target")
  valid_601316 = validateParameter(valid_601316, JString, required = true, default = newJString(
      "Logs_20140328.DescribeResourcePolicies"))
  if valid_601316 != nil:
    section.add "X-Amz-Target", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Content-Sha256", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Algorithm")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Algorithm", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Signature")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Signature", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-SignedHeaders", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Credential")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Credential", valid_601321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601323: Call_DescribeResourcePolicies_601311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resource policies in this account.
  ## 
  let valid = call_601323.validator(path, query, header, formData, body)
  let scheme = call_601323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601323.url(scheme.get, call_601323.host, call_601323.base,
                         call_601323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601323, url, valid)

proc call*(call_601324: Call_DescribeResourcePolicies_601311; body: JsonNode): Recallable =
  ## describeResourcePolicies
  ## Lists the resource policies in this account.
  ##   body: JObject (required)
  var body_601325 = newJObject()
  if body != nil:
    body_601325 = body
  result = call_601324.call(nil, nil, nil, nil, body_601325)

var describeResourcePolicies* = Call_DescribeResourcePolicies_601311(
    name: "describeResourcePolicies", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeResourcePolicies",
    validator: validate_DescribeResourcePolicies_601312, base: "/",
    url: url_DescribeResourcePolicies_601313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscriptionFilters_601326 = ref object of OpenApiRestCall_600437
proc url_DescribeSubscriptionFilters_601328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSubscriptionFilters_601327(path: JsonNode; query: JsonNode;
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
  var valid_601329 = query.getOrDefault("nextToken")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "nextToken", valid_601329
  var valid_601330 = query.getOrDefault("limit")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "limit", valid_601330
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
  var valid_601331 = header.getOrDefault("X-Amz-Date")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Date", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Security-Token")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Security-Token", valid_601332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601333 = header.getOrDefault("X-Amz-Target")
  valid_601333 = validateParameter(valid_601333, JString, required = true, default = newJString(
      "Logs_20140328.DescribeSubscriptionFilters"))
  if valid_601333 != nil:
    section.add "X-Amz-Target", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Content-Sha256", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Algorithm")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Algorithm", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Signature")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Signature", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-SignedHeaders", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Credential")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Credential", valid_601338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601340: Call_DescribeSubscriptionFilters_601326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the subscription filters for the specified log group. You can list all the subscription filters or filter the results by prefix. The results are ASCII-sorted by filter name.
  ## 
  let valid = call_601340.validator(path, query, header, formData, body)
  let scheme = call_601340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601340.url(scheme.get, call_601340.host, call_601340.base,
                         call_601340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601340, url, valid)

proc call*(call_601341: Call_DescribeSubscriptionFilters_601326; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeSubscriptionFilters
  ## Lists the subscription filters for the specified log group. You can list all the subscription filters or filter the results by prefix. The results are ASCII-sorted by filter name.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601342 = newJObject()
  var body_601343 = newJObject()
  add(query_601342, "nextToken", newJString(nextToken))
  if body != nil:
    body_601343 = body
  add(query_601342, "limit", newJString(limit))
  result = call_601341.call(nil, query_601342, nil, nil, body_601343)

var describeSubscriptionFilters* = Call_DescribeSubscriptionFilters_601326(
    name: "describeSubscriptionFilters", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeSubscriptionFilters",
    validator: validate_DescribeSubscriptionFilters_601327, base: "/",
    url: url_DescribeSubscriptionFilters_601328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateKmsKey_601344 = ref object of OpenApiRestCall_600437
proc url_DisassociateKmsKey_601346(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateKmsKey_601345(path: JsonNode; query: JsonNode;
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
  var valid_601347 = header.getOrDefault("X-Amz-Date")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Date", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Security-Token")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Security-Token", valid_601348
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601349 = header.getOrDefault("X-Amz-Target")
  valid_601349 = validateParameter(valid_601349, JString, required = true, default = newJString(
      "Logs_20140328.DisassociateKmsKey"))
  if valid_601349 != nil:
    section.add "X-Amz-Target", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Content-Sha256", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Algorithm")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Algorithm", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Signature")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Signature", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-SignedHeaders", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Credential")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Credential", valid_601354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601356: Call_DisassociateKmsKey_601344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the associated AWS Key Management Service (AWS KMS) customer master key (CMK) from the specified log group.</p> <p>After the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p>
  ## 
  let valid = call_601356.validator(path, query, header, formData, body)
  let scheme = call_601356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601356.url(scheme.get, call_601356.host, call_601356.base,
                         call_601356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601356, url, valid)

proc call*(call_601357: Call_DisassociateKmsKey_601344; body: JsonNode): Recallable =
  ## disassociateKmsKey
  ## <p>Disassociates the associated AWS Key Management Service (AWS KMS) customer master key (CMK) from the specified log group.</p> <p>After the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p>
  ##   body: JObject (required)
  var body_601358 = newJObject()
  if body != nil:
    body_601358 = body
  result = call_601357.call(nil, nil, nil, nil, body_601358)

var disassociateKmsKey* = Call_DisassociateKmsKey_601344(
    name: "disassociateKmsKey", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DisassociateKmsKey",
    validator: validate_DisassociateKmsKey_601345, base: "/",
    url: url_DisassociateKmsKey_601346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FilterLogEvents_601359 = ref object of OpenApiRestCall_600437
proc url_FilterLogEvents_601361(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_FilterLogEvents_601360(path: JsonNode; query: JsonNode;
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
  var valid_601362 = query.getOrDefault("nextToken")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "nextToken", valid_601362
  var valid_601363 = query.getOrDefault("limit")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "limit", valid_601363
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
  var valid_601364 = header.getOrDefault("X-Amz-Date")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Date", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Security-Token")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Security-Token", valid_601365
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601366 = header.getOrDefault("X-Amz-Target")
  valid_601366 = validateParameter(valid_601366, JString, required = true, default = newJString(
      "Logs_20140328.FilterLogEvents"))
  if valid_601366 != nil:
    section.add "X-Amz-Target", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Content-Sha256", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Algorithm")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Algorithm", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Signature")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Signature", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-SignedHeaders", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Credential")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Credential", valid_601371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601373: Call_FilterLogEvents_601359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists log events from the specified log group. You can list all the log events or filter the results using a filter pattern, a time range, and the name of the log stream.</p> <p>By default, this operation returns as many log events as can fit in 1 MB (up to 10,000 log events), or all the events found within the time range that you specify. If the results include a token, then there are more log events available, and you can get additional results by specifying the token in a subsequent call.</p>
  ## 
  let valid = call_601373.validator(path, query, header, formData, body)
  let scheme = call_601373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601373.url(scheme.get, call_601373.host, call_601373.base,
                         call_601373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601373, url, valid)

proc call*(call_601374: Call_FilterLogEvents_601359; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## filterLogEvents
  ## <p>Lists log events from the specified log group. You can list all the log events or filter the results using a filter pattern, a time range, and the name of the log stream.</p> <p>By default, this operation returns as many log events as can fit in 1 MB (up to 10,000 log events), or all the events found within the time range that you specify. If the results include a token, then there are more log events available, and you can get additional results by specifying the token in a subsequent call.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601375 = newJObject()
  var body_601376 = newJObject()
  add(query_601375, "nextToken", newJString(nextToken))
  if body != nil:
    body_601376 = body
  add(query_601375, "limit", newJString(limit))
  result = call_601374.call(nil, query_601375, nil, nil, body_601376)

var filterLogEvents* = Call_FilterLogEvents_601359(name: "filterLogEvents",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.FilterLogEvents",
    validator: validate_FilterLogEvents_601360, base: "/", url: url_FilterLogEvents_601361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLogEvents_601377 = ref object of OpenApiRestCall_600437
proc url_GetLogEvents_601379(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLogEvents_601378(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601380 = query.getOrDefault("nextToken")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "nextToken", valid_601380
  var valid_601381 = query.getOrDefault("limit")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "limit", valid_601381
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
  var valid_601382 = header.getOrDefault("X-Amz-Date")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Date", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Security-Token")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Security-Token", valid_601383
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601384 = header.getOrDefault("X-Amz-Target")
  valid_601384 = validateParameter(valid_601384, JString, required = true, default = newJString(
      "Logs_20140328.GetLogEvents"))
  if valid_601384 != nil:
    section.add "X-Amz-Target", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Content-Sha256", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Algorithm")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Algorithm", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Signature")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Signature", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-SignedHeaders", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Credential")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Credential", valid_601389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601391: Call_GetLogEvents_601377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists log events from the specified log stream. You can list all the log events or filter using a time range.</p> <p>By default, this operation returns as many log events as can fit in a response size of 1MB (up to 10,000 log events). You can get additional log events by specifying one of the tokens in a subsequent call.</p>
  ## 
  let valid = call_601391.validator(path, query, header, formData, body)
  let scheme = call_601391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601391.url(scheme.get, call_601391.host, call_601391.base,
                         call_601391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601391, url, valid)

proc call*(call_601392: Call_GetLogEvents_601377; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## getLogEvents
  ## <p>Lists log events from the specified log stream. You can list all the log events or filter using a time range.</p> <p>By default, this operation returns as many log events as can fit in a response size of 1MB (up to 10,000 log events). You can get additional log events by specifying one of the tokens in a subsequent call.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_601393 = newJObject()
  var body_601394 = newJObject()
  add(query_601393, "nextToken", newJString(nextToken))
  if body != nil:
    body_601394 = body
  add(query_601393, "limit", newJString(limit))
  result = call_601392.call(nil, query_601393, nil, nil, body_601394)

var getLogEvents* = Call_GetLogEvents_601377(name: "getLogEvents",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetLogEvents",
    validator: validate_GetLogEvents_601378, base: "/", url: url_GetLogEvents_601379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLogGroupFields_601395 = ref object of OpenApiRestCall_600437
proc url_GetLogGroupFields_601397(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLogGroupFields_601396(path: JsonNode; query: JsonNode;
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
  var valid_601398 = header.getOrDefault("X-Amz-Date")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Date", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Security-Token")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Security-Token", valid_601399
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601400 = header.getOrDefault("X-Amz-Target")
  valid_601400 = validateParameter(valid_601400, JString, required = true, default = newJString(
      "Logs_20140328.GetLogGroupFields"))
  if valid_601400 != nil:
    section.add "X-Amz-Target", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Content-Sha256", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Algorithm")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Algorithm", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Signature")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Signature", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-SignedHeaders", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Credential")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Credential", valid_601405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601407: Call_GetLogGroupFields_601395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the fields that are included in log events in the specified log group, along with the percentage of log events that contain each field. The search is limited to a time period that you specify.</p> <p>In the results, fields that start with @ are fields generated by CloudWatch Logs. For example, <code>@timestamp</code> is the timestamp of each log event.</p> <p>The response results are sorted by the frequency percentage, starting with the highest percentage.</p>
  ## 
  let valid = call_601407.validator(path, query, header, formData, body)
  let scheme = call_601407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601407.url(scheme.get, call_601407.host, call_601407.base,
                         call_601407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601407, url, valid)

proc call*(call_601408: Call_GetLogGroupFields_601395; body: JsonNode): Recallable =
  ## getLogGroupFields
  ## <p>Returns a list of the fields that are included in log events in the specified log group, along with the percentage of log events that contain each field. The search is limited to a time period that you specify.</p> <p>In the results, fields that start with @ are fields generated by CloudWatch Logs. For example, <code>@timestamp</code> is the timestamp of each log event.</p> <p>The response results are sorted by the frequency percentage, starting with the highest percentage.</p>
  ##   body: JObject (required)
  var body_601409 = newJObject()
  if body != nil:
    body_601409 = body
  result = call_601408.call(nil, nil, nil, nil, body_601409)

var getLogGroupFields* = Call_GetLogGroupFields_601395(name: "getLogGroupFields",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetLogGroupFields",
    validator: validate_GetLogGroupFields_601396, base: "/",
    url: url_GetLogGroupFields_601397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLogRecord_601410 = ref object of OpenApiRestCall_600437
proc url_GetLogRecord_601412(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLogRecord_601411(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601413 = header.getOrDefault("X-Amz-Date")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Date", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Security-Token")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Security-Token", valid_601414
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601415 = header.getOrDefault("X-Amz-Target")
  valid_601415 = validateParameter(valid_601415, JString, required = true, default = newJString(
      "Logs_20140328.GetLogRecord"))
  if valid_601415 != nil:
    section.add "X-Amz-Target", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Content-Sha256", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Algorithm")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Algorithm", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Signature")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Signature", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-SignedHeaders", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Credential")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Credential", valid_601420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601422: Call_GetLogRecord_601410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the fields and values of a single log event. All fields are retrieved, even if the original query that produced the <code>logRecordPointer</code> retrieved only a subset of fields. Fields are returned as field name/field value pairs.</p> <p>Additionally, the entire unparsed log event is returned within <code>@message</code>.</p>
  ## 
  let valid = call_601422.validator(path, query, header, formData, body)
  let scheme = call_601422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601422.url(scheme.get, call_601422.host, call_601422.base,
                         call_601422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601422, url, valid)

proc call*(call_601423: Call_GetLogRecord_601410; body: JsonNode): Recallable =
  ## getLogRecord
  ## <p>Retrieves all the fields and values of a single log event. All fields are retrieved, even if the original query that produced the <code>logRecordPointer</code> retrieved only a subset of fields. Fields are returned as field name/field value pairs.</p> <p>Additionally, the entire unparsed log event is returned within <code>@message</code>.</p>
  ##   body: JObject (required)
  var body_601424 = newJObject()
  if body != nil:
    body_601424 = body
  result = call_601423.call(nil, nil, nil, nil, body_601424)

var getLogRecord* = Call_GetLogRecord_601410(name: "getLogRecord",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetLogRecord",
    validator: validate_GetLogRecord_601411, base: "/", url: url_GetLogRecord_601412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryResults_601425 = ref object of OpenApiRestCall_600437
proc url_GetQueryResults_601427(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetQueryResults_601426(path: JsonNode; query: JsonNode;
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
  var valid_601428 = header.getOrDefault("X-Amz-Date")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Date", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Security-Token")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Security-Token", valid_601429
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601430 = header.getOrDefault("X-Amz-Target")
  valid_601430 = validateParameter(valid_601430, JString, required = true, default = newJString(
      "Logs_20140328.GetQueryResults"))
  if valid_601430 != nil:
    section.add "X-Amz-Target", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Content-Sha256", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Algorithm")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Algorithm", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Signature")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Signature", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-SignedHeaders", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Credential")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Credential", valid_601435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601437: Call_GetQueryResults_601425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the results from the specified query.</p> <p>Only the fields requested in the query are returned, along with a <code>@ptr</code> field which is the identifier for the log record. You can use the value of <code>@ptr</code> in a operation to get the full log record.</p> <p> <code>GetQueryResults</code> does not start a query execution. To run a query, use .</p> <p>If the value of the <code>Status</code> field in the output is <code>Running</code>, this operation returns only partial results. If you see a value of <code>Scheduled</code> or <code>Running</code> for the status, you can retry the operation later to see the final results. </p>
  ## 
  let valid = call_601437.validator(path, query, header, formData, body)
  let scheme = call_601437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601437.url(scheme.get, call_601437.host, call_601437.base,
                         call_601437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601437, url, valid)

proc call*(call_601438: Call_GetQueryResults_601425; body: JsonNode): Recallable =
  ## getQueryResults
  ## <p>Returns the results from the specified query.</p> <p>Only the fields requested in the query are returned, along with a <code>@ptr</code> field which is the identifier for the log record. You can use the value of <code>@ptr</code> in a operation to get the full log record.</p> <p> <code>GetQueryResults</code> does not start a query execution. To run a query, use .</p> <p>If the value of the <code>Status</code> field in the output is <code>Running</code>, this operation returns only partial results. If you see a value of <code>Scheduled</code> or <code>Running</code> for the status, you can retry the operation later to see the final results. </p>
  ##   body: JObject (required)
  var body_601439 = newJObject()
  if body != nil:
    body_601439 = body
  result = call_601438.call(nil, nil, nil, nil, body_601439)

var getQueryResults* = Call_GetQueryResults_601425(name: "getQueryResults",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetQueryResults",
    validator: validate_GetQueryResults_601426, base: "/", url: url_GetQueryResults_601427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsLogGroup_601440 = ref object of OpenApiRestCall_600437
proc url_ListTagsLogGroup_601442(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsLogGroup_601441(path: JsonNode; query: JsonNode;
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
  var valid_601443 = header.getOrDefault("X-Amz-Date")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Date", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Security-Token")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Security-Token", valid_601444
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601445 = header.getOrDefault("X-Amz-Target")
  valid_601445 = validateParameter(valid_601445, JString, required = true, default = newJString(
      "Logs_20140328.ListTagsLogGroup"))
  if valid_601445 != nil:
    section.add "X-Amz-Target", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Content-Sha256", valid_601446
  var valid_601447 = header.getOrDefault("X-Amz-Algorithm")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Algorithm", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Signature")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Signature", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-SignedHeaders", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Credential")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Credential", valid_601450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601452: Call_ListTagsLogGroup_601440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified log group.
  ## 
  let valid = call_601452.validator(path, query, header, formData, body)
  let scheme = call_601452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601452.url(scheme.get, call_601452.host, call_601452.base,
                         call_601452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601452, url, valid)

proc call*(call_601453: Call_ListTagsLogGroup_601440; body: JsonNode): Recallable =
  ## listTagsLogGroup
  ## Lists the tags for the specified log group.
  ##   body: JObject (required)
  var body_601454 = newJObject()
  if body != nil:
    body_601454 = body
  result = call_601453.call(nil, nil, nil, nil, body_601454)

var listTagsLogGroup* = Call_ListTagsLogGroup_601440(name: "listTagsLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.ListTagsLogGroup",
    validator: validate_ListTagsLogGroup_601441, base: "/",
    url: url_ListTagsLogGroup_601442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDestination_601455 = ref object of OpenApiRestCall_600437
proc url_PutDestination_601457(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDestination_601456(path: JsonNode; query: JsonNode;
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
  var valid_601458 = header.getOrDefault("X-Amz-Date")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Date", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Security-Token")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Security-Token", valid_601459
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601460 = header.getOrDefault("X-Amz-Target")
  valid_601460 = validateParameter(valid_601460, JString, required = true, default = newJString(
      "Logs_20140328.PutDestination"))
  if valid_601460 != nil:
    section.add "X-Amz-Target", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Content-Sha256", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-Algorithm")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Algorithm", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Signature")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Signature", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-SignedHeaders", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Credential")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Credential", valid_601465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601467: Call_PutDestination_601455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a destination. A destination encapsulates a physical resource (such as an Amazon Kinesis stream) and enables you to subscribe to a real-time stream of log events for a different account, ingested using <a>PutLogEvents</a>. A destination can be an Amazon Kinesis stream, Amazon Kinesis Data Firehose strea, or an AWS Lambda function.</p> <p>Through an access policy, a destination controls what is written to it. By default, <code>PutDestination</code> does not set any access policy with the destination, which means a cross-account user cannot call <a>PutSubscriptionFilter</a> against this destination. To enable this, the destination owner must call <a>PutDestinationPolicy</a> after <code>PutDestination</code>.</p>
  ## 
  let valid = call_601467.validator(path, query, header, formData, body)
  let scheme = call_601467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601467.url(scheme.get, call_601467.host, call_601467.base,
                         call_601467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601467, url, valid)

proc call*(call_601468: Call_PutDestination_601455; body: JsonNode): Recallable =
  ## putDestination
  ## <p>Creates or updates a destination. A destination encapsulates a physical resource (such as an Amazon Kinesis stream) and enables you to subscribe to a real-time stream of log events for a different account, ingested using <a>PutLogEvents</a>. A destination can be an Amazon Kinesis stream, Amazon Kinesis Data Firehose strea, or an AWS Lambda function.</p> <p>Through an access policy, a destination controls what is written to it. By default, <code>PutDestination</code> does not set any access policy with the destination, which means a cross-account user cannot call <a>PutSubscriptionFilter</a> against this destination. To enable this, the destination owner must call <a>PutDestinationPolicy</a> after <code>PutDestination</code>.</p>
  ##   body: JObject (required)
  var body_601469 = newJObject()
  if body != nil:
    body_601469 = body
  result = call_601468.call(nil, nil, nil, nil, body_601469)

var putDestination* = Call_PutDestination_601455(name: "putDestination",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutDestination",
    validator: validate_PutDestination_601456, base: "/", url: url_PutDestination_601457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDestinationPolicy_601470 = ref object of OpenApiRestCall_600437
proc url_PutDestinationPolicy_601472(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDestinationPolicy_601471(path: JsonNode; query: JsonNode;
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
  var valid_601473 = header.getOrDefault("X-Amz-Date")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Date", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Security-Token")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Security-Token", valid_601474
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601475 = header.getOrDefault("X-Amz-Target")
  valid_601475 = validateParameter(valid_601475, JString, required = true, default = newJString(
      "Logs_20140328.PutDestinationPolicy"))
  if valid_601475 != nil:
    section.add "X-Amz-Target", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Content-Sha256", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Algorithm")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Algorithm", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Signature")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Signature", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-SignedHeaders", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Credential")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Credential", valid_601480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601482: Call_PutDestinationPolicy_601470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an access policy associated with an existing destination. An access policy is an <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/policies_overview.html">IAM policy document</a> that is used to authorize claims to register a subscription filter against a given destination.
  ## 
  let valid = call_601482.validator(path, query, header, formData, body)
  let scheme = call_601482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601482.url(scheme.get, call_601482.host, call_601482.base,
                         call_601482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601482, url, valid)

proc call*(call_601483: Call_PutDestinationPolicy_601470; body: JsonNode): Recallable =
  ## putDestinationPolicy
  ## Creates or updates an access policy associated with an existing destination. An access policy is an <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/policies_overview.html">IAM policy document</a> that is used to authorize claims to register a subscription filter against a given destination.
  ##   body: JObject (required)
  var body_601484 = newJObject()
  if body != nil:
    body_601484 = body
  result = call_601483.call(nil, nil, nil, nil, body_601484)

var putDestinationPolicy* = Call_PutDestinationPolicy_601470(
    name: "putDestinationPolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutDestinationPolicy",
    validator: validate_PutDestinationPolicy_601471, base: "/",
    url: url_PutDestinationPolicy_601472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLogEvents_601485 = ref object of OpenApiRestCall_600437
proc url_PutLogEvents_601487(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutLogEvents_601486(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601488 = header.getOrDefault("X-Amz-Date")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Date", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Security-Token")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Security-Token", valid_601489
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601490 = header.getOrDefault("X-Amz-Target")
  valid_601490 = validateParameter(valid_601490, JString, required = true, default = newJString(
      "Logs_20140328.PutLogEvents"))
  if valid_601490 != nil:
    section.add "X-Amz-Target", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Content-Sha256", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Algorithm")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Algorithm", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Signature")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Signature", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-SignedHeaders", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Credential")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Credential", valid_601495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601497: Call_PutLogEvents_601485; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a batch of log events to the specified log stream.</p> <p>You must include the sequence token obtained from the response of the previous call. An upload in a newly created log stream does not require a sequence token. You can also get the sequence token using <a>DescribeLogStreams</a>. If you call <code>PutLogEvents</code> twice within a narrow time period using the same value for <code>sequenceToken</code>, both calls may be successful, or one may be rejected.</p> <p>The batch of events must satisfy the following constraints:</p> <ul> <li> <p>The maximum batch size is 1,048,576 bytes, and this size is calculated as the sum of all event messages in UTF-8, plus 26 bytes for each log event.</p> </li> <li> <p>None of the log events in the batch can be more than 2 hours in the future.</p> </li> <li> <p>None of the log events in the batch can be older than 14 days or older than the retention period of the log group.</p> </li> <li> <p>The log events in the batch must be in chronological ordered by their timestamp. The timestamp is the time the event occurred, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC. (In AWS Tools for PowerShell and the AWS SDK for .NET, the timestamp is specified in .NET format: yyyy-mm-ddThh:mm:ss. For example, 2017-09-15T13:45:30.) </p> </li> <li> <p>The maximum number of log events in a batch is 10,000.</p> </li> <li> <p>A batch of log events in a single request cannot span more than 24 hours. Otherwise, the operation fails.</p> </li> </ul> <p>If a call to PutLogEvents returns "UnrecognizedClientException" the most likely cause is an invalid AWS access key ID or secret key. </p>
  ## 
  let valid = call_601497.validator(path, query, header, formData, body)
  let scheme = call_601497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601497.url(scheme.get, call_601497.host, call_601497.base,
                         call_601497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601497, url, valid)

proc call*(call_601498: Call_PutLogEvents_601485; body: JsonNode): Recallable =
  ## putLogEvents
  ## <p>Uploads a batch of log events to the specified log stream.</p> <p>You must include the sequence token obtained from the response of the previous call. An upload in a newly created log stream does not require a sequence token. You can also get the sequence token using <a>DescribeLogStreams</a>. If you call <code>PutLogEvents</code> twice within a narrow time period using the same value for <code>sequenceToken</code>, both calls may be successful, or one may be rejected.</p> <p>The batch of events must satisfy the following constraints:</p> <ul> <li> <p>The maximum batch size is 1,048,576 bytes, and this size is calculated as the sum of all event messages in UTF-8, plus 26 bytes for each log event.</p> </li> <li> <p>None of the log events in the batch can be more than 2 hours in the future.</p> </li> <li> <p>None of the log events in the batch can be older than 14 days or older than the retention period of the log group.</p> </li> <li> <p>The log events in the batch must be in chronological ordered by their timestamp. The timestamp is the time the event occurred, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC. (In AWS Tools for PowerShell and the AWS SDK for .NET, the timestamp is specified in .NET format: yyyy-mm-ddThh:mm:ss. For example, 2017-09-15T13:45:30.) </p> </li> <li> <p>The maximum number of log events in a batch is 10,000.</p> </li> <li> <p>A batch of log events in a single request cannot span more than 24 hours. Otherwise, the operation fails.</p> </li> </ul> <p>If a call to PutLogEvents returns "UnrecognizedClientException" the most likely cause is an invalid AWS access key ID or secret key. </p>
  ##   body: JObject (required)
  var body_601499 = newJObject()
  if body != nil:
    body_601499 = body
  result = call_601498.call(nil, nil, nil, nil, body_601499)

var putLogEvents* = Call_PutLogEvents_601485(name: "putLogEvents",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutLogEvents",
    validator: validate_PutLogEvents_601486, base: "/", url: url_PutLogEvents_601487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMetricFilter_601500 = ref object of OpenApiRestCall_600437
proc url_PutMetricFilter_601502(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutMetricFilter_601501(path: JsonNode; query: JsonNode;
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
  var valid_601503 = header.getOrDefault("X-Amz-Date")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Date", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Security-Token")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Security-Token", valid_601504
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601505 = header.getOrDefault("X-Amz-Target")
  valid_601505 = validateParameter(valid_601505, JString, required = true, default = newJString(
      "Logs_20140328.PutMetricFilter"))
  if valid_601505 != nil:
    section.add "X-Amz-Target", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Content-Sha256", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Algorithm")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Algorithm", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Signature")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Signature", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-SignedHeaders", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Credential")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Credential", valid_601510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601512: Call_PutMetricFilter_601500; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a metric filter and associates it with the specified log group. Metric filters allow you to configure rules to extract metric data from log events ingested through <a>PutLogEvents</a>.</p> <p>The maximum number of metric filters that can be associated with a log group is 100.</p>
  ## 
  let valid = call_601512.validator(path, query, header, formData, body)
  let scheme = call_601512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601512.url(scheme.get, call_601512.host, call_601512.base,
                         call_601512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601512, url, valid)

proc call*(call_601513: Call_PutMetricFilter_601500; body: JsonNode): Recallable =
  ## putMetricFilter
  ## <p>Creates or updates a metric filter and associates it with the specified log group. Metric filters allow you to configure rules to extract metric data from log events ingested through <a>PutLogEvents</a>.</p> <p>The maximum number of metric filters that can be associated with a log group is 100.</p>
  ##   body: JObject (required)
  var body_601514 = newJObject()
  if body != nil:
    body_601514 = body
  result = call_601513.call(nil, nil, nil, nil, body_601514)

var putMetricFilter* = Call_PutMetricFilter_601500(name: "putMetricFilter",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutMetricFilter",
    validator: validate_PutMetricFilter_601501, base: "/", url: url_PutMetricFilter_601502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_601515 = ref object of OpenApiRestCall_600437
proc url_PutResourcePolicy_601517(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutResourcePolicy_601516(path: JsonNode; query: JsonNode;
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
  var valid_601518 = header.getOrDefault("X-Amz-Date")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Date", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Security-Token")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Security-Token", valid_601519
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601520 = header.getOrDefault("X-Amz-Target")
  valid_601520 = validateParameter(valid_601520, JString, required = true, default = newJString(
      "Logs_20140328.PutResourcePolicy"))
  if valid_601520 != nil:
    section.add "X-Amz-Target", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Content-Sha256", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Algorithm")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Algorithm", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Signature")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Signature", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-SignedHeaders", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Credential")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Credential", valid_601525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601527: Call_PutResourcePolicy_601515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a resource policy allowing other AWS services to put log events to this account, such as Amazon Route 53. An account can have up to 10 resource policies per region.
  ## 
  let valid = call_601527.validator(path, query, header, formData, body)
  let scheme = call_601527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601527.url(scheme.get, call_601527.host, call_601527.base,
                         call_601527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601527, url, valid)

proc call*(call_601528: Call_PutResourcePolicy_601515; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Creates or updates a resource policy allowing other AWS services to put log events to this account, such as Amazon Route 53. An account can have up to 10 resource policies per region.
  ##   body: JObject (required)
  var body_601529 = newJObject()
  if body != nil:
    body_601529 = body
  result = call_601528.call(nil, nil, nil, nil, body_601529)

var putResourcePolicy* = Call_PutResourcePolicy_601515(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutResourcePolicy",
    validator: validate_PutResourcePolicy_601516, base: "/",
    url: url_PutResourcePolicy_601517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRetentionPolicy_601530 = ref object of OpenApiRestCall_600437
proc url_PutRetentionPolicy_601532(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRetentionPolicy_601531(path: JsonNode; query: JsonNode;
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
  var valid_601533 = header.getOrDefault("X-Amz-Date")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Date", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Security-Token")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Security-Token", valid_601534
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601535 = header.getOrDefault("X-Amz-Target")
  valid_601535 = validateParameter(valid_601535, JString, required = true, default = newJString(
      "Logs_20140328.PutRetentionPolicy"))
  if valid_601535 != nil:
    section.add "X-Amz-Target", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Content-Sha256", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Algorithm")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Algorithm", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Signature")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Signature", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-SignedHeaders", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Credential")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Credential", valid_601540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601542: Call_PutRetentionPolicy_601530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the retention of the specified log group. A retention policy allows you to configure the number of days for which to retain log events in the specified log group.
  ## 
  let valid = call_601542.validator(path, query, header, formData, body)
  let scheme = call_601542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601542.url(scheme.get, call_601542.host, call_601542.base,
                         call_601542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601542, url, valid)

proc call*(call_601543: Call_PutRetentionPolicy_601530; body: JsonNode): Recallable =
  ## putRetentionPolicy
  ## Sets the retention of the specified log group. A retention policy allows you to configure the number of days for which to retain log events in the specified log group.
  ##   body: JObject (required)
  var body_601544 = newJObject()
  if body != nil:
    body_601544 = body
  result = call_601543.call(nil, nil, nil, nil, body_601544)

var putRetentionPolicy* = Call_PutRetentionPolicy_601530(
    name: "putRetentionPolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutRetentionPolicy",
    validator: validate_PutRetentionPolicy_601531, base: "/",
    url: url_PutRetentionPolicy_601532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSubscriptionFilter_601545 = ref object of OpenApiRestCall_600437
proc url_PutSubscriptionFilter_601547(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutSubscriptionFilter_601546(path: JsonNode; query: JsonNode;
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
  var valid_601548 = header.getOrDefault("X-Amz-Date")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Date", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Security-Token")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Security-Token", valid_601549
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601550 = header.getOrDefault("X-Amz-Target")
  valid_601550 = validateParameter(valid_601550, JString, required = true, default = newJString(
      "Logs_20140328.PutSubscriptionFilter"))
  if valid_601550 != nil:
    section.add "X-Amz-Target", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Content-Sha256", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Algorithm")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Algorithm", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Signature")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Signature", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-SignedHeaders", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Credential")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Credential", valid_601555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601557: Call_PutSubscriptionFilter_601545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a subscription filter and associates it with the specified log group. Subscription filters allow you to subscribe to a real-time stream of log events ingested through <a>PutLogEvents</a> and have them delivered to a specific destination. Currently, the supported destinations are:</p> <ul> <li> <p>An Amazon Kinesis stream belonging to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>A logical destination that belongs to a different account, for cross-account delivery.</p> </li> <li> <p>An Amazon Kinesis Firehose delivery stream that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>An AWS Lambda function that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> </ul> <p>There can only be one subscription filter associated with a log group. If you are updating an existing filter, you must specify the correct name in <code>filterName</code>. Otherwise, the call fails because you cannot associate a second filter with a log group.</p>
  ## 
  let valid = call_601557.validator(path, query, header, formData, body)
  let scheme = call_601557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601557.url(scheme.get, call_601557.host, call_601557.base,
                         call_601557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601557, url, valid)

proc call*(call_601558: Call_PutSubscriptionFilter_601545; body: JsonNode): Recallable =
  ## putSubscriptionFilter
  ## <p>Creates or updates a subscription filter and associates it with the specified log group. Subscription filters allow you to subscribe to a real-time stream of log events ingested through <a>PutLogEvents</a> and have them delivered to a specific destination. Currently, the supported destinations are:</p> <ul> <li> <p>An Amazon Kinesis stream belonging to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>A logical destination that belongs to a different account, for cross-account delivery.</p> </li> <li> <p>An Amazon Kinesis Firehose delivery stream that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>An AWS Lambda function that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> </ul> <p>There can only be one subscription filter associated with a log group. If you are updating an existing filter, you must specify the correct name in <code>filterName</code>. Otherwise, the call fails because you cannot associate a second filter with a log group.</p>
  ##   body: JObject (required)
  var body_601559 = newJObject()
  if body != nil:
    body_601559 = body
  result = call_601558.call(nil, nil, nil, nil, body_601559)

var putSubscriptionFilter* = Call_PutSubscriptionFilter_601545(
    name: "putSubscriptionFilter", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutSubscriptionFilter",
    validator: validate_PutSubscriptionFilter_601546, base: "/",
    url: url_PutSubscriptionFilter_601547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartQuery_601560 = ref object of OpenApiRestCall_600437
proc url_StartQuery_601562(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartQuery_601561(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601563 = header.getOrDefault("X-Amz-Date")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Date", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Security-Token")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Security-Token", valid_601564
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601565 = header.getOrDefault("X-Amz-Target")
  valid_601565 = validateParameter(valid_601565, JString, required = true, default = newJString(
      "Logs_20140328.StartQuery"))
  if valid_601565 != nil:
    section.add "X-Amz-Target", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Content-Sha256", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Algorithm")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Algorithm", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Signature")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Signature", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-SignedHeaders", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-Credential")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Credential", valid_601570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601572: Call_StartQuery_601560; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Schedules a query of a log group using CloudWatch Logs Insights. You specify the log group and time range to query, and the query string to use.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html">CloudWatch Logs Insights Query Syntax</a>.</p> <p>Queries time out after 15 minutes of execution. If your queries are timing out, reduce the time range being searched, or partition your query into a number of queries.</p>
  ## 
  let valid = call_601572.validator(path, query, header, formData, body)
  let scheme = call_601572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601572.url(scheme.get, call_601572.host, call_601572.base,
                         call_601572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601572, url, valid)

proc call*(call_601573: Call_StartQuery_601560; body: JsonNode): Recallable =
  ## startQuery
  ## <p>Schedules a query of a log group using CloudWatch Logs Insights. You specify the log group and time range to query, and the query string to use.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html">CloudWatch Logs Insights Query Syntax</a>.</p> <p>Queries time out after 15 minutes of execution. If your queries are timing out, reduce the time range being searched, or partition your query into a number of queries.</p>
  ##   body: JObject (required)
  var body_601574 = newJObject()
  if body != nil:
    body_601574 = body
  result = call_601573.call(nil, nil, nil, nil, body_601574)

var startQuery* = Call_StartQuery_601560(name: "startQuery",
                                      meth: HttpMethod.HttpPost,
                                      host: "logs.amazonaws.com", route: "/#X-Amz-Target=Logs_20140328.StartQuery",
                                      validator: validate_StartQuery_601561,
                                      base: "/", url: url_StartQuery_601562,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopQuery_601575 = ref object of OpenApiRestCall_600437
proc url_StopQuery_601577(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopQuery_601576(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601578 = header.getOrDefault("X-Amz-Date")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Date", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Security-Token")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Security-Token", valid_601579
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601580 = header.getOrDefault("X-Amz-Target")
  valid_601580 = validateParameter(valid_601580, JString, required = true, default = newJString(
      "Logs_20140328.StopQuery"))
  if valid_601580 != nil:
    section.add "X-Amz-Target", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Content-Sha256", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Algorithm")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Algorithm", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Signature")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Signature", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-SignedHeaders", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Credential")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Credential", valid_601585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601587: Call_StopQuery_601575; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a CloudWatch Logs Insights query that is in progress. If the query has already ended, the operation returns an error indicating that the specified query is not running.
  ## 
  let valid = call_601587.validator(path, query, header, formData, body)
  let scheme = call_601587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601587.url(scheme.get, call_601587.host, call_601587.base,
                         call_601587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601587, url, valid)

proc call*(call_601588: Call_StopQuery_601575; body: JsonNode): Recallable =
  ## stopQuery
  ## Stops a CloudWatch Logs Insights query that is in progress. If the query has already ended, the operation returns an error indicating that the specified query is not running.
  ##   body: JObject (required)
  var body_601589 = newJObject()
  if body != nil:
    body_601589 = body
  result = call_601588.call(nil, nil, nil, nil, body_601589)

var stopQuery* = Call_StopQuery_601575(name: "stopQuery", meth: HttpMethod.HttpPost,
                                    host: "logs.amazonaws.com", route: "/#X-Amz-Target=Logs_20140328.StopQuery",
                                    validator: validate_StopQuery_601576,
                                    base: "/", url: url_StopQuery_601577,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagLogGroup_601590 = ref object of OpenApiRestCall_600437
proc url_TagLogGroup_601592(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagLogGroup_601591(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601593 = header.getOrDefault("X-Amz-Date")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Date", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Security-Token")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Security-Token", valid_601594
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601595 = header.getOrDefault("X-Amz-Target")
  valid_601595 = validateParameter(valid_601595, JString, required = true, default = newJString(
      "Logs_20140328.TagLogGroup"))
  if valid_601595 != nil:
    section.add "X-Amz-Target", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Content-Sha256", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Algorithm")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Algorithm", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Signature")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Signature", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-SignedHeaders", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Credential")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Credential", valid_601600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601602: Call_TagLogGroup_601590; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or updates the specified tags for the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To remove tags, use <a>UntagLogGroup</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/log-group-tagging.html">Tag Log Groups in Amazon CloudWatch Logs</a> in the <i>Amazon CloudWatch Logs User Guide</i>.</p>
  ## 
  let valid = call_601602.validator(path, query, header, formData, body)
  let scheme = call_601602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601602.url(scheme.get, call_601602.host, call_601602.base,
                         call_601602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601602, url, valid)

proc call*(call_601603: Call_TagLogGroup_601590; body: JsonNode): Recallable =
  ## tagLogGroup
  ## <p>Adds or updates the specified tags for the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To remove tags, use <a>UntagLogGroup</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/log-group-tagging.html">Tag Log Groups in Amazon CloudWatch Logs</a> in the <i>Amazon CloudWatch Logs User Guide</i>.</p>
  ##   body: JObject (required)
  var body_601604 = newJObject()
  if body != nil:
    body_601604 = body
  result = call_601603.call(nil, nil, nil, nil, body_601604)

var tagLogGroup* = Call_TagLogGroup_601590(name: "tagLogGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "logs.amazonaws.com", route: "/#X-Amz-Target=Logs_20140328.TagLogGroup",
                                        validator: validate_TagLogGroup_601591,
                                        base: "/", url: url_TagLogGroup_601592,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestMetricFilter_601605 = ref object of OpenApiRestCall_600437
proc url_TestMetricFilter_601607(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TestMetricFilter_601606(path: JsonNode; query: JsonNode;
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
  var valid_601608 = header.getOrDefault("X-Amz-Date")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Date", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Security-Token")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Security-Token", valid_601609
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601610 = header.getOrDefault("X-Amz-Target")
  valid_601610 = validateParameter(valid_601610, JString, required = true, default = newJString(
      "Logs_20140328.TestMetricFilter"))
  if valid_601610 != nil:
    section.add "X-Amz-Target", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Content-Sha256", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Algorithm")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Algorithm", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Signature")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Signature", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-SignedHeaders", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Credential")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Credential", valid_601615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601617: Call_TestMetricFilter_601605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the filter pattern of a metric filter against a sample of log event messages. You can use this operation to validate the correctness of a metric filter pattern.
  ## 
  let valid = call_601617.validator(path, query, header, formData, body)
  let scheme = call_601617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601617.url(scheme.get, call_601617.host, call_601617.base,
                         call_601617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601617, url, valid)

proc call*(call_601618: Call_TestMetricFilter_601605; body: JsonNode): Recallable =
  ## testMetricFilter
  ## Tests the filter pattern of a metric filter against a sample of log event messages. You can use this operation to validate the correctness of a metric filter pattern.
  ##   body: JObject (required)
  var body_601619 = newJObject()
  if body != nil:
    body_601619 = body
  result = call_601618.call(nil, nil, nil, nil, body_601619)

var testMetricFilter* = Call_TestMetricFilter_601605(name: "testMetricFilter",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.TestMetricFilter",
    validator: validate_TestMetricFilter_601606, base: "/",
    url: url_TestMetricFilter_601607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagLogGroup_601620 = ref object of OpenApiRestCall_600437
proc url_UntagLogGroup_601622(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagLogGroup_601621(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601623 = header.getOrDefault("X-Amz-Date")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Date", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Security-Token")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Security-Token", valid_601624
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601625 = header.getOrDefault("X-Amz-Target")
  valid_601625 = validateParameter(valid_601625, JString, required = true, default = newJString(
      "Logs_20140328.UntagLogGroup"))
  if valid_601625 != nil:
    section.add "X-Amz-Target", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Content-Sha256", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Algorithm")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Algorithm", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Signature")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Signature", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-SignedHeaders", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Credential")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Credential", valid_601630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601632: Call_UntagLogGroup_601620; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To add tags, use <a>UntagLogGroup</a>.</p>
  ## 
  let valid = call_601632.validator(path, query, header, formData, body)
  let scheme = call_601632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601632.url(scheme.get, call_601632.host, call_601632.base,
                         call_601632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601632, url, valid)

proc call*(call_601633: Call_UntagLogGroup_601620; body: JsonNode): Recallable =
  ## untagLogGroup
  ## <p>Removes the specified tags from the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To add tags, use <a>UntagLogGroup</a>.</p>
  ##   body: JObject (required)
  var body_601634 = newJObject()
  if body != nil:
    body_601634 = body
  result = call_601633.call(nil, nil, nil, nil, body_601634)

var untagLogGroup* = Call_UntagLogGroup_601620(name: "untagLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.UntagLogGroup",
    validator: validate_UntagLogGroup_601621, base: "/", url: url_UntagLogGroup_601622,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
