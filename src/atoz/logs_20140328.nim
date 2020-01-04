
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateKmsKey_601727 = ref object of OpenApiRestCall_601389
proc url_AssociateKmsKey_601729(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateKmsKey_601728(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "Logs_20140328.AssociateKmsKey"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_AssociateKmsKey_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified AWS Key Management Service (AWS KMS) customer master key (CMK) with the specified log group.</p> <p>Associating an AWS KMS CMK with a log group overrides any existing associations between the log group and a CMK. After a CMK is associated with a log group, all newly ingested data for the log group is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p> <p>If you attempt to associate a CMK with a log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_AssociateKmsKey_601727; body: JsonNode): Recallable =
  ## associateKmsKey
  ## <p>Associates the specified AWS Key Management Service (AWS KMS) customer master key (CMK) with the specified log group.</p> <p>Associating an AWS KMS CMK with a log group overrides any existing associations between the log group and a CMK. After a CMK is associated with a log group, all newly ingested data for the log group is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p> <p>If you attempt to associate a CMK with a log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var associateKmsKey* = Call_AssociateKmsKey_601727(name: "associateKmsKey",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.AssociateKmsKey",
    validator: validate_AssociateKmsKey_601728, base: "/", url: url_AssociateKmsKey_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelExportTask_601996 = ref object of OpenApiRestCall_601389
proc url_CancelExportTask_601998(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelExportTask_601997(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "Logs_20140328.CancelExportTask"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_CancelExportTask_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels the specified export task.</p> <p>The task must be in the <code>PENDING</code> or <code>RUNNING</code> state.</p>
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CancelExportTask_601996; body: JsonNode): Recallable =
  ## cancelExportTask
  ## <p>Cancels the specified export task.</p> <p>The task must be in the <code>PENDING</code> or <code>RUNNING</code> state.</p>
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var cancelExportTask* = Call_CancelExportTask_601996(name: "cancelExportTask",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CancelExportTask",
    validator: validate_CancelExportTask_601997, base: "/",
    url: url_CancelExportTask_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportTask_602011 = ref object of OpenApiRestCall_601389
proc url_CreateExportTask_602013(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateExportTask_602012(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "Logs_20140328.CreateExportTask"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_CreateExportTask_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an export task, which allows you to efficiently export data from a log group to an Amazon S3 bucket.</p> <p>This is an asynchronous call. If all the required information is provided, this operation initiates an export task and responds with the ID of the task. After the task has started, you can use <a>DescribeExportTasks</a> to get the status of the export task. Each account can only have one active (<code>RUNNING</code> or <code>PENDING</code>) export task at a time. To cancel an export task, use <a>CancelExportTask</a>.</p> <p>You can export logs from multiple log groups or multiple time ranges to the same S3 bucket. To separate out log data for each export task, you can specify a prefix to be used as the Amazon S3 key prefix for all exported objects.</p> <p>Exporting to S3 buckets that are encrypted with AES-256 is supported. Exporting to S3 buckets encrypted with SSE-KMS is not supported. </p>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_CreateExportTask_602011; body: JsonNode): Recallable =
  ## createExportTask
  ## <p>Creates an export task, which allows you to efficiently export data from a log group to an Amazon S3 bucket.</p> <p>This is an asynchronous call. If all the required information is provided, this operation initiates an export task and responds with the ID of the task. After the task has started, you can use <a>DescribeExportTasks</a> to get the status of the export task. Each account can only have one active (<code>RUNNING</code> or <code>PENDING</code>) export task at a time. To cancel an export task, use <a>CancelExportTask</a>.</p> <p>You can export logs from multiple log groups or multiple time ranges to the same S3 bucket. To separate out log data for each export task, you can specify a prefix to be used as the Amazon S3 key prefix for all exported objects.</p> <p>Exporting to S3 buckets that are encrypted with AES-256 is supported. Exporting to S3 buckets encrypted with SSE-KMS is not supported. </p>
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var createExportTask* = Call_CreateExportTask_602011(name: "createExportTask",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CreateExportTask",
    validator: validate_CreateExportTask_602012, base: "/",
    url: url_CreateExportTask_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogGroup_602026 = ref object of OpenApiRestCall_601389
proc url_CreateLogGroup_602028(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLogGroup_602027(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a log group with the specified name.</p> <p>You can create up to 20,000 log groups per account.</p> <p>You must use the following guidelines when naming a log group:</p> <ul> <li> <p>Log group names must be unique within a region for an AWS account.</p> </li> <li> <p>Log group names can be between 1 and 512 characters long.</p> </li> <li> <p>Log group names consist of the following characters: a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), '/' (forward slash), '.' (period), and '#' (number sign)</p> </li> </ul> <p>If you associate a AWS Key Management Service (AWS KMS) customer master key (CMK) with the log group, ingested data is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>If you attempt to associate a CMK with the log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "Logs_20140328.CreateLogGroup"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_CreateLogGroup_602026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a log group with the specified name.</p> <p>You can create up to 20,000 log groups per account.</p> <p>You must use the following guidelines when naming a log group:</p> <ul> <li> <p>Log group names must be unique within a region for an AWS account.</p> </li> <li> <p>Log group names can be between 1 and 512 characters long.</p> </li> <li> <p>Log group names consist of the following characters: a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), '/' (forward slash), '.' (period), and '#' (number sign)</p> </li> </ul> <p>If you associate a AWS Key Management Service (AWS KMS) customer master key (CMK) with the log group, ingested data is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>If you attempt to associate a CMK with the log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_CreateLogGroup_602026; body: JsonNode): Recallable =
  ## createLogGroup
  ## <p>Creates a log group with the specified name.</p> <p>You can create up to 20,000 log groups per account.</p> <p>You must use the following guidelines when naming a log group:</p> <ul> <li> <p>Log group names must be unique within a region for an AWS account.</p> </li> <li> <p>Log group names can be between 1 and 512 characters long.</p> </li> <li> <p>Log group names consist of the following characters: a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), '/' (forward slash), '.' (period), and '#' (number sign)</p> </li> </ul> <p>If you associate a AWS Key Management Service (AWS KMS) customer master key (CMK) with the log group, ingested data is encrypted using the CMK. This association is stored as long as the data encrypted with the CMK is still within Amazon CloudWatch Logs. This enables Amazon CloudWatch Logs to decrypt this data whenever it is requested.</p> <p>If you attempt to associate a CMK with the log group but the CMK does not exist or the CMK is disabled, you will receive an <code>InvalidParameterException</code> error. </p>
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var createLogGroup* = Call_CreateLogGroup_602026(name: "createLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CreateLogGroup",
    validator: validate_CreateLogGroup_602027, base: "/", url: url_CreateLogGroup_602028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogStream_602041 = ref object of OpenApiRestCall_601389
proc url_CreateLogStream_602043(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLogStream_602042(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "Logs_20140328.CreateLogStream"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_CreateLogStream_602041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a log stream for the specified log group.</p> <p>There is no limit on the number of log streams that you can create for a log group.</p> <p>You must use the following guidelines when naming a log stream:</p> <ul> <li> <p>Log stream names must be unique within the log group.</p> </li> <li> <p>Log stream names can be between 1 and 512 characters long.</p> </li> <li> <p>The ':' (colon) and '*' (asterisk) characters are not allowed.</p> </li> </ul>
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_CreateLogStream_602041; body: JsonNode): Recallable =
  ## createLogStream
  ## <p>Creates a log stream for the specified log group.</p> <p>There is no limit on the number of log streams that you can create for a log group.</p> <p>You must use the following guidelines when naming a log stream:</p> <ul> <li> <p>Log stream names must be unique within the log group.</p> </li> <li> <p>Log stream names can be between 1 and 512 characters long.</p> </li> <li> <p>The ':' (colon) and '*' (asterisk) characters are not allowed.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var createLogStream* = Call_CreateLogStream_602041(name: "createLogStream",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.CreateLogStream",
    validator: validate_CreateLogStream_602042, base: "/", url: url_CreateLogStream_602043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDestination_602056 = ref object of OpenApiRestCall_601389
proc url_DeleteDestination_602058(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDestination_602057(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "Logs_20140328.DeleteDestination"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_DeleteDestination_602056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified destination, and eventually disables all the subscription filters that publish to it. This operation does not delete the physical resource encapsulated by the destination.
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_DeleteDestination_602056; body: JsonNode): Recallable =
  ## deleteDestination
  ## Deletes the specified destination, and eventually disables all the subscription filters that publish to it. This operation does not delete the physical resource encapsulated by the destination.
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var deleteDestination* = Call_DeleteDestination_602056(name: "deleteDestination",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteDestination",
    validator: validate_DeleteDestination_602057, base: "/",
    url: url_DeleteDestination_602058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogGroup_602071 = ref object of OpenApiRestCall_601389
proc url_DeleteLogGroup_602073(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLogGroup_602072(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "Logs_20140328.DeleteLogGroup"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_DeleteLogGroup_602071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified log group and permanently deletes all the archived log events associated with the log group.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_DeleteLogGroup_602071; body: JsonNode): Recallable =
  ## deleteLogGroup
  ## Deletes the specified log group and permanently deletes all the archived log events associated with the log group.
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var deleteLogGroup* = Call_DeleteLogGroup_602071(name: "deleteLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteLogGroup",
    validator: validate_DeleteLogGroup_602072, base: "/", url: url_DeleteLogGroup_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogStream_602086 = ref object of OpenApiRestCall_601389
proc url_DeleteLogStream_602088(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLogStream_602087(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "Logs_20140328.DeleteLogStream"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_DeleteLogStream_602086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified log stream and permanently deletes all the archived log events associated with the log stream.
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_DeleteLogStream_602086; body: JsonNode): Recallable =
  ## deleteLogStream
  ## Deletes the specified log stream and permanently deletes all the archived log events associated with the log stream.
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var deleteLogStream* = Call_DeleteLogStream_602086(name: "deleteLogStream",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteLogStream",
    validator: validate_DeleteLogStream_602087, base: "/", url: url_DeleteLogStream_602088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMetricFilter_602101 = ref object of OpenApiRestCall_601389
proc url_DeleteMetricFilter_602103(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMetricFilter_602102(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "Logs_20140328.DeleteMetricFilter"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_DeleteMetricFilter_602101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified metric filter.
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_DeleteMetricFilter_602101; body: JsonNode): Recallable =
  ## deleteMetricFilter
  ## Deletes the specified metric filter.
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var deleteMetricFilter* = Call_DeleteMetricFilter_602101(
    name: "deleteMetricFilter", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteMetricFilter",
    validator: validate_DeleteMetricFilter_602102, base: "/",
    url: url_DeleteMetricFilter_602103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_602116 = ref object of OpenApiRestCall_601389
proc url_DeleteResourcePolicy_602118(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourcePolicy_602117(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602119 = header.getOrDefault("X-Amz-Target")
  valid_602119 = validateParameter(valid_602119, JString, required = true, default = newJString(
      "Logs_20140328.DeleteResourcePolicy"))
  if valid_602119 != nil:
    section.add "X-Amz-Target", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Signature")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Signature", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Credential")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Credential", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Security-Token")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Security-Token", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Algorithm")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Algorithm", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-SignedHeaders", valid_602126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_DeleteResourcePolicy_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource policy from this account. This revokes the access of the identities in that policy to put log events to this account.
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_DeleteResourcePolicy_602116; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a resource policy from this account. This revokes the access of the identities in that policy to put log events to this account.
  ##   body: JObject (required)
  var body_602130 = newJObject()
  if body != nil:
    body_602130 = body
  result = call_602129.call(nil, nil, nil, nil, body_602130)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_602116(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_602117, base: "/",
    url: url_DeleteResourcePolicy_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRetentionPolicy_602131 = ref object of OpenApiRestCall_601389
proc url_DeleteRetentionPolicy_602133(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRetentionPolicy_602132(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602134 = header.getOrDefault("X-Amz-Target")
  valid_602134 = validateParameter(valid_602134, JString, required = true, default = newJString(
      "Logs_20140328.DeleteRetentionPolicy"))
  if valid_602134 != nil:
    section.add "X-Amz-Target", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_DeleteRetentionPolicy_602131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified retention policy.</p> <p>Log events do not expire if they belong to log groups without a retention policy.</p>
  ## 
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602143, url, valid)

proc call*(call_602144: Call_DeleteRetentionPolicy_602131; body: JsonNode): Recallable =
  ## deleteRetentionPolicy
  ## <p>Deletes the specified retention policy.</p> <p>Log events do not expire if they belong to log groups without a retention policy.</p>
  ##   body: JObject (required)
  var body_602145 = newJObject()
  if body != nil:
    body_602145 = body
  result = call_602144.call(nil, nil, nil, nil, body_602145)

var deleteRetentionPolicy* = Call_DeleteRetentionPolicy_602131(
    name: "deleteRetentionPolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteRetentionPolicy",
    validator: validate_DeleteRetentionPolicy_602132, base: "/",
    url: url_DeleteRetentionPolicy_602133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionFilter_602146 = ref object of OpenApiRestCall_601389
proc url_DeleteSubscriptionFilter_602148(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSubscriptionFilter_602147(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602149 = header.getOrDefault("X-Amz-Target")
  valid_602149 = validateParameter(valid_602149, JString, required = true, default = newJString(
      "Logs_20140328.DeleteSubscriptionFilter"))
  if valid_602149 != nil:
    section.add "X-Amz-Target", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602158: Call_DeleteSubscriptionFilter_602146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription filter.
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_DeleteSubscriptionFilter_602146; body: JsonNode): Recallable =
  ## deleteSubscriptionFilter
  ## Deletes the specified subscription filter.
  ##   body: JObject (required)
  var body_602160 = newJObject()
  if body != nil:
    body_602160 = body
  result = call_602159.call(nil, nil, nil, nil, body_602160)

var deleteSubscriptionFilter* = Call_DeleteSubscriptionFilter_602146(
    name: "deleteSubscriptionFilter", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DeleteSubscriptionFilter",
    validator: validate_DeleteSubscriptionFilter_602147, base: "/",
    url: url_DeleteSubscriptionFilter_602148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDestinations_602161 = ref object of OpenApiRestCall_601389
proc url_DescribeDestinations_602163(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDestinations_602162(path: JsonNode; query: JsonNode;
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
  var valid_602164 = query.getOrDefault("nextToken")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "nextToken", valid_602164
  var valid_602165 = query.getOrDefault("limit")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "limit", valid_602165
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602166 = header.getOrDefault("X-Amz-Target")
  valid_602166 = validateParameter(valid_602166, JString, required = true, default = newJString(
      "Logs_20140328.DescribeDestinations"))
  if valid_602166 != nil:
    section.add "X-Amz-Target", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Signature")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Signature", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Content-Sha256", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Date")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Date", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Credential")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Credential", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Security-Token")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Security-Token", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Algorithm")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Algorithm", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-SignedHeaders", valid_602173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602175: Call_DescribeDestinations_602161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all your destinations. The results are ASCII-sorted by destination name.
  ## 
  let valid = call_602175.validator(path, query, header, formData, body)
  let scheme = call_602175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602175.url(scheme.get, call_602175.host, call_602175.base,
                         call_602175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602175, url, valid)

proc call*(call_602176: Call_DescribeDestinations_602161; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeDestinations
  ## Lists all your destinations. The results are ASCII-sorted by destination name.
  ##   nextToken: string
  ##            : Pagination token
  ##   limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602177 = newJObject()
  var body_602178 = newJObject()
  add(query_602177, "nextToken", newJString(nextToken))
  add(query_602177, "limit", newJString(limit))
  if body != nil:
    body_602178 = body
  result = call_602176.call(nil, query_602177, nil, nil, body_602178)

var describeDestinations* = Call_DescribeDestinations_602161(
    name: "describeDestinations", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeDestinations",
    validator: validate_DescribeDestinations_602162, base: "/",
    url: url_DescribeDestinations_602163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportTasks_602180 = ref object of OpenApiRestCall_601389
proc url_DescribeExportTasks_602182(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExportTasks_602181(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602183 = header.getOrDefault("X-Amz-Target")
  valid_602183 = validateParameter(valid_602183, JString, required = true, default = newJString(
      "Logs_20140328.DescribeExportTasks"))
  if valid_602183 != nil:
    section.add "X-Amz-Target", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Signature")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Signature", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Content-Sha256", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Date")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Date", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Credential")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Credential", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Security-Token")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Security-Token", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Algorithm")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Algorithm", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-SignedHeaders", valid_602190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602192: Call_DescribeExportTasks_602180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified export tasks. You can list all your export tasks or filter the results based on task ID or task status.
  ## 
  let valid = call_602192.validator(path, query, header, formData, body)
  let scheme = call_602192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602192.url(scheme.get, call_602192.host, call_602192.base,
                         call_602192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602192, url, valid)

proc call*(call_602193: Call_DescribeExportTasks_602180; body: JsonNode): Recallable =
  ## describeExportTasks
  ## Lists the specified export tasks. You can list all your export tasks or filter the results based on task ID or task status.
  ##   body: JObject (required)
  var body_602194 = newJObject()
  if body != nil:
    body_602194 = body
  result = call_602193.call(nil, nil, nil, nil, body_602194)

var describeExportTasks* = Call_DescribeExportTasks_602180(
    name: "describeExportTasks", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeExportTasks",
    validator: validate_DescribeExportTasks_602181, base: "/",
    url: url_DescribeExportTasks_602182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLogGroups_602195 = ref object of OpenApiRestCall_601389
proc url_DescribeLogGroups_602197(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLogGroups_602196(path: JsonNode; query: JsonNode;
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
  var valid_602198 = query.getOrDefault("nextToken")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "nextToken", valid_602198
  var valid_602199 = query.getOrDefault("limit")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "limit", valid_602199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602200 = header.getOrDefault("X-Amz-Target")
  valid_602200 = validateParameter(valid_602200, JString, required = true, default = newJString(
      "Logs_20140328.DescribeLogGroups"))
  if valid_602200 != nil:
    section.add "X-Amz-Target", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Signature")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Signature", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Content-Sha256", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Date")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Date", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Credential")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Credential", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Security-Token")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Security-Token", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Algorithm")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Algorithm", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-SignedHeaders", valid_602207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602209: Call_DescribeLogGroups_602195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified log groups. You can list all your log groups or filter the results by prefix. The results are ASCII-sorted by log group name.
  ## 
  let valid = call_602209.validator(path, query, header, formData, body)
  let scheme = call_602209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602209.url(scheme.get, call_602209.host, call_602209.base,
                         call_602209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602209, url, valid)

proc call*(call_602210: Call_DescribeLogGroups_602195; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeLogGroups
  ## Lists the specified log groups. You can list all your log groups or filter the results by prefix. The results are ASCII-sorted by log group name.
  ##   nextToken: string
  ##            : Pagination token
  ##   limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602211 = newJObject()
  var body_602212 = newJObject()
  add(query_602211, "nextToken", newJString(nextToken))
  add(query_602211, "limit", newJString(limit))
  if body != nil:
    body_602212 = body
  result = call_602210.call(nil, query_602211, nil, nil, body_602212)

var describeLogGroups* = Call_DescribeLogGroups_602195(name: "describeLogGroups",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeLogGroups",
    validator: validate_DescribeLogGroups_602196, base: "/",
    url: url_DescribeLogGroups_602197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLogStreams_602213 = ref object of OpenApiRestCall_601389
proc url_DescribeLogStreams_602215(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLogStreams_602214(path: JsonNode; query: JsonNode;
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
  var valid_602216 = query.getOrDefault("nextToken")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "nextToken", valid_602216
  var valid_602217 = query.getOrDefault("limit")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "limit", valid_602217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602218 = header.getOrDefault("X-Amz-Target")
  valid_602218 = validateParameter(valid_602218, JString, required = true, default = newJString(
      "Logs_20140328.DescribeLogStreams"))
  if valid_602218 != nil:
    section.add "X-Amz-Target", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Signature")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Signature", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Content-Sha256", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Date")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Date", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Credential")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Credential", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Security-Token")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Security-Token", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Algorithm")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Algorithm", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-SignedHeaders", valid_602225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602227: Call_DescribeLogStreams_602213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the log streams for the specified log group. You can list all the log streams or filter the results by prefix. You can also control how the results are ordered.</p> <p>This operation has a limit of five transactions per second, after which transactions are throttled.</p>
  ## 
  let valid = call_602227.validator(path, query, header, formData, body)
  let scheme = call_602227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602227.url(scheme.get, call_602227.host, call_602227.base,
                         call_602227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602227, url, valid)

proc call*(call_602228: Call_DescribeLogStreams_602213; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeLogStreams
  ## <p>Lists the log streams for the specified log group. You can list all the log streams or filter the results by prefix. You can also control how the results are ordered.</p> <p>This operation has a limit of five transactions per second, after which transactions are throttled.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602229 = newJObject()
  var body_602230 = newJObject()
  add(query_602229, "nextToken", newJString(nextToken))
  add(query_602229, "limit", newJString(limit))
  if body != nil:
    body_602230 = body
  result = call_602228.call(nil, query_602229, nil, nil, body_602230)

var describeLogStreams* = Call_DescribeLogStreams_602213(
    name: "describeLogStreams", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeLogStreams",
    validator: validate_DescribeLogStreams_602214, base: "/",
    url: url_DescribeLogStreams_602215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMetricFilters_602231 = ref object of OpenApiRestCall_601389
proc url_DescribeMetricFilters_602233(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMetricFilters_602232(path: JsonNode; query: JsonNode;
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
  var valid_602234 = query.getOrDefault("nextToken")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "nextToken", valid_602234
  var valid_602235 = query.getOrDefault("limit")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "limit", valid_602235
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602236 = header.getOrDefault("X-Amz-Target")
  valid_602236 = validateParameter(valid_602236, JString, required = true, default = newJString(
      "Logs_20140328.DescribeMetricFilters"))
  if valid_602236 != nil:
    section.add "X-Amz-Target", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Signature")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Signature", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Content-Sha256", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Date")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Date", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Credential")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Credential", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Security-Token")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Security-Token", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Algorithm")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Algorithm", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-SignedHeaders", valid_602243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602245: Call_DescribeMetricFilters_602231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified metric filters. You can list all the metric filters or filter the results by log name, prefix, metric name, or metric namespace. The results are ASCII-sorted by filter name.
  ## 
  let valid = call_602245.validator(path, query, header, formData, body)
  let scheme = call_602245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602245.url(scheme.get, call_602245.host, call_602245.base,
                         call_602245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602245, url, valid)

proc call*(call_602246: Call_DescribeMetricFilters_602231; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeMetricFilters
  ## Lists the specified metric filters. You can list all the metric filters or filter the results by log name, prefix, metric name, or metric namespace. The results are ASCII-sorted by filter name.
  ##   nextToken: string
  ##            : Pagination token
  ##   limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602247 = newJObject()
  var body_602248 = newJObject()
  add(query_602247, "nextToken", newJString(nextToken))
  add(query_602247, "limit", newJString(limit))
  if body != nil:
    body_602248 = body
  result = call_602246.call(nil, query_602247, nil, nil, body_602248)

var describeMetricFilters* = Call_DescribeMetricFilters_602231(
    name: "describeMetricFilters", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeMetricFilters",
    validator: validate_DescribeMetricFilters_602232, base: "/",
    url: url_DescribeMetricFilters_602233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeQueries_602249 = ref object of OpenApiRestCall_601389
proc url_DescribeQueries_602251(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeQueries_602250(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602252 = header.getOrDefault("X-Amz-Target")
  valid_602252 = validateParameter(valid_602252, JString, required = true, default = newJString(
      "Logs_20140328.DescribeQueries"))
  if valid_602252 != nil:
    section.add "X-Amz-Target", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Signature")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Signature", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Content-Sha256", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Date")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Date", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Credential")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Credential", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Security-Token")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Security-Token", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Algorithm")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Algorithm", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-SignedHeaders", valid_602259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602261: Call_DescribeQueries_602249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of CloudWatch Logs Insights queries that are scheduled, executing, or have been executed recently in this account. You can request all queries, or limit it to queries of a specific log group or queries with a certain status.
  ## 
  let valid = call_602261.validator(path, query, header, formData, body)
  let scheme = call_602261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602261.url(scheme.get, call_602261.host, call_602261.base,
                         call_602261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602261, url, valid)

proc call*(call_602262: Call_DescribeQueries_602249; body: JsonNode): Recallable =
  ## describeQueries
  ## Returns a list of CloudWatch Logs Insights queries that are scheduled, executing, or have been executed recently in this account. You can request all queries, or limit it to queries of a specific log group or queries with a certain status.
  ##   body: JObject (required)
  var body_602263 = newJObject()
  if body != nil:
    body_602263 = body
  result = call_602262.call(nil, nil, nil, nil, body_602263)

var describeQueries* = Call_DescribeQueries_602249(name: "describeQueries",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeQueries",
    validator: validate_DescribeQueries_602250, base: "/", url: url_DescribeQueries_602251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePolicies_602264 = ref object of OpenApiRestCall_601389
proc url_DescribeResourcePolicies_602266(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeResourcePolicies_602265(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602267 = header.getOrDefault("X-Amz-Target")
  valid_602267 = validateParameter(valid_602267, JString, required = true, default = newJString(
      "Logs_20140328.DescribeResourcePolicies"))
  if valid_602267 != nil:
    section.add "X-Amz-Target", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Signature")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Signature", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Content-Sha256", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Date")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Date", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Credential")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Credential", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Security-Token")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Security-Token", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Algorithm")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Algorithm", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-SignedHeaders", valid_602274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602276: Call_DescribeResourcePolicies_602264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resource policies in this account.
  ## 
  let valid = call_602276.validator(path, query, header, formData, body)
  let scheme = call_602276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602276.url(scheme.get, call_602276.host, call_602276.base,
                         call_602276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602276, url, valid)

proc call*(call_602277: Call_DescribeResourcePolicies_602264; body: JsonNode): Recallable =
  ## describeResourcePolicies
  ## Lists the resource policies in this account.
  ##   body: JObject (required)
  var body_602278 = newJObject()
  if body != nil:
    body_602278 = body
  result = call_602277.call(nil, nil, nil, nil, body_602278)

var describeResourcePolicies* = Call_DescribeResourcePolicies_602264(
    name: "describeResourcePolicies", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeResourcePolicies",
    validator: validate_DescribeResourcePolicies_602265, base: "/",
    url: url_DescribeResourcePolicies_602266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscriptionFilters_602279 = ref object of OpenApiRestCall_601389
proc url_DescribeSubscriptionFilters_602281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSubscriptionFilters_602280(path: JsonNode; query: JsonNode;
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
  var valid_602282 = query.getOrDefault("nextToken")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "nextToken", valid_602282
  var valid_602283 = query.getOrDefault("limit")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "limit", valid_602283
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602284 = header.getOrDefault("X-Amz-Target")
  valid_602284 = validateParameter(valid_602284, JString, required = true, default = newJString(
      "Logs_20140328.DescribeSubscriptionFilters"))
  if valid_602284 != nil:
    section.add "X-Amz-Target", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Signature")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Signature", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Content-Sha256", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Date")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Date", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Credential")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Credential", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Security-Token")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Security-Token", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Algorithm")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Algorithm", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-SignedHeaders", valid_602291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602293: Call_DescribeSubscriptionFilters_602279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the subscription filters for the specified log group. You can list all the subscription filters or filter the results by prefix. The results are ASCII-sorted by filter name.
  ## 
  let valid = call_602293.validator(path, query, header, formData, body)
  let scheme = call_602293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602293.url(scheme.get, call_602293.host, call_602293.base,
                         call_602293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602293, url, valid)

proc call*(call_602294: Call_DescribeSubscriptionFilters_602279; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## describeSubscriptionFilters
  ## Lists the subscription filters for the specified log group. You can list all the subscription filters or filter the results by prefix. The results are ASCII-sorted by filter name.
  ##   nextToken: string
  ##            : Pagination token
  ##   limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602295 = newJObject()
  var body_602296 = newJObject()
  add(query_602295, "nextToken", newJString(nextToken))
  add(query_602295, "limit", newJString(limit))
  if body != nil:
    body_602296 = body
  result = call_602294.call(nil, query_602295, nil, nil, body_602296)

var describeSubscriptionFilters* = Call_DescribeSubscriptionFilters_602279(
    name: "describeSubscriptionFilters", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DescribeSubscriptionFilters",
    validator: validate_DescribeSubscriptionFilters_602280, base: "/",
    url: url_DescribeSubscriptionFilters_602281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateKmsKey_602297 = ref object of OpenApiRestCall_601389
proc url_DisassociateKmsKey_602299(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateKmsKey_602298(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602300 = header.getOrDefault("X-Amz-Target")
  valid_602300 = validateParameter(valid_602300, JString, required = true, default = newJString(
      "Logs_20140328.DisassociateKmsKey"))
  if valid_602300 != nil:
    section.add "X-Amz-Target", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Signature")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Signature", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Content-Sha256", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Date")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Date", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Credential")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Credential", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Security-Token")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Security-Token", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Algorithm")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Algorithm", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-SignedHeaders", valid_602307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602309: Call_DisassociateKmsKey_602297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the associated AWS Key Management Service (AWS KMS) customer master key (CMK) from the specified log group.</p> <p>After the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p>
  ## 
  let valid = call_602309.validator(path, query, header, formData, body)
  let scheme = call_602309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602309.url(scheme.get, call_602309.host, call_602309.base,
                         call_602309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602309, url, valid)

proc call*(call_602310: Call_DisassociateKmsKey_602297; body: JsonNode): Recallable =
  ## disassociateKmsKey
  ## <p>Disassociates the associated AWS Key Management Service (AWS KMS) customer master key (CMK) from the specified log group.</p> <p>After the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested.</p> <p>Note that it can take up to 5 minutes for this operation to take effect.</p>
  ##   body: JObject (required)
  var body_602311 = newJObject()
  if body != nil:
    body_602311 = body
  result = call_602310.call(nil, nil, nil, nil, body_602311)

var disassociateKmsKey* = Call_DisassociateKmsKey_602297(
    name: "disassociateKmsKey", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.DisassociateKmsKey",
    validator: validate_DisassociateKmsKey_602298, base: "/",
    url: url_DisassociateKmsKey_602299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FilterLogEvents_602312 = ref object of OpenApiRestCall_601389
proc url_FilterLogEvents_602314(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_FilterLogEvents_602313(path: JsonNode; query: JsonNode;
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
  var valid_602315 = query.getOrDefault("nextToken")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "nextToken", valid_602315
  var valid_602316 = query.getOrDefault("limit")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "limit", valid_602316
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602317 = header.getOrDefault("X-Amz-Target")
  valid_602317 = validateParameter(valid_602317, JString, required = true, default = newJString(
      "Logs_20140328.FilterLogEvents"))
  if valid_602317 != nil:
    section.add "X-Amz-Target", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Signature")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Signature", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Content-Sha256", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Date")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Date", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Credential")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Credential", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Security-Token")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Security-Token", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Algorithm")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Algorithm", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-SignedHeaders", valid_602324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602326: Call_FilterLogEvents_602312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists log events from the specified log group. You can list all the log events or filter the results using a filter pattern, a time range, and the name of the log stream.</p> <p>By default, this operation returns as many log events as can fit in 1 MB (up to 10,000 log events), or all the events found within the time range that you specify. If the results include a token, then there are more log events available, and you can get additional results by specifying the token in a subsequent call.</p>
  ## 
  let valid = call_602326.validator(path, query, header, formData, body)
  let scheme = call_602326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602326.url(scheme.get, call_602326.host, call_602326.base,
                         call_602326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602326, url, valid)

proc call*(call_602327: Call_FilterLogEvents_602312; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## filterLogEvents
  ## <p>Lists log events from the specified log group. You can list all the log events or filter the results using a filter pattern, a time range, and the name of the log stream.</p> <p>By default, this operation returns as many log events as can fit in 1 MB (up to 10,000 log events), or all the events found within the time range that you specify. If the results include a token, then there are more log events available, and you can get additional results by specifying the token in a subsequent call.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602328 = newJObject()
  var body_602329 = newJObject()
  add(query_602328, "nextToken", newJString(nextToken))
  add(query_602328, "limit", newJString(limit))
  if body != nil:
    body_602329 = body
  result = call_602327.call(nil, query_602328, nil, nil, body_602329)

var filterLogEvents* = Call_FilterLogEvents_602312(name: "filterLogEvents",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.FilterLogEvents",
    validator: validate_FilterLogEvents_602313, base: "/", url: url_FilterLogEvents_602314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLogEvents_602330 = ref object of OpenApiRestCall_601389
proc url_GetLogEvents_602332(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLogEvents_602331(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602333 = query.getOrDefault("nextToken")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "nextToken", valid_602333
  var valid_602334 = query.getOrDefault("limit")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "limit", valid_602334
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602335 = header.getOrDefault("X-Amz-Target")
  valid_602335 = validateParameter(valid_602335, JString, required = true, default = newJString(
      "Logs_20140328.GetLogEvents"))
  if valid_602335 != nil:
    section.add "X-Amz-Target", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Signature")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Signature", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Content-Sha256", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Date")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Date", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Credential")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Credential", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Security-Token")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Security-Token", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Algorithm")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Algorithm", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-SignedHeaders", valid_602342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602344: Call_GetLogEvents_602330; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists log events from the specified log stream. You can list all the log events or filter using a time range.</p> <p>By default, this operation returns as many log events as can fit in a response size of 1MB (up to 10,000 log events). You can get additional log events by specifying one of the tokens in a subsequent call.</p>
  ## 
  let valid = call_602344.validator(path, query, header, formData, body)
  let scheme = call_602344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602344.url(scheme.get, call_602344.host, call_602344.base,
                         call_602344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602344, url, valid)

proc call*(call_602345: Call_GetLogEvents_602330; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## getLogEvents
  ## <p>Lists log events from the specified log stream. You can list all the log events or filter using a time range.</p> <p>By default, this operation returns as many log events as can fit in a response size of 1MB (up to 10,000 log events). You can get additional log events by specifying one of the tokens in a subsequent call.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602346 = newJObject()
  var body_602347 = newJObject()
  add(query_602346, "nextToken", newJString(nextToken))
  add(query_602346, "limit", newJString(limit))
  if body != nil:
    body_602347 = body
  result = call_602345.call(nil, query_602346, nil, nil, body_602347)

var getLogEvents* = Call_GetLogEvents_602330(name: "getLogEvents",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetLogEvents",
    validator: validate_GetLogEvents_602331, base: "/", url: url_GetLogEvents_602332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLogGroupFields_602348 = ref object of OpenApiRestCall_601389
proc url_GetLogGroupFields_602350(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLogGroupFields_602349(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602351 = header.getOrDefault("X-Amz-Target")
  valid_602351 = validateParameter(valid_602351, JString, required = true, default = newJString(
      "Logs_20140328.GetLogGroupFields"))
  if valid_602351 != nil:
    section.add "X-Amz-Target", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Signature")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Signature", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Content-Sha256", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Date")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Date", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Credential")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Credential", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Security-Token")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Security-Token", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Algorithm")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Algorithm", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-SignedHeaders", valid_602358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602360: Call_GetLogGroupFields_602348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the fields that are included in log events in the specified log group, along with the percentage of log events that contain each field. The search is limited to a time period that you specify.</p> <p>In the results, fields that start with @ are fields generated by CloudWatch Logs. For example, <code>@timestamp</code> is the timestamp of each log event.</p> <p>The response results are sorted by the frequency percentage, starting with the highest percentage.</p>
  ## 
  let valid = call_602360.validator(path, query, header, formData, body)
  let scheme = call_602360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602360.url(scheme.get, call_602360.host, call_602360.base,
                         call_602360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602360, url, valid)

proc call*(call_602361: Call_GetLogGroupFields_602348; body: JsonNode): Recallable =
  ## getLogGroupFields
  ## <p>Returns a list of the fields that are included in log events in the specified log group, along with the percentage of log events that contain each field. The search is limited to a time period that you specify.</p> <p>In the results, fields that start with @ are fields generated by CloudWatch Logs. For example, <code>@timestamp</code> is the timestamp of each log event.</p> <p>The response results are sorted by the frequency percentage, starting with the highest percentage.</p>
  ##   body: JObject (required)
  var body_602362 = newJObject()
  if body != nil:
    body_602362 = body
  result = call_602361.call(nil, nil, nil, nil, body_602362)

var getLogGroupFields* = Call_GetLogGroupFields_602348(name: "getLogGroupFields",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetLogGroupFields",
    validator: validate_GetLogGroupFields_602349, base: "/",
    url: url_GetLogGroupFields_602350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLogRecord_602363 = ref object of OpenApiRestCall_601389
proc url_GetLogRecord_602365(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLogRecord_602364(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602366 = header.getOrDefault("X-Amz-Target")
  valid_602366 = validateParameter(valid_602366, JString, required = true, default = newJString(
      "Logs_20140328.GetLogRecord"))
  if valid_602366 != nil:
    section.add "X-Amz-Target", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Signature")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Signature", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Content-Sha256", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Date")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Date", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Credential")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Credential", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Security-Token")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Security-Token", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Algorithm")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Algorithm", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-SignedHeaders", valid_602373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602375: Call_GetLogRecord_602363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the fields and values of a single log event. All fields are retrieved, even if the original query that produced the <code>logRecordPointer</code> retrieved only a subset of fields. Fields are returned as field name/field value pairs.</p> <p>Additionally, the entire unparsed log event is returned within <code>@message</code>.</p>
  ## 
  let valid = call_602375.validator(path, query, header, formData, body)
  let scheme = call_602375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602375.url(scheme.get, call_602375.host, call_602375.base,
                         call_602375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602375, url, valid)

proc call*(call_602376: Call_GetLogRecord_602363; body: JsonNode): Recallable =
  ## getLogRecord
  ## <p>Retrieves all the fields and values of a single log event. All fields are retrieved, even if the original query that produced the <code>logRecordPointer</code> retrieved only a subset of fields. Fields are returned as field name/field value pairs.</p> <p>Additionally, the entire unparsed log event is returned within <code>@message</code>.</p>
  ##   body: JObject (required)
  var body_602377 = newJObject()
  if body != nil:
    body_602377 = body
  result = call_602376.call(nil, nil, nil, nil, body_602377)

var getLogRecord* = Call_GetLogRecord_602363(name: "getLogRecord",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetLogRecord",
    validator: validate_GetLogRecord_602364, base: "/", url: url_GetLogRecord_602365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryResults_602378 = ref object of OpenApiRestCall_601389
proc url_GetQueryResults_602380(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetQueryResults_602379(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602381 = header.getOrDefault("X-Amz-Target")
  valid_602381 = validateParameter(valid_602381, JString, required = true, default = newJString(
      "Logs_20140328.GetQueryResults"))
  if valid_602381 != nil:
    section.add "X-Amz-Target", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Signature")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Signature", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Content-Sha256", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Date")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Date", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Credential")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Credential", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Security-Token")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Security-Token", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Algorithm")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Algorithm", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-SignedHeaders", valid_602388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602390: Call_GetQueryResults_602378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the results from the specified query.</p> <p>Only the fields requested in the query are returned, along with a <code>@ptr</code> field which is the identifier for the log record. You can use the value of <code>@ptr</code> in a operation to get the full log record.</p> <p> <code>GetQueryResults</code> does not start a query execution. To run a query, use .</p> <p>If the value of the <code>Status</code> field in the output is <code>Running</code>, this operation returns only partial results. If you see a value of <code>Scheduled</code> or <code>Running</code> for the status, you can retry the operation later to see the final results. </p>
  ## 
  let valid = call_602390.validator(path, query, header, formData, body)
  let scheme = call_602390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602390.url(scheme.get, call_602390.host, call_602390.base,
                         call_602390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602390, url, valid)

proc call*(call_602391: Call_GetQueryResults_602378; body: JsonNode): Recallable =
  ## getQueryResults
  ## <p>Returns the results from the specified query.</p> <p>Only the fields requested in the query are returned, along with a <code>@ptr</code> field which is the identifier for the log record. You can use the value of <code>@ptr</code> in a operation to get the full log record.</p> <p> <code>GetQueryResults</code> does not start a query execution. To run a query, use .</p> <p>If the value of the <code>Status</code> field in the output is <code>Running</code>, this operation returns only partial results. If you see a value of <code>Scheduled</code> or <code>Running</code> for the status, you can retry the operation later to see the final results. </p>
  ##   body: JObject (required)
  var body_602392 = newJObject()
  if body != nil:
    body_602392 = body
  result = call_602391.call(nil, nil, nil, nil, body_602392)

var getQueryResults* = Call_GetQueryResults_602378(name: "getQueryResults",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.GetQueryResults",
    validator: validate_GetQueryResults_602379, base: "/", url: url_GetQueryResults_602380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsLogGroup_602393 = ref object of OpenApiRestCall_601389
proc url_ListTagsLogGroup_602395(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsLogGroup_602394(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602396 = header.getOrDefault("X-Amz-Target")
  valid_602396 = validateParameter(valid_602396, JString, required = true, default = newJString(
      "Logs_20140328.ListTagsLogGroup"))
  if valid_602396 != nil:
    section.add "X-Amz-Target", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Signature")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Signature", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Content-Sha256", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Date")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Date", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Credential")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Credential", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Security-Token")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Security-Token", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Algorithm")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Algorithm", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-SignedHeaders", valid_602403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602405: Call_ListTagsLogGroup_602393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified log group.
  ## 
  let valid = call_602405.validator(path, query, header, formData, body)
  let scheme = call_602405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602405.url(scheme.get, call_602405.host, call_602405.base,
                         call_602405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602405, url, valid)

proc call*(call_602406: Call_ListTagsLogGroup_602393; body: JsonNode): Recallable =
  ## listTagsLogGroup
  ## Lists the tags for the specified log group.
  ##   body: JObject (required)
  var body_602407 = newJObject()
  if body != nil:
    body_602407 = body
  result = call_602406.call(nil, nil, nil, nil, body_602407)

var listTagsLogGroup* = Call_ListTagsLogGroup_602393(name: "listTagsLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.ListTagsLogGroup",
    validator: validate_ListTagsLogGroup_602394, base: "/",
    url: url_ListTagsLogGroup_602395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDestination_602408 = ref object of OpenApiRestCall_601389
proc url_PutDestination_602410(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDestination_602409(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates or updates a destination. This operation is used only to create destinations for cross-account subscriptions.</p> <p>A destination encapsulates a physical resource (such as an Amazon Kinesis stream) and enables you to subscribe to a real-time stream of log events for a different account, ingested using <a>PutLogEvents</a>.</p> <p>Through an access policy, a destination controls what is written to it. By default, <code>PutDestination</code> does not set any access policy with the destination, which means a cross-account user cannot call <a>PutSubscriptionFilter</a> against this destination. To enable this, the destination owner must call <a>PutDestinationPolicy</a> after <code>PutDestination</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602411 = header.getOrDefault("X-Amz-Target")
  valid_602411 = validateParameter(valid_602411, JString, required = true, default = newJString(
      "Logs_20140328.PutDestination"))
  if valid_602411 != nil:
    section.add "X-Amz-Target", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Signature")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Signature", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Content-Sha256", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Date")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Date", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Credential")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Credential", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Security-Token")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Security-Token", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Algorithm")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Algorithm", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-SignedHeaders", valid_602418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602420: Call_PutDestination_602408; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a destination. This operation is used only to create destinations for cross-account subscriptions.</p> <p>A destination encapsulates a physical resource (such as an Amazon Kinesis stream) and enables you to subscribe to a real-time stream of log events for a different account, ingested using <a>PutLogEvents</a>.</p> <p>Through an access policy, a destination controls what is written to it. By default, <code>PutDestination</code> does not set any access policy with the destination, which means a cross-account user cannot call <a>PutSubscriptionFilter</a> against this destination. To enable this, the destination owner must call <a>PutDestinationPolicy</a> after <code>PutDestination</code>.</p>
  ## 
  let valid = call_602420.validator(path, query, header, formData, body)
  let scheme = call_602420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602420.url(scheme.get, call_602420.host, call_602420.base,
                         call_602420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602420, url, valid)

proc call*(call_602421: Call_PutDestination_602408; body: JsonNode): Recallable =
  ## putDestination
  ## <p>Creates or updates a destination. This operation is used only to create destinations for cross-account subscriptions.</p> <p>A destination encapsulates a physical resource (such as an Amazon Kinesis stream) and enables you to subscribe to a real-time stream of log events for a different account, ingested using <a>PutLogEvents</a>.</p> <p>Through an access policy, a destination controls what is written to it. By default, <code>PutDestination</code> does not set any access policy with the destination, which means a cross-account user cannot call <a>PutSubscriptionFilter</a> against this destination. To enable this, the destination owner must call <a>PutDestinationPolicy</a> after <code>PutDestination</code>.</p>
  ##   body: JObject (required)
  var body_602422 = newJObject()
  if body != nil:
    body_602422 = body
  result = call_602421.call(nil, nil, nil, nil, body_602422)

var putDestination* = Call_PutDestination_602408(name: "putDestination",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutDestination",
    validator: validate_PutDestination_602409, base: "/", url: url_PutDestination_602410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDestinationPolicy_602423 = ref object of OpenApiRestCall_601389
proc url_PutDestinationPolicy_602425(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDestinationPolicy_602424(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602426 = header.getOrDefault("X-Amz-Target")
  valid_602426 = validateParameter(valid_602426, JString, required = true, default = newJString(
      "Logs_20140328.PutDestinationPolicy"))
  if valid_602426 != nil:
    section.add "X-Amz-Target", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Signature")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Signature", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Content-Sha256", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Date")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Date", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Credential")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Credential", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Security-Token")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Security-Token", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Algorithm")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Algorithm", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-SignedHeaders", valid_602433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602435: Call_PutDestinationPolicy_602423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an access policy associated with an existing destination. An access policy is an <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/policies_overview.html">IAM policy document</a> that is used to authorize claims to register a subscription filter against a given destination.
  ## 
  let valid = call_602435.validator(path, query, header, formData, body)
  let scheme = call_602435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602435.url(scheme.get, call_602435.host, call_602435.base,
                         call_602435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602435, url, valid)

proc call*(call_602436: Call_PutDestinationPolicy_602423; body: JsonNode): Recallable =
  ## putDestinationPolicy
  ## Creates or updates an access policy associated with an existing destination. An access policy is an <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/policies_overview.html">IAM policy document</a> that is used to authorize claims to register a subscription filter against a given destination.
  ##   body: JObject (required)
  var body_602437 = newJObject()
  if body != nil:
    body_602437 = body
  result = call_602436.call(nil, nil, nil, nil, body_602437)

var putDestinationPolicy* = Call_PutDestinationPolicy_602423(
    name: "putDestinationPolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutDestinationPolicy",
    validator: validate_PutDestinationPolicy_602424, base: "/",
    url: url_PutDestinationPolicy_602425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLogEvents_602438 = ref object of OpenApiRestCall_601389
proc url_PutLogEvents_602440(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLogEvents_602439(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602441 = header.getOrDefault("X-Amz-Target")
  valid_602441 = validateParameter(valid_602441, JString, required = true, default = newJString(
      "Logs_20140328.PutLogEvents"))
  if valid_602441 != nil:
    section.add "X-Amz-Target", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Signature")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Signature", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Content-Sha256", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Date")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Date", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Credential")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Credential", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Security-Token")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Security-Token", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Algorithm")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Algorithm", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-SignedHeaders", valid_602448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602450: Call_PutLogEvents_602438; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a batch of log events to the specified log stream.</p> <p>You must include the sequence token obtained from the response of the previous call. An upload in a newly created log stream does not require a sequence token. You can also get the sequence token using <a>DescribeLogStreams</a>. If you call <code>PutLogEvents</code> twice within a narrow time period using the same value for <code>sequenceToken</code>, both calls may be successful, or one may be rejected.</p> <p>The batch of events must satisfy the following constraints:</p> <ul> <li> <p>The maximum batch size is 1,048,576 bytes, and this size is calculated as the sum of all event messages in UTF-8, plus 26 bytes for each log event.</p> </li> <li> <p>None of the log events in the batch can be more than 2 hours in the future.</p> </li> <li> <p>None of the log events in the batch can be older than 14 days or older than the retention period of the log group.</p> </li> <li> <p>The log events in the batch must be in chronological ordered by their timestamp. The timestamp is the time the event occurred, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC. (In AWS Tools for PowerShell and the AWS SDK for .NET, the timestamp is specified in .NET format: yyyy-mm-ddThh:mm:ss. For example, 2017-09-15T13:45:30.) </p> </li> <li> <p>The maximum number of log events in a batch is 10,000.</p> </li> <li> <p>A batch of log events in a single request cannot span more than 24 hours. Otherwise, the operation fails.</p> </li> </ul> <p>If a call to PutLogEvents returns "UnrecognizedClientException" the most likely cause is an invalid AWS access key ID or secret key. </p>
  ## 
  let valid = call_602450.validator(path, query, header, formData, body)
  let scheme = call_602450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602450.url(scheme.get, call_602450.host, call_602450.base,
                         call_602450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602450, url, valid)

proc call*(call_602451: Call_PutLogEvents_602438; body: JsonNode): Recallable =
  ## putLogEvents
  ## <p>Uploads a batch of log events to the specified log stream.</p> <p>You must include the sequence token obtained from the response of the previous call. An upload in a newly created log stream does not require a sequence token. You can also get the sequence token using <a>DescribeLogStreams</a>. If you call <code>PutLogEvents</code> twice within a narrow time period using the same value for <code>sequenceToken</code>, both calls may be successful, or one may be rejected.</p> <p>The batch of events must satisfy the following constraints:</p> <ul> <li> <p>The maximum batch size is 1,048,576 bytes, and this size is calculated as the sum of all event messages in UTF-8, plus 26 bytes for each log event.</p> </li> <li> <p>None of the log events in the batch can be more than 2 hours in the future.</p> </li> <li> <p>None of the log events in the batch can be older than 14 days or older than the retention period of the log group.</p> </li> <li> <p>The log events in the batch must be in chronological ordered by their timestamp. The timestamp is the time the event occurred, expressed as the number of milliseconds after Jan 1, 1970 00:00:00 UTC. (In AWS Tools for PowerShell and the AWS SDK for .NET, the timestamp is specified in .NET format: yyyy-mm-ddThh:mm:ss. For example, 2017-09-15T13:45:30.) </p> </li> <li> <p>The maximum number of log events in a batch is 10,000.</p> </li> <li> <p>A batch of log events in a single request cannot span more than 24 hours. Otherwise, the operation fails.</p> </li> </ul> <p>If a call to PutLogEvents returns "UnrecognizedClientException" the most likely cause is an invalid AWS access key ID or secret key. </p>
  ##   body: JObject (required)
  var body_602452 = newJObject()
  if body != nil:
    body_602452 = body
  result = call_602451.call(nil, nil, nil, nil, body_602452)

var putLogEvents* = Call_PutLogEvents_602438(name: "putLogEvents",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutLogEvents",
    validator: validate_PutLogEvents_602439, base: "/", url: url_PutLogEvents_602440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMetricFilter_602453 = ref object of OpenApiRestCall_601389
proc url_PutMetricFilter_602455(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutMetricFilter_602454(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602456 = header.getOrDefault("X-Amz-Target")
  valid_602456 = validateParameter(valid_602456, JString, required = true, default = newJString(
      "Logs_20140328.PutMetricFilter"))
  if valid_602456 != nil:
    section.add "X-Amz-Target", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Signature")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Signature", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Content-Sha256", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Date")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Date", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Credential")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Credential", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Security-Token")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Security-Token", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Algorithm")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Algorithm", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-SignedHeaders", valid_602463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602465: Call_PutMetricFilter_602453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a metric filter and associates it with the specified log group. Metric filters allow you to configure rules to extract metric data from log events ingested through <a>PutLogEvents</a>.</p> <p>The maximum number of metric filters that can be associated with a log group is 100.</p>
  ## 
  let valid = call_602465.validator(path, query, header, formData, body)
  let scheme = call_602465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602465.url(scheme.get, call_602465.host, call_602465.base,
                         call_602465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602465, url, valid)

proc call*(call_602466: Call_PutMetricFilter_602453; body: JsonNode): Recallable =
  ## putMetricFilter
  ## <p>Creates or updates a metric filter and associates it with the specified log group. Metric filters allow you to configure rules to extract metric data from log events ingested through <a>PutLogEvents</a>.</p> <p>The maximum number of metric filters that can be associated with a log group is 100.</p>
  ##   body: JObject (required)
  var body_602467 = newJObject()
  if body != nil:
    body_602467 = body
  result = call_602466.call(nil, nil, nil, nil, body_602467)

var putMetricFilter* = Call_PutMetricFilter_602453(name: "putMetricFilter",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutMetricFilter",
    validator: validate_PutMetricFilter_602454, base: "/", url: url_PutMetricFilter_602455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_602468 = ref object of OpenApiRestCall_601389
proc url_PutResourcePolicy_602470(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutResourcePolicy_602469(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602471 = header.getOrDefault("X-Amz-Target")
  valid_602471 = validateParameter(valid_602471, JString, required = true, default = newJString(
      "Logs_20140328.PutResourcePolicy"))
  if valid_602471 != nil:
    section.add "X-Amz-Target", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Signature")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Signature", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Content-Sha256", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Date")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Date", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Credential")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Credential", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Security-Token")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Security-Token", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Algorithm")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Algorithm", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-SignedHeaders", valid_602478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602480: Call_PutResourcePolicy_602468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a resource policy allowing other AWS services to put log events to this account, such as Amazon Route 53. An account can have up to 10 resource policies per region.
  ## 
  let valid = call_602480.validator(path, query, header, formData, body)
  let scheme = call_602480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602480.url(scheme.get, call_602480.host, call_602480.base,
                         call_602480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602480, url, valid)

proc call*(call_602481: Call_PutResourcePolicy_602468; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Creates or updates a resource policy allowing other AWS services to put log events to this account, such as Amazon Route 53. An account can have up to 10 resource policies per region.
  ##   body: JObject (required)
  var body_602482 = newJObject()
  if body != nil:
    body_602482 = body
  result = call_602481.call(nil, nil, nil, nil, body_602482)

var putResourcePolicy* = Call_PutResourcePolicy_602468(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutResourcePolicy",
    validator: validate_PutResourcePolicy_602469, base: "/",
    url: url_PutResourcePolicy_602470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRetentionPolicy_602483 = ref object of OpenApiRestCall_601389
proc url_PutRetentionPolicy_602485(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRetentionPolicy_602484(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602486 = header.getOrDefault("X-Amz-Target")
  valid_602486 = validateParameter(valid_602486, JString, required = true, default = newJString(
      "Logs_20140328.PutRetentionPolicy"))
  if valid_602486 != nil:
    section.add "X-Amz-Target", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Signature")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Signature", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Content-Sha256", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Date")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Date", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Credential")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Credential", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Security-Token")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Security-Token", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Algorithm")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Algorithm", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-SignedHeaders", valid_602493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602495: Call_PutRetentionPolicy_602483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the retention of the specified log group. A retention policy allows you to configure the number of days for which to retain log events in the specified log group.
  ## 
  let valid = call_602495.validator(path, query, header, formData, body)
  let scheme = call_602495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602495.url(scheme.get, call_602495.host, call_602495.base,
                         call_602495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602495, url, valid)

proc call*(call_602496: Call_PutRetentionPolicy_602483; body: JsonNode): Recallable =
  ## putRetentionPolicy
  ## Sets the retention of the specified log group. A retention policy allows you to configure the number of days for which to retain log events in the specified log group.
  ##   body: JObject (required)
  var body_602497 = newJObject()
  if body != nil:
    body_602497 = body
  result = call_602496.call(nil, nil, nil, nil, body_602497)

var putRetentionPolicy* = Call_PutRetentionPolicy_602483(
    name: "putRetentionPolicy", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutRetentionPolicy",
    validator: validate_PutRetentionPolicy_602484, base: "/",
    url: url_PutRetentionPolicy_602485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSubscriptionFilter_602498 = ref object of OpenApiRestCall_601389
proc url_PutSubscriptionFilter_602500(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutSubscriptionFilter_602499(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602501 = header.getOrDefault("X-Amz-Target")
  valid_602501 = validateParameter(valid_602501, JString, required = true, default = newJString(
      "Logs_20140328.PutSubscriptionFilter"))
  if valid_602501 != nil:
    section.add "X-Amz-Target", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Signature")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Signature", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Content-Sha256", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Date")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Date", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Credential")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Credential", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Security-Token")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Security-Token", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Algorithm")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Algorithm", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-SignedHeaders", valid_602508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602510: Call_PutSubscriptionFilter_602498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a subscription filter and associates it with the specified log group. Subscription filters allow you to subscribe to a real-time stream of log events ingested through <a>PutLogEvents</a> and have them delivered to a specific destination. Currently, the supported destinations are:</p> <ul> <li> <p>An Amazon Kinesis stream belonging to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>A logical destination that belongs to a different account, for cross-account delivery.</p> </li> <li> <p>An Amazon Kinesis Firehose delivery stream that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>An AWS Lambda function that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> </ul> <p>There can only be one subscription filter associated with a log group. If you are updating an existing filter, you must specify the correct name in <code>filterName</code>. Otherwise, the call fails because you cannot associate a second filter with a log group.</p>
  ## 
  let valid = call_602510.validator(path, query, header, formData, body)
  let scheme = call_602510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602510.url(scheme.get, call_602510.host, call_602510.base,
                         call_602510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602510, url, valid)

proc call*(call_602511: Call_PutSubscriptionFilter_602498; body: JsonNode): Recallable =
  ## putSubscriptionFilter
  ## <p>Creates or updates a subscription filter and associates it with the specified log group. Subscription filters allow you to subscribe to a real-time stream of log events ingested through <a>PutLogEvents</a> and have them delivered to a specific destination. Currently, the supported destinations are:</p> <ul> <li> <p>An Amazon Kinesis stream belonging to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>A logical destination that belongs to a different account, for cross-account delivery.</p> </li> <li> <p>An Amazon Kinesis Firehose delivery stream that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> <li> <p>An AWS Lambda function that belongs to the same account as the subscription filter, for same-account delivery.</p> </li> </ul> <p>There can only be one subscription filter associated with a log group. If you are updating an existing filter, you must specify the correct name in <code>filterName</code>. Otherwise, the call fails because you cannot associate a second filter with a log group.</p>
  ##   body: JObject (required)
  var body_602512 = newJObject()
  if body != nil:
    body_602512 = body
  result = call_602511.call(nil, nil, nil, nil, body_602512)

var putSubscriptionFilter* = Call_PutSubscriptionFilter_602498(
    name: "putSubscriptionFilter", meth: HttpMethod.HttpPost,
    host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.PutSubscriptionFilter",
    validator: validate_PutSubscriptionFilter_602499, base: "/",
    url: url_PutSubscriptionFilter_602500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartQuery_602513 = ref object of OpenApiRestCall_601389
proc url_StartQuery_602515(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartQuery_602514(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602516 = header.getOrDefault("X-Amz-Target")
  valid_602516 = validateParameter(valid_602516, JString, required = true, default = newJString(
      "Logs_20140328.StartQuery"))
  if valid_602516 != nil:
    section.add "X-Amz-Target", valid_602516
  var valid_602517 = header.getOrDefault("X-Amz-Signature")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Signature", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Content-Sha256", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-Date")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Date", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-Credential")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Credential", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Security-Token")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Security-Token", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Algorithm")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Algorithm", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-SignedHeaders", valid_602523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602525: Call_StartQuery_602513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Schedules a query of a log group using CloudWatch Logs Insights. You specify the log group and time range to query, and the query string to use.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html">CloudWatch Logs Insights Query Syntax</a>.</p> <p>Queries time out after 15 minutes of execution. If your queries are timing out, reduce the time range being searched, or partition your query into a number of queries.</p>
  ## 
  let valid = call_602525.validator(path, query, header, formData, body)
  let scheme = call_602525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602525.url(scheme.get, call_602525.host, call_602525.base,
                         call_602525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602525, url, valid)

proc call*(call_602526: Call_StartQuery_602513; body: JsonNode): Recallable =
  ## startQuery
  ## <p>Schedules a query of a log group using CloudWatch Logs Insights. You specify the log group and time range to query, and the query string to use.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html">CloudWatch Logs Insights Query Syntax</a>.</p> <p>Queries time out after 15 minutes of execution. If your queries are timing out, reduce the time range being searched, or partition your query into a number of queries.</p>
  ##   body: JObject (required)
  var body_602527 = newJObject()
  if body != nil:
    body_602527 = body
  result = call_602526.call(nil, nil, nil, nil, body_602527)

var startQuery* = Call_StartQuery_602513(name: "startQuery",
                                      meth: HttpMethod.HttpPost,
                                      host: "logs.amazonaws.com", route: "/#X-Amz-Target=Logs_20140328.StartQuery",
                                      validator: validate_StartQuery_602514,
                                      base: "/", url: url_StartQuery_602515,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopQuery_602528 = ref object of OpenApiRestCall_601389
proc url_StopQuery_602530(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopQuery_602529(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602531 = header.getOrDefault("X-Amz-Target")
  valid_602531 = validateParameter(valid_602531, JString, required = true, default = newJString(
      "Logs_20140328.StopQuery"))
  if valid_602531 != nil:
    section.add "X-Amz-Target", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Signature")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Signature", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Content-Sha256", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Date")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Date", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-Credential")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Credential", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-Security-Token")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Security-Token", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Algorithm")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Algorithm", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-SignedHeaders", valid_602538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602540: Call_StopQuery_602528; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a CloudWatch Logs Insights query that is in progress. If the query has already ended, the operation returns an error indicating that the specified query is not running.
  ## 
  let valid = call_602540.validator(path, query, header, formData, body)
  let scheme = call_602540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602540.url(scheme.get, call_602540.host, call_602540.base,
                         call_602540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602540, url, valid)

proc call*(call_602541: Call_StopQuery_602528; body: JsonNode): Recallable =
  ## stopQuery
  ## Stops a CloudWatch Logs Insights query that is in progress. If the query has already ended, the operation returns an error indicating that the specified query is not running.
  ##   body: JObject (required)
  var body_602542 = newJObject()
  if body != nil:
    body_602542 = body
  result = call_602541.call(nil, nil, nil, nil, body_602542)

var stopQuery* = Call_StopQuery_602528(name: "stopQuery", meth: HttpMethod.HttpPost,
                                    host: "logs.amazonaws.com", route: "/#X-Amz-Target=Logs_20140328.StopQuery",
                                    validator: validate_StopQuery_602529,
                                    base: "/", url: url_StopQuery_602530,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagLogGroup_602543 = ref object of OpenApiRestCall_601389
proc url_TagLogGroup_602545(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagLogGroup_602544(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602546 = header.getOrDefault("X-Amz-Target")
  valid_602546 = validateParameter(valid_602546, JString, required = true, default = newJString(
      "Logs_20140328.TagLogGroup"))
  if valid_602546 != nil:
    section.add "X-Amz-Target", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Signature")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Signature", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Content-Sha256", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Date")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Date", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Credential")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Credential", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Security-Token")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Security-Token", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Algorithm")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Algorithm", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-SignedHeaders", valid_602553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602555: Call_TagLogGroup_602543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or updates the specified tags for the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To remove tags, use <a>UntagLogGroup</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/log-group-tagging.html">Tag Log Groups in Amazon CloudWatch Logs</a> in the <i>Amazon CloudWatch Logs User Guide</i>.</p>
  ## 
  let valid = call_602555.validator(path, query, header, formData, body)
  let scheme = call_602555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602555.url(scheme.get, call_602555.host, call_602555.base,
                         call_602555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602555, url, valid)

proc call*(call_602556: Call_TagLogGroup_602543; body: JsonNode): Recallable =
  ## tagLogGroup
  ## <p>Adds or updates the specified tags for the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To remove tags, use <a>UntagLogGroup</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/log-group-tagging.html">Tag Log Groups in Amazon CloudWatch Logs</a> in the <i>Amazon CloudWatch Logs User Guide</i>.</p>
  ##   body: JObject (required)
  var body_602557 = newJObject()
  if body != nil:
    body_602557 = body
  result = call_602556.call(nil, nil, nil, nil, body_602557)

var tagLogGroup* = Call_TagLogGroup_602543(name: "tagLogGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "logs.amazonaws.com", route: "/#X-Amz-Target=Logs_20140328.TagLogGroup",
                                        validator: validate_TagLogGroup_602544,
                                        base: "/", url: url_TagLogGroup_602545,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestMetricFilter_602558 = ref object of OpenApiRestCall_601389
proc url_TestMetricFilter_602560(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestMetricFilter_602559(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602561 = header.getOrDefault("X-Amz-Target")
  valid_602561 = validateParameter(valid_602561, JString, required = true, default = newJString(
      "Logs_20140328.TestMetricFilter"))
  if valid_602561 != nil:
    section.add "X-Amz-Target", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Signature")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Signature", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Content-Sha256", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Date")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Date", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Credential")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Credential", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Security-Token")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Security-Token", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Algorithm")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Algorithm", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-SignedHeaders", valid_602568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602570: Call_TestMetricFilter_602558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the filter pattern of a metric filter against a sample of log event messages. You can use this operation to validate the correctness of a metric filter pattern.
  ## 
  let valid = call_602570.validator(path, query, header, formData, body)
  let scheme = call_602570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602570.url(scheme.get, call_602570.host, call_602570.base,
                         call_602570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602570, url, valid)

proc call*(call_602571: Call_TestMetricFilter_602558; body: JsonNode): Recallable =
  ## testMetricFilter
  ## Tests the filter pattern of a metric filter against a sample of log event messages. You can use this operation to validate the correctness of a metric filter pattern.
  ##   body: JObject (required)
  var body_602572 = newJObject()
  if body != nil:
    body_602572 = body
  result = call_602571.call(nil, nil, nil, nil, body_602572)

var testMetricFilter* = Call_TestMetricFilter_602558(name: "testMetricFilter",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.TestMetricFilter",
    validator: validate_TestMetricFilter_602559, base: "/",
    url: url_TestMetricFilter_602560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagLogGroup_602573 = ref object of OpenApiRestCall_601389
proc url_UntagLogGroup_602575(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagLogGroup_602574(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602576 = header.getOrDefault("X-Amz-Target")
  valid_602576 = validateParameter(valid_602576, JString, required = true, default = newJString(
      "Logs_20140328.UntagLogGroup"))
  if valid_602576 != nil:
    section.add "X-Amz-Target", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Signature")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Signature", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Content-Sha256", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Date")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Date", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Credential")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Credential", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Security-Token")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Security-Token", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Algorithm")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Algorithm", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-SignedHeaders", valid_602583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602585: Call_UntagLogGroup_602573; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To add tags, use <a>UntagLogGroup</a>.</p>
  ## 
  let valid = call_602585.validator(path, query, header, formData, body)
  let scheme = call_602585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602585.url(scheme.get, call_602585.host, call_602585.base,
                         call_602585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602585, url, valid)

proc call*(call_602586: Call_UntagLogGroup_602573; body: JsonNode): Recallable =
  ## untagLogGroup
  ## <p>Removes the specified tags from the specified log group.</p> <p>To list the tags for a log group, use <a>ListTagsLogGroup</a>. To add tags, use <a>UntagLogGroup</a>.</p>
  ##   body: JObject (required)
  var body_602587 = newJObject()
  if body != nil:
    body_602587 = body
  result = call_602586.call(nil, nil, nil, nil, body_602587)

var untagLogGroup* = Call_UntagLogGroup_602573(name: "untagLogGroup",
    meth: HttpMethod.HttpPost, host: "logs.amazonaws.com",
    route: "/#X-Amz-Target=Logs_20140328.UntagLogGroup",
    validator: validate_UntagLogGroup_602574, base: "/", url: url_UntagLogGroup_602575,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
