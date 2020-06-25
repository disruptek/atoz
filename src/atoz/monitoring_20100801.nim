
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudWatch
## version: 2010-08-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon CloudWatch monitors your Amazon Web Services (AWS) resources and the applications you run on AWS in real time. You can use CloudWatch to collect and track metrics, which are the variables you want to measure for your resources and applications.</p> <p>CloudWatch alarms send notifications or automatically change the resources you are monitoring based on rules that you define. For example, you can monitor the CPU usage and disk reads and writes of your Amazon EC2 instances. Then, use this data to determine whether you should launch additional instances to handle increased load. You can also use this data to stop under-used instances to save money.</p> <p>In addition to monitoring the built-in metrics that come with AWS, you can monitor your own custom metrics. With CloudWatch, you gain system-wide visibility into resource utilization, application performance, and operational health.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/monitoring/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "monitoring.ap-northeast-1.amazonaws.com", "ap-southeast-1": "monitoring.ap-southeast-1.amazonaws.com",
                           "us-west-2": "monitoring.us-west-2.amazonaws.com",
                           "eu-west-2": "monitoring.eu-west-2.amazonaws.com", "ap-northeast-3": "monitoring.ap-northeast-3.amazonaws.com", "eu-central-1": "monitoring.eu-central-1.amazonaws.com",
                           "us-east-2": "monitoring.us-east-2.amazonaws.com",
                           "us-east-1": "monitoring.us-east-1.amazonaws.com", "cn-northwest-1": "monitoring.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "monitoring.ap-south-1.amazonaws.com",
                           "eu-north-1": "monitoring.eu-north-1.amazonaws.com", "ap-northeast-2": "monitoring.ap-northeast-2.amazonaws.com",
                           "us-west-1": "monitoring.us-west-1.amazonaws.com", "us-gov-east-1": "monitoring.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "monitoring.eu-west-3.amazonaws.com", "cn-north-1": "monitoring.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "monitoring.sa-east-1.amazonaws.com",
                           "eu-west-1": "monitoring.eu-west-1.amazonaws.com", "us-gov-west-1": "monitoring.us-gov-west-1.amazonaws.com", "ap-southeast-2": "monitoring.ap-southeast-2.amazonaws.com", "ca-central-1": "monitoring.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "monitoring.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "monitoring.ap-southeast-1.amazonaws.com",
      "us-west-2": "monitoring.us-west-2.amazonaws.com",
      "eu-west-2": "monitoring.eu-west-2.amazonaws.com",
      "ap-northeast-3": "monitoring.ap-northeast-3.amazonaws.com",
      "eu-central-1": "monitoring.eu-central-1.amazonaws.com",
      "us-east-2": "monitoring.us-east-2.amazonaws.com",
      "us-east-1": "monitoring.us-east-1.amazonaws.com",
      "cn-northwest-1": "monitoring.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "monitoring.ap-south-1.amazonaws.com",
      "eu-north-1": "monitoring.eu-north-1.amazonaws.com",
      "ap-northeast-2": "monitoring.ap-northeast-2.amazonaws.com",
      "us-west-1": "monitoring.us-west-1.amazonaws.com",
      "us-gov-east-1": "monitoring.us-gov-east-1.amazonaws.com",
      "eu-west-3": "monitoring.eu-west-3.amazonaws.com",
      "cn-north-1": "monitoring.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "monitoring.sa-east-1.amazonaws.com",
      "eu-west-1": "monitoring.eu-west-1.amazonaws.com",
      "us-gov-west-1": "monitoring.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "monitoring.ap-southeast-2.amazonaws.com",
      "ca-central-1": "monitoring.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "monitoring"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostDeleteAlarms_21626034 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteAlarms_21626036(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAlarms_21626035(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626037 = query.getOrDefault("Action")
  valid_21626037 = validateParameter(valid_21626037, JString, required = true,
                                   default = newJString("DeleteAlarms"))
  if valid_21626037 != nil:
    section.add "Action", valid_21626037
  var valid_21626038 = query.getOrDefault("Version")
  valid_21626038 = validateParameter(valid_21626038, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626038 != nil:
    section.add "Version", valid_21626038
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626039 = header.getOrDefault("X-Amz-Date")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Date", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Security-Token", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Algorithm", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Signature")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Signature", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Credential")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Credential", valid_21626045
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_21626046 = formData.getOrDefault("AlarmNames")
  valid_21626046 = validateParameter(valid_21626046, JArray, required = true,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "AlarmNames", valid_21626046
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626047: Call_PostDeleteAlarms_21626034; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_21626047.validator(path, query, header, formData, body, _)
  let scheme = call_21626047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626047.makeUrl(scheme.get, call_21626047.host, call_21626047.base,
                               call_21626047.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626047, uri, valid, _)

proc call*(call_21626048: Call_PostDeleteAlarms_21626034; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   Action: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Version: string (required)
  var query_21626049 = newJObject()
  var formData_21626050 = newJObject()
  add(query_21626049, "Action", newJString(Action))
  if AlarmNames != nil:
    formData_21626050.add "AlarmNames", AlarmNames
  add(query_21626049, "Version", newJString(Version))
  result = call_21626048.call(nil, query_21626049, nil, formData_21626050, nil)

var postDeleteAlarms* = Call_PostDeleteAlarms_21626034(name: "postDeleteAlarms",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_PostDeleteAlarms_21626035,
    base: "/", makeUrl: url_PostDeleteAlarms_21626036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAlarms_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteAlarms_21625781(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAlarms_21625780(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AlarmNames` field"
  var valid_21625882 = query.getOrDefault("AlarmNames")
  valid_21625882 = validateParameter(valid_21625882, JArray, required = true,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "AlarmNames", valid_21625882
  var valid_21625897 = query.getOrDefault("Action")
  valid_21625897 = validateParameter(valid_21625897, JString, required = true,
                                   default = newJString("DeleteAlarms"))
  if valid_21625897 != nil:
    section.add "Action", valid_21625897
  var valid_21625898 = query.getOrDefault("Version")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21625898 != nil:
    section.add "Version", valid_21625898
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625899 = header.getOrDefault("X-Amz-Date")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Date", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Security-Token", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Algorithm", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Signature")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Signature", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-Credential")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-Credential", valid_21625905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625930: Call_GetDeleteAlarms_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_21625930.validator(path, query, header, formData, body, _)
  let scheme = call_21625930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625930.makeUrl(scheme.get, call_21625930.host, call_21625930.base,
                               call_21625930.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625930, uri, valid, _)

proc call*(call_21625993: Call_GetDeleteAlarms_21625779; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21625995 = newJObject()
  if AlarmNames != nil:
    query_21625995.add "AlarmNames", AlarmNames
  add(query_21625995, "Action", newJString(Action))
  add(query_21625995, "Version", newJString(Version))
  result = call_21625993.call(nil, query_21625995, nil, nil, nil)

var getDeleteAlarms* = Call_GetDeleteAlarms_21625779(name: "getDeleteAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_GetDeleteAlarms_21625780,
    base: "/", makeUrl: url_GetDeleteAlarms_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnomalyDetector_21626070 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteAnomalyDetector_21626072(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAnomalyDetector_21626071(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626073 = query.getOrDefault("Action")
  valid_21626073 = validateParameter(valid_21626073, JString, required = true, default = newJString(
      "DeleteAnomalyDetector"))
  if valid_21626073 != nil:
    section.add "Action", valid_21626073
  var valid_21626074 = query.getOrDefault("Version")
  valid_21626074 = validateParameter(valid_21626074, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626074 != nil:
    section.add "Version", valid_21626074
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626075 = header.getOrDefault("X-Amz-Date")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Date", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Security-Token", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Algorithm", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Signature")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Signature", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Credential")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Credential", valid_21626081
  result.add "header", section
  ## parameters in `formData` object:
  ##   MetricName: JString (required)
  ##             : The metric name associated with the anomaly detection model to delete.
  ##   Dimensions: JArray
  ##             : The metric dimensions associated with the anomaly detection model to delete.
  ##   Stat: JString (required)
  ##       : The statistic associated with the anomaly detection model to delete.
  ##   Namespace: JString (required)
  ##            : The namespace associated with the anomaly detection model to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_21626082 = formData.getOrDefault("MetricName")
  valid_21626082 = validateParameter(valid_21626082, JString, required = true,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "MetricName", valid_21626082
  var valid_21626083 = formData.getOrDefault("Dimensions")
  valid_21626083 = validateParameter(valid_21626083, JArray, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "Dimensions", valid_21626083
  var valid_21626084 = formData.getOrDefault("Stat")
  valid_21626084 = validateParameter(valid_21626084, JString, required = true,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "Stat", valid_21626084
  var valid_21626085 = formData.getOrDefault("Namespace")
  valid_21626085 = validateParameter(valid_21626085, JString, required = true,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "Namespace", valid_21626085
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_PostDeleteAnomalyDetector_21626070;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_PostDeleteAnomalyDetector_21626070;
          MetricName: string; Stat: string; Namespace: string;
          Dimensions: JsonNode = nil; Action: string = "DeleteAnomalyDetector";
          Version: string = "2010-08-01"): Recallable =
  ## postDeleteAnomalyDetector
  ## Deletes the specified anomaly detection model from your account.
  ##   MetricName: string (required)
  ##             : The metric name associated with the anomaly detection model to delete.
  ##   Dimensions: JArray
  ##             : The metric dimensions associated with the anomaly detection model to delete.
  ##   Action: string (required)
  ##   Stat: string (required)
  ##       : The statistic associated with the anomaly detection model to delete.
  ##   Namespace: string (required)
  ##            : The namespace associated with the anomaly detection model to delete.
  ##   Version: string (required)
  var query_21626088 = newJObject()
  var formData_21626089 = newJObject()
  add(formData_21626089, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_21626089.add "Dimensions", Dimensions
  add(query_21626088, "Action", newJString(Action))
  add(formData_21626089, "Stat", newJString(Stat))
  add(formData_21626089, "Namespace", newJString(Namespace))
  add(query_21626088, "Version", newJString(Version))
  result = call_21626087.call(nil, query_21626088, nil, formData_21626089, nil)

var postDeleteAnomalyDetector* = Call_PostDeleteAnomalyDetector_21626070(
    name: "postDeleteAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_PostDeleteAnomalyDetector_21626071, base: "/",
    makeUrl: url_PostDeleteAnomalyDetector_21626072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnomalyDetector_21626051 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteAnomalyDetector_21626053(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAnomalyDetector_21626052(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString (required)
  ##            : The namespace associated with the anomaly detection model to delete.
  ##   Stat: JString (required)
  ##       : The statistic associated with the anomaly detection model to delete.
  ##   Dimensions: JArray
  ##             : The metric dimensions associated with the anomaly detection model to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MetricName: JString (required)
  ##             : The metric name associated with the anomaly detection model to delete.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_21626054 = query.getOrDefault("Namespace")
  valid_21626054 = validateParameter(valid_21626054, JString, required = true,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "Namespace", valid_21626054
  var valid_21626055 = query.getOrDefault("Stat")
  valid_21626055 = validateParameter(valid_21626055, JString, required = true,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "Stat", valid_21626055
  var valid_21626056 = query.getOrDefault("Dimensions")
  valid_21626056 = validateParameter(valid_21626056, JArray, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "Dimensions", valid_21626056
  var valid_21626057 = query.getOrDefault("Action")
  valid_21626057 = validateParameter(valid_21626057, JString, required = true, default = newJString(
      "DeleteAnomalyDetector"))
  if valid_21626057 != nil:
    section.add "Action", valid_21626057
  var valid_21626058 = query.getOrDefault("Version")
  valid_21626058 = validateParameter(valid_21626058, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626058 != nil:
    section.add "Version", valid_21626058
  var valid_21626059 = query.getOrDefault("MetricName")
  valid_21626059 = validateParameter(valid_21626059, JString, required = true,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "MetricName", valid_21626059
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626060 = header.getOrDefault("X-Amz-Date")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Date", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Security-Token", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Algorithm", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Signature")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Signature", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Credential")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Credential", valid_21626066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626067: Call_GetDeleteAnomalyDetector_21626051;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_21626067.validator(path, query, header, formData, body, _)
  let scheme = call_21626067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626067.makeUrl(scheme.get, call_21626067.host, call_21626067.base,
                               call_21626067.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626067, uri, valid, _)

proc call*(call_21626068: Call_GetDeleteAnomalyDetector_21626051;
          Namespace: string; Stat: string; MetricName: string;
          Dimensions: JsonNode = nil; Action: string = "DeleteAnomalyDetector";
          Version: string = "2010-08-01"): Recallable =
  ## getDeleteAnomalyDetector
  ## Deletes the specified anomaly detection model from your account.
  ##   Namespace: string (required)
  ##            : The namespace associated with the anomaly detection model to delete.
  ##   Stat: string (required)
  ##       : The statistic associated with the anomaly detection model to delete.
  ##   Dimensions: JArray
  ##             : The metric dimensions associated with the anomaly detection model to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricName: string (required)
  ##             : The metric name associated with the anomaly detection model to delete.
  var query_21626069 = newJObject()
  add(query_21626069, "Namespace", newJString(Namespace))
  add(query_21626069, "Stat", newJString(Stat))
  if Dimensions != nil:
    query_21626069.add "Dimensions", Dimensions
  add(query_21626069, "Action", newJString(Action))
  add(query_21626069, "Version", newJString(Version))
  add(query_21626069, "MetricName", newJString(MetricName))
  result = call_21626068.call(nil, query_21626069, nil, nil, nil)

var getDeleteAnomalyDetector* = Call_GetDeleteAnomalyDetector_21626051(
    name: "getDeleteAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_GetDeleteAnomalyDetector_21626052, base: "/",
    makeUrl: url_GetDeleteAnomalyDetector_21626053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDashboards_21626106 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteDashboards_21626108(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDashboards_21626107(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626109 = query.getOrDefault("Action")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true,
                                   default = newJString("DeleteDashboards"))
  if valid_21626109 != nil:
    section.add "Action", valid_21626109
  var valid_21626110 = query.getOrDefault("Version")
  valid_21626110 = validateParameter(valid_21626110, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626110 != nil:
    section.add "Version", valid_21626110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626111 = header.getOrDefault("X-Amz-Date")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Date", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Security-Token", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Algorithm", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Signature")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Signature", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Credential")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Credential", valid_21626117
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardNames` field"
  var valid_21626118 = formData.getOrDefault("DashboardNames")
  valid_21626118 = validateParameter(valid_21626118, JArray, required = true,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "DashboardNames", valid_21626118
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626119: Call_PostDeleteDashboards_21626106; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_21626119.validator(path, query, header, formData, body, _)
  let scheme = call_21626119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626119.makeUrl(scheme.get, call_21626119.host, call_21626119.base,
                               call_21626119.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626119, uri, valid, _)

proc call*(call_21626120: Call_PostDeleteDashboards_21626106;
          DashboardNames: JsonNode; Action: string = "DeleteDashboards";
          Version: string = "2010-08-01"): Recallable =
  ## postDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  var query_21626121 = newJObject()
  var formData_21626122 = newJObject()
  add(query_21626121, "Action", newJString(Action))
  add(query_21626121, "Version", newJString(Version))
  if DashboardNames != nil:
    formData_21626122.add "DashboardNames", DashboardNames
  result = call_21626120.call(nil, query_21626121, nil, formData_21626122, nil)

var postDeleteDashboards* = Call_PostDeleteDashboards_21626106(
    name: "postDeleteDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_PostDeleteDashboards_21626107, base: "/",
    makeUrl: url_PostDeleteDashboards_21626108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDashboards_21626090 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteDashboards_21626092(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDashboards_21626091(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626093 = query.getOrDefault("Action")
  valid_21626093 = validateParameter(valid_21626093, JString, required = true,
                                   default = newJString("DeleteDashboards"))
  if valid_21626093 != nil:
    section.add "Action", valid_21626093
  var valid_21626094 = query.getOrDefault("DashboardNames")
  valid_21626094 = validateParameter(valid_21626094, JArray, required = true,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "DashboardNames", valid_21626094
  var valid_21626095 = query.getOrDefault("Version")
  valid_21626095 = validateParameter(valid_21626095, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626095 != nil:
    section.add "Version", valid_21626095
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626096 = header.getOrDefault("X-Amz-Date")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Date", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Security-Token", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Algorithm", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Signature")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Signature", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Credential")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Credential", valid_21626102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626103: Call_GetDeleteDashboards_21626090; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_21626103.validator(path, query, header, formData, body, _)
  let scheme = call_21626103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626103.makeUrl(scheme.get, call_21626103.host, call_21626103.base,
                               call_21626103.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626103, uri, valid, _)

proc call*(call_21626104: Call_GetDeleteDashboards_21626090;
          DashboardNames: JsonNode; Action: string = "DeleteDashboards";
          Version: string = "2010-08-01"): Recallable =
  ## getDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   Action: string (required)
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Version: string (required)
  var query_21626105 = newJObject()
  add(query_21626105, "Action", newJString(Action))
  if DashboardNames != nil:
    query_21626105.add "DashboardNames", DashboardNames
  add(query_21626105, "Version", newJString(Version))
  result = call_21626104.call(nil, query_21626105, nil, nil, nil)

var getDeleteDashboards* = Call_GetDeleteDashboards_21626090(
    name: "getDeleteDashboards", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_GetDeleteDashboards_21626091, base: "/",
    makeUrl: url_GetDeleteDashboards_21626092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteInsightRules_21626139 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteInsightRules_21626141(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteInsightRules_21626140(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626142 = query.getOrDefault("Action")
  valid_21626142 = validateParameter(valid_21626142, JString, required = true,
                                   default = newJString("DeleteInsightRules"))
  if valid_21626142 != nil:
    section.add "Action", valid_21626142
  var valid_21626143 = query.getOrDefault("Version")
  valid_21626143 = validateParameter(valid_21626143, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626143 != nil:
    section.add "Version", valid_21626143
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626144 = header.getOrDefault("X-Amz-Date")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Date", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Security-Token", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Algorithm", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Signature")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Signature", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Credential")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Credential", valid_21626150
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_21626151 = formData.getOrDefault("RuleNames")
  valid_21626151 = validateParameter(valid_21626151, JArray, required = true,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "RuleNames", valid_21626151
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626152: Call_PostDeleteInsightRules_21626139;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_21626152.validator(path, query, header, formData, body, _)
  let scheme = call_21626152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626152.makeUrl(scheme.get, call_21626152.host, call_21626152.base,
                               call_21626152.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626152, uri, valid, _)

proc call*(call_21626153: Call_PostDeleteInsightRules_21626139;
          RuleNames: JsonNode; Action: string = "DeleteInsightRules";
          Version: string = "2010-08-01"): Recallable =
  ## postDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626154 = newJObject()
  var formData_21626155 = newJObject()
  if RuleNames != nil:
    formData_21626155.add "RuleNames", RuleNames
  add(query_21626154, "Action", newJString(Action))
  add(query_21626154, "Version", newJString(Version))
  result = call_21626153.call(nil, query_21626154, nil, formData_21626155, nil)

var postDeleteInsightRules* = Call_PostDeleteInsightRules_21626139(
    name: "postDeleteInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_PostDeleteInsightRules_21626140, base: "/",
    makeUrl: url_PostDeleteInsightRules_21626141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteInsightRules_21626123 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteInsightRules_21626125(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteInsightRules_21626124(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626126 = query.getOrDefault("Action")
  valid_21626126 = validateParameter(valid_21626126, JString, required = true,
                                   default = newJString("DeleteInsightRules"))
  if valid_21626126 != nil:
    section.add "Action", valid_21626126
  var valid_21626127 = query.getOrDefault("RuleNames")
  valid_21626127 = validateParameter(valid_21626127, JArray, required = true,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "RuleNames", valid_21626127
  var valid_21626128 = query.getOrDefault("Version")
  valid_21626128 = validateParameter(valid_21626128, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626128 != nil:
    section.add "Version", valid_21626128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626129 = header.getOrDefault("X-Amz-Date")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Date", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Security-Token", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Algorithm", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Signature")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Signature", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Credential")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Credential", valid_21626135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626136: Call_GetDeleteInsightRules_21626123;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_21626136.validator(path, query, header, formData, body, _)
  let scheme = call_21626136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626136.makeUrl(scheme.get, call_21626136.host, call_21626136.base,
                               call_21626136.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626136, uri, valid, _)

proc call*(call_21626137: Call_GetDeleteInsightRules_21626123; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_21626138 = newJObject()
  add(query_21626138, "Action", newJString(Action))
  if RuleNames != nil:
    query_21626138.add "RuleNames", RuleNames
  add(query_21626138, "Version", newJString(Version))
  result = call_21626137.call(nil, query_21626138, nil, nil, nil)

var getDeleteInsightRules* = Call_GetDeleteInsightRules_21626123(
    name: "getDeleteInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_GetDeleteInsightRules_21626124, base: "/",
    makeUrl: url_GetDeleteInsightRules_21626125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmHistory_21626178 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeAlarmHistory_21626180(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAlarmHistory_21626179(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626181 = query.getOrDefault("Action")
  valid_21626181 = validateParameter(valid_21626181, JString, required = true,
                                   default = newJString("DescribeAlarmHistory"))
  if valid_21626181 != nil:
    section.add "Action", valid_21626181
  var valid_21626182 = query.getOrDefault("Version")
  valid_21626182 = validateParameter(valid_21626182, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626182 != nil:
    section.add "Version", valid_21626182
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626183 = header.getOrDefault("X-Amz-Date")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Date", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Security-Token", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   AlarmName: JString
  ##            : The name of the alarm.
  ##   MaxRecords: JInt
  ##             : The maximum number of alarm history records to retrieve.
  ##   HistoryItemType: JString
  ##                  : The type of alarm histories to retrieve.
  ##   EndDate: JString
  ##          : The ending date to retrieve alarm history.
  ##   StartDate: JString
  ##            : The starting date to retrieve alarm history.
  section = newJObject()
  var valid_21626190 = formData.getOrDefault("NextToken")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "NextToken", valid_21626190
  var valid_21626191 = formData.getOrDefault("AlarmName")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "AlarmName", valid_21626191
  var valid_21626192 = formData.getOrDefault("MaxRecords")
  valid_21626192 = validateParameter(valid_21626192, JInt, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "MaxRecords", valid_21626192
  var valid_21626193 = formData.getOrDefault("HistoryItemType")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = newJString("ConfigurationUpdate"))
  if valid_21626193 != nil:
    section.add "HistoryItemType", valid_21626193
  var valid_21626194 = formData.getOrDefault("EndDate")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "EndDate", valid_21626194
  var valid_21626195 = formData.getOrDefault("StartDate")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "StartDate", valid_21626195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626196: Call_PostDescribeAlarmHistory_21626178;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_21626196.validator(path, query, header, formData, body, _)
  let scheme = call_21626196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626196.makeUrl(scheme.get, call_21626196.host, call_21626196.base,
                               call_21626196.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626196, uri, valid, _)

proc call*(call_21626197: Call_PostDescribeAlarmHistory_21626178;
          NextToken: string = ""; Action: string = "DescribeAlarmHistory";
          AlarmName: string = ""; MaxRecords: int = 0;
          HistoryItemType: string = "ConfigurationUpdate"; EndDate: string = "";
          Version: string = "2010-08-01"; StartDate: string = ""): Recallable =
  ## postDescribeAlarmHistory
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Action: string (required)
  ##   AlarmName: string
  ##            : The name of the alarm.
  ##   MaxRecords: int
  ##             : The maximum number of alarm history records to retrieve.
  ##   HistoryItemType: string
  ##                  : The type of alarm histories to retrieve.
  ##   EndDate: string
  ##          : The ending date to retrieve alarm history.
  ##   Version: string (required)
  ##   StartDate: string
  ##            : The starting date to retrieve alarm history.
  var query_21626198 = newJObject()
  var formData_21626199 = newJObject()
  add(formData_21626199, "NextToken", newJString(NextToken))
  add(query_21626198, "Action", newJString(Action))
  add(formData_21626199, "AlarmName", newJString(AlarmName))
  add(formData_21626199, "MaxRecords", newJInt(MaxRecords))
  add(formData_21626199, "HistoryItemType", newJString(HistoryItemType))
  add(formData_21626199, "EndDate", newJString(EndDate))
  add(query_21626198, "Version", newJString(Version))
  add(formData_21626199, "StartDate", newJString(StartDate))
  result = call_21626197.call(nil, query_21626198, nil, formData_21626199, nil)

var postDescribeAlarmHistory* = Call_PostDescribeAlarmHistory_21626178(
    name: "postDescribeAlarmHistory", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_PostDescribeAlarmHistory_21626179, base: "/",
    makeUrl: url_PostDescribeAlarmHistory_21626180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmHistory_21626156 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeAlarmHistory_21626158(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAlarmHistory_21626157(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : The maximum number of alarm history records to retrieve.
  ##   EndDate: JString
  ##          : The ending date to retrieve alarm history.
  ##   AlarmName: JString
  ##            : The name of the alarm.
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Action: JString (required)
  ##   StartDate: JString
  ##            : The starting date to retrieve alarm history.
  ##   Version: JString (required)
  ##   HistoryItemType: JString
  ##                  : The type of alarm histories to retrieve.
  section = newJObject()
  var valid_21626159 = query.getOrDefault("MaxRecords")
  valid_21626159 = validateParameter(valid_21626159, JInt, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "MaxRecords", valid_21626159
  var valid_21626160 = query.getOrDefault("EndDate")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "EndDate", valid_21626160
  var valid_21626161 = query.getOrDefault("AlarmName")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "AlarmName", valid_21626161
  var valid_21626162 = query.getOrDefault("NextToken")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "NextToken", valid_21626162
  var valid_21626163 = query.getOrDefault("Action")
  valid_21626163 = validateParameter(valid_21626163, JString, required = true,
                                   default = newJString("DescribeAlarmHistory"))
  if valid_21626163 != nil:
    section.add "Action", valid_21626163
  var valid_21626164 = query.getOrDefault("StartDate")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "StartDate", valid_21626164
  var valid_21626165 = query.getOrDefault("Version")
  valid_21626165 = validateParameter(valid_21626165, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626165 != nil:
    section.add "Version", valid_21626165
  var valid_21626166 = query.getOrDefault("HistoryItemType")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = newJString("ConfigurationUpdate"))
  if valid_21626166 != nil:
    section.add "HistoryItemType", valid_21626166
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Algorithm", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Signature")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Signature", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Credential")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Credential", valid_21626173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626174: Call_GetDescribeAlarmHistory_21626156;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_21626174.validator(path, query, header, formData, body, _)
  let scheme = call_21626174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626174.makeUrl(scheme.get, call_21626174.host, call_21626174.base,
                               call_21626174.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626174, uri, valid, _)

proc call*(call_21626175: Call_GetDescribeAlarmHistory_21626156;
          MaxRecords: int = 0; EndDate: string = ""; AlarmName: string = "";
          NextToken: string = ""; Action: string = "DescribeAlarmHistory";
          StartDate: string = ""; Version: string = "2010-08-01";
          HistoryItemType: string = "ConfigurationUpdate"): Recallable =
  ## getDescribeAlarmHistory
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ##   MaxRecords: int
  ##             : The maximum number of alarm history records to retrieve.
  ##   EndDate: string
  ##          : The ending date to retrieve alarm history.
  ##   AlarmName: string
  ##            : The name of the alarm.
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Action: string (required)
  ##   StartDate: string
  ##            : The starting date to retrieve alarm history.
  ##   Version: string (required)
  ##   HistoryItemType: string
  ##                  : The type of alarm histories to retrieve.
  var query_21626176 = newJObject()
  add(query_21626176, "MaxRecords", newJInt(MaxRecords))
  add(query_21626176, "EndDate", newJString(EndDate))
  add(query_21626176, "AlarmName", newJString(AlarmName))
  add(query_21626176, "NextToken", newJString(NextToken))
  add(query_21626176, "Action", newJString(Action))
  add(query_21626176, "StartDate", newJString(StartDate))
  add(query_21626176, "Version", newJString(Version))
  add(query_21626176, "HistoryItemType", newJString(HistoryItemType))
  result = call_21626175.call(nil, query_21626176, nil, nil, nil)

var getDescribeAlarmHistory* = Call_GetDescribeAlarmHistory_21626156(
    name: "getDescribeAlarmHistory", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_GetDescribeAlarmHistory_21626157, base: "/",
    makeUrl: url_GetDescribeAlarmHistory_21626158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarms_21626221 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeAlarms_21626223(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAlarms_21626222(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626224 = query.getOrDefault("Action")
  valid_21626224 = validateParameter(valid_21626224, JString, required = true,
                                   default = newJString("DescribeAlarms"))
  if valid_21626224 != nil:
    section.add "Action", valid_21626224
  var valid_21626225 = query.getOrDefault("Version")
  valid_21626225 = validateParameter(valid_21626225, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626225 != nil:
    section.add "Version", valid_21626225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626226 = header.getOrDefault("X-Amz-Date")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Date", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Security-Token", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Algorithm", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Signature")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Signature", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Credential")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Credential", valid_21626232
  result.add "header", section
  ## parameters in `formData` object:
  ##   ActionPrefix: JString
  ##               : The action name prefix.
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   StateValue: JString
  ##             : The state value to be used in matching alarms.
  ##   AlarmNamePrefix: JString
  ##                  : The alarm name prefix. If this parameter is specified, you cannot specify <code>AlarmNames</code>.
  ##   MaxRecords: JInt
  ##             : The maximum number of alarm descriptions to retrieve.
  ##   AlarmNames: JArray
  ##             : The names of the alarms.
  section = newJObject()
  var valid_21626233 = formData.getOrDefault("ActionPrefix")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "ActionPrefix", valid_21626233
  var valid_21626234 = formData.getOrDefault("NextToken")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "NextToken", valid_21626234
  var valid_21626235 = formData.getOrDefault("StateValue")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = newJString("OK"))
  if valid_21626235 != nil:
    section.add "StateValue", valid_21626235
  var valid_21626236 = formData.getOrDefault("AlarmNamePrefix")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "AlarmNamePrefix", valid_21626236
  var valid_21626237 = formData.getOrDefault("MaxRecords")
  valid_21626237 = validateParameter(valid_21626237, JInt, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "MaxRecords", valid_21626237
  var valid_21626238 = formData.getOrDefault("AlarmNames")
  valid_21626238 = validateParameter(valid_21626238, JArray, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "AlarmNames", valid_21626238
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626239: Call_PostDescribeAlarms_21626221; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_21626239.validator(path, query, header, formData, body, _)
  let scheme = call_21626239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626239.makeUrl(scheme.get, call_21626239.host, call_21626239.base,
                               call_21626239.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626239, uri, valid, _)

proc call*(call_21626240: Call_PostDescribeAlarms_21626221;
          ActionPrefix: string = ""; NextToken: string = ""; StateValue: string = "OK";
          Action: string = "DescribeAlarms"; AlarmNamePrefix: string = "";
          MaxRecords: int = 0; AlarmNames: JsonNode = nil;
          Version: string = "2010-08-01"): Recallable =
  ## postDescribeAlarms
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ##   ActionPrefix: string
  ##               : The action name prefix.
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   StateValue: string
  ##             : The state value to be used in matching alarms.
  ##   Action: string (required)
  ##   AlarmNamePrefix: string
  ##                  : The alarm name prefix. If this parameter is specified, you cannot specify <code>AlarmNames</code>.
  ##   MaxRecords: int
  ##             : The maximum number of alarm descriptions to retrieve.
  ##   AlarmNames: JArray
  ##             : The names of the alarms.
  ##   Version: string (required)
  var query_21626241 = newJObject()
  var formData_21626242 = newJObject()
  add(formData_21626242, "ActionPrefix", newJString(ActionPrefix))
  add(formData_21626242, "NextToken", newJString(NextToken))
  add(formData_21626242, "StateValue", newJString(StateValue))
  add(query_21626241, "Action", newJString(Action))
  add(formData_21626242, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(formData_21626242, "MaxRecords", newJInt(MaxRecords))
  if AlarmNames != nil:
    formData_21626242.add "AlarmNames", AlarmNames
  add(query_21626241, "Version", newJString(Version))
  result = call_21626240.call(nil, query_21626241, nil, formData_21626242, nil)

var postDescribeAlarms* = Call_PostDescribeAlarms_21626221(
    name: "postDescribeAlarms", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarms",
    validator: validate_PostDescribeAlarms_21626222, base: "/",
    makeUrl: url_PostDescribeAlarms_21626223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarms_21626200 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeAlarms_21626202(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAlarms_21626201(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AlarmNamePrefix: JString
  ##                  : The alarm name prefix. If this parameter is specified, you cannot specify <code>AlarmNames</code>.
  ##   MaxRecords: JInt
  ##             : The maximum number of alarm descriptions to retrieve.
  ##   ActionPrefix: JString
  ##               : The action name prefix.
  ##   AlarmNames: JArray
  ##             : The names of the alarms.
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Action: JString (required)
  ##   StateValue: JString
  ##             : The state value to be used in matching alarms.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626203 = query.getOrDefault("AlarmNamePrefix")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "AlarmNamePrefix", valid_21626203
  var valid_21626204 = query.getOrDefault("MaxRecords")
  valid_21626204 = validateParameter(valid_21626204, JInt, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "MaxRecords", valid_21626204
  var valid_21626205 = query.getOrDefault("ActionPrefix")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "ActionPrefix", valid_21626205
  var valid_21626206 = query.getOrDefault("AlarmNames")
  valid_21626206 = validateParameter(valid_21626206, JArray, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "AlarmNames", valid_21626206
  var valid_21626207 = query.getOrDefault("NextToken")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "NextToken", valid_21626207
  var valid_21626208 = query.getOrDefault("Action")
  valid_21626208 = validateParameter(valid_21626208, JString, required = true,
                                   default = newJString("DescribeAlarms"))
  if valid_21626208 != nil:
    section.add "Action", valid_21626208
  var valid_21626209 = query.getOrDefault("StateValue")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = newJString("OK"))
  if valid_21626209 != nil:
    section.add "StateValue", valid_21626209
  var valid_21626210 = query.getOrDefault("Version")
  valid_21626210 = validateParameter(valid_21626210, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626210 != nil:
    section.add "Version", valid_21626210
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626211 = header.getOrDefault("X-Amz-Date")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Date", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Security-Token", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Algorithm", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Signature")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Signature", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Credential")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Credential", valid_21626217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626218: Call_GetDescribeAlarms_21626200; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_21626218.validator(path, query, header, formData, body, _)
  let scheme = call_21626218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626218.makeUrl(scheme.get, call_21626218.host, call_21626218.base,
                               call_21626218.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626218, uri, valid, _)

proc call*(call_21626219: Call_GetDescribeAlarms_21626200;
          AlarmNamePrefix: string = ""; MaxRecords: int = 0; ActionPrefix: string = "";
          AlarmNames: JsonNode = nil; NextToken: string = "";
          Action: string = "DescribeAlarms"; StateValue: string = "OK";
          Version: string = "2010-08-01"): Recallable =
  ## getDescribeAlarms
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ##   AlarmNamePrefix: string
  ##                  : The alarm name prefix. If this parameter is specified, you cannot specify <code>AlarmNames</code>.
  ##   MaxRecords: int
  ##             : The maximum number of alarm descriptions to retrieve.
  ##   ActionPrefix: string
  ##               : The action name prefix.
  ##   AlarmNames: JArray
  ##             : The names of the alarms.
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Action: string (required)
  ##   StateValue: string
  ##             : The state value to be used in matching alarms.
  ##   Version: string (required)
  var query_21626220 = newJObject()
  add(query_21626220, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(query_21626220, "MaxRecords", newJInt(MaxRecords))
  add(query_21626220, "ActionPrefix", newJString(ActionPrefix))
  if AlarmNames != nil:
    query_21626220.add "AlarmNames", AlarmNames
  add(query_21626220, "NextToken", newJString(NextToken))
  add(query_21626220, "Action", newJString(Action))
  add(query_21626220, "StateValue", newJString(StateValue))
  add(query_21626220, "Version", newJString(Version))
  result = call_21626219.call(nil, query_21626220, nil, nil, nil)

var getDescribeAlarms* = Call_GetDescribeAlarms_21626200(name: "getDescribeAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DescribeAlarms", validator: validate_GetDescribeAlarms_21626201,
    base: "/", makeUrl: url_GetDescribeAlarms_21626202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmsForMetric_21626265 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeAlarmsForMetric_21626267(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAlarmsForMetric_21626266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626268 = query.getOrDefault("Action")
  valid_21626268 = validateParameter(valid_21626268, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_21626268 != nil:
    section.add "Action", valid_21626268
  var valid_21626269 = query.getOrDefault("Version")
  valid_21626269 = validateParameter(valid_21626269, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626269 != nil:
    section.add "Version", valid_21626269
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626270 = header.getOrDefault("X-Amz-Date")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Date", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Security-Token", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Algorithm", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Signature")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Signature", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Credential")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Credential", valid_21626276
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExtendedStatistic: JString
  ##                    : The percentile statistic for the metric. Specify a value between p0.0 and p100.
  ##   MetricName: JString (required)
  ##             : The name of the metric.
  ##   Dimensions: JArray
  ##             : The dimensions associated with the metric. If the metric has any associated dimensions, you must specify them in order for the call to succeed.
  ##   Statistic: JString
  ##            : The statistic for the metric, other than percentiles. For percentile statistics, use <code>ExtendedStatistics</code>.
  ##   Namespace: JString (required)
  ##            : The namespace of the metric.
  ##   Unit: JString
  ##       : The unit for the metric.
  ##   Period: JInt
  ##         : The period, in seconds, over which the statistic is applied.
  section = newJObject()
  var valid_21626277 = formData.getOrDefault("ExtendedStatistic")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "ExtendedStatistic", valid_21626277
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_21626278 = formData.getOrDefault("MetricName")
  valid_21626278 = validateParameter(valid_21626278, JString, required = true,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "MetricName", valid_21626278
  var valid_21626279 = formData.getOrDefault("Dimensions")
  valid_21626279 = validateParameter(valid_21626279, JArray, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "Dimensions", valid_21626279
  var valid_21626280 = formData.getOrDefault("Statistic")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = newJString("SampleCount"))
  if valid_21626280 != nil:
    section.add "Statistic", valid_21626280
  var valid_21626281 = formData.getOrDefault("Namespace")
  valid_21626281 = validateParameter(valid_21626281, JString, required = true,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "Namespace", valid_21626281
  var valid_21626282 = formData.getOrDefault("Unit")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = newJString("Seconds"))
  if valid_21626282 != nil:
    section.add "Unit", valid_21626282
  var valid_21626283 = formData.getOrDefault("Period")
  valid_21626283 = validateParameter(valid_21626283, JInt, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "Period", valid_21626283
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626284: Call_PostDescribeAlarmsForMetric_21626265;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_21626284.validator(path, query, header, formData, body, _)
  let scheme = call_21626284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626284.makeUrl(scheme.get, call_21626284.host, call_21626284.base,
                               call_21626284.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626284, uri, valid, _)

proc call*(call_21626285: Call_PostDescribeAlarmsForMetric_21626265;
          MetricName: string; Namespace: string; ExtendedStatistic: string = "";
          Dimensions: JsonNode = nil; Action: string = "DescribeAlarmsForMetric";
          Statistic: string = "SampleCount"; Unit: string = "Seconds";
          Version: string = "2010-08-01"; Period: int = 0): Recallable =
  ## postDescribeAlarmsForMetric
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ##   ExtendedStatistic: string
  ##                    : The percentile statistic for the metric. Specify a value between p0.0 and p100.
  ##   MetricName: string (required)
  ##             : The name of the metric.
  ##   Dimensions: JArray
  ##             : The dimensions associated with the metric. If the metric has any associated dimensions, you must specify them in order for the call to succeed.
  ##   Action: string (required)
  ##   Statistic: string
  ##            : The statistic for the metric, other than percentiles. For percentile statistics, use <code>ExtendedStatistics</code>.
  ##   Namespace: string (required)
  ##            : The namespace of the metric.
  ##   Unit: string
  ##       : The unit for the metric.
  ##   Version: string (required)
  ##   Period: int
  ##         : The period, in seconds, over which the statistic is applied.
  var query_21626286 = newJObject()
  var formData_21626287 = newJObject()
  add(formData_21626287, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(formData_21626287, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_21626287.add "Dimensions", Dimensions
  add(query_21626286, "Action", newJString(Action))
  add(formData_21626287, "Statistic", newJString(Statistic))
  add(formData_21626287, "Namespace", newJString(Namespace))
  add(formData_21626287, "Unit", newJString(Unit))
  add(query_21626286, "Version", newJString(Version))
  add(formData_21626287, "Period", newJInt(Period))
  result = call_21626285.call(nil, query_21626286, nil, formData_21626287, nil)

var postDescribeAlarmsForMetric* = Call_PostDescribeAlarmsForMetric_21626265(
    name: "postDescribeAlarmsForMetric", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_PostDescribeAlarmsForMetric_21626266, base: "/",
    makeUrl: url_PostDescribeAlarmsForMetric_21626267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmsForMetric_21626243 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeAlarmsForMetric_21626245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAlarmsForMetric_21626244(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString (required)
  ##            : The namespace of the metric.
  ##   Unit: JString
  ##       : The unit for the metric.
  ##   ExtendedStatistic: JString
  ##                    : The percentile statistic for the metric. Specify a value between p0.0 and p100.
  ##   Dimensions: JArray
  ##             : The dimensions associated with the metric. If the metric has any associated dimensions, you must specify them in order for the call to succeed.
  ##   Action: JString (required)
  ##   Period: JInt
  ##         : The period, in seconds, over which the statistic is applied.
  ##   MetricName: JString (required)
  ##             : The name of the metric.
  ##   Statistic: JString
  ##            : The statistic for the metric, other than percentiles. For percentile statistics, use <code>ExtendedStatistics</code>.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_21626246 = query.getOrDefault("Namespace")
  valid_21626246 = validateParameter(valid_21626246, JString, required = true,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "Namespace", valid_21626246
  var valid_21626247 = query.getOrDefault("Unit")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = newJString("Seconds"))
  if valid_21626247 != nil:
    section.add "Unit", valid_21626247
  var valid_21626248 = query.getOrDefault("ExtendedStatistic")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "ExtendedStatistic", valid_21626248
  var valid_21626249 = query.getOrDefault("Dimensions")
  valid_21626249 = validateParameter(valid_21626249, JArray, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "Dimensions", valid_21626249
  var valid_21626250 = query.getOrDefault("Action")
  valid_21626250 = validateParameter(valid_21626250, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_21626250 != nil:
    section.add "Action", valid_21626250
  var valid_21626251 = query.getOrDefault("Period")
  valid_21626251 = validateParameter(valid_21626251, JInt, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "Period", valid_21626251
  var valid_21626252 = query.getOrDefault("MetricName")
  valid_21626252 = validateParameter(valid_21626252, JString, required = true,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "MetricName", valid_21626252
  var valid_21626253 = query.getOrDefault("Statistic")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = newJString("SampleCount"))
  if valid_21626253 != nil:
    section.add "Statistic", valid_21626253
  var valid_21626254 = query.getOrDefault("Version")
  valid_21626254 = validateParameter(valid_21626254, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626254 != nil:
    section.add "Version", valid_21626254
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626255 = header.getOrDefault("X-Amz-Date")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Date", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Security-Token", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Algorithm", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Signature")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Signature", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Credential")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Credential", valid_21626261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626262: Call_GetDescribeAlarmsForMetric_21626243;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_21626262.validator(path, query, header, formData, body, _)
  let scheme = call_21626262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626262.makeUrl(scheme.get, call_21626262.host, call_21626262.base,
                               call_21626262.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626262, uri, valid, _)

proc call*(call_21626263: Call_GetDescribeAlarmsForMetric_21626243;
          Namespace: string; MetricName: string; Unit: string = "Seconds";
          ExtendedStatistic: string = ""; Dimensions: JsonNode = nil;
          Action: string = "DescribeAlarmsForMetric"; Period: int = 0;
          Statistic: string = "SampleCount"; Version: string = "2010-08-01"): Recallable =
  ## getDescribeAlarmsForMetric
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ##   Namespace: string (required)
  ##            : The namespace of the metric.
  ##   Unit: string
  ##       : The unit for the metric.
  ##   ExtendedStatistic: string
  ##                    : The percentile statistic for the metric. Specify a value between p0.0 and p100.
  ##   Dimensions: JArray
  ##             : The dimensions associated with the metric. If the metric has any associated dimensions, you must specify them in order for the call to succeed.
  ##   Action: string (required)
  ##   Period: int
  ##         : The period, in seconds, over which the statistic is applied.
  ##   MetricName: string (required)
  ##             : The name of the metric.
  ##   Statistic: string
  ##            : The statistic for the metric, other than percentiles. For percentile statistics, use <code>ExtendedStatistics</code>.
  ##   Version: string (required)
  var query_21626264 = newJObject()
  add(query_21626264, "Namespace", newJString(Namespace))
  add(query_21626264, "Unit", newJString(Unit))
  add(query_21626264, "ExtendedStatistic", newJString(ExtendedStatistic))
  if Dimensions != nil:
    query_21626264.add "Dimensions", Dimensions
  add(query_21626264, "Action", newJString(Action))
  add(query_21626264, "Period", newJInt(Period))
  add(query_21626264, "MetricName", newJString(MetricName))
  add(query_21626264, "Statistic", newJString(Statistic))
  add(query_21626264, "Version", newJString(Version))
  result = call_21626263.call(nil, query_21626264, nil, nil, nil)

var getDescribeAlarmsForMetric* = Call_GetDescribeAlarmsForMetric_21626243(
    name: "getDescribeAlarmsForMetric", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_GetDescribeAlarmsForMetric_21626244, base: "/",
    makeUrl: url_GetDescribeAlarmsForMetric_21626245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnomalyDetectors_21626308 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeAnomalyDetectors_21626310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAnomalyDetectors_21626309(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626311 = query.getOrDefault("Action")
  valid_21626311 = validateParameter(valid_21626311, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_21626311 != nil:
    section.add "Action", valid_21626311
  var valid_21626312 = query.getOrDefault("Version")
  valid_21626312 = validateParameter(valid_21626312, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626312 != nil:
    section.add "Version", valid_21626312
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626313 = header.getOrDefault("X-Amz-Date")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Date", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Security-Token", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Algorithm", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Signature")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Signature", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Credential")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Credential", valid_21626319
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Use the token returned by the previous operation to request the next page of results.
  ##   MaxResults: JInt
  ##             : <p>The maximum number of results to return in one operation. The maximum value you can specify is 10.</p> <p>To retrieve the remaining results, make another call with the returned <code>NextToken</code> value. </p>
  ##   MetricName: JString
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric name. If there are multiple metrics with this name in different namespaces that have anomaly detection models, they're all returned.
  ##   Dimensions: JArray
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric dimensions. If there are multiple metrics that have these dimensions and have anomaly detection models associated, they're all returned.
  ##   Namespace: JString
  ##            : Limits the results to only the anomaly detection models that are associated with the specified namespace.
  section = newJObject()
  var valid_21626320 = formData.getOrDefault("NextToken")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "NextToken", valid_21626320
  var valid_21626321 = formData.getOrDefault("MaxResults")
  valid_21626321 = validateParameter(valid_21626321, JInt, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "MaxResults", valid_21626321
  var valid_21626322 = formData.getOrDefault("MetricName")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "MetricName", valid_21626322
  var valid_21626323 = formData.getOrDefault("Dimensions")
  valid_21626323 = validateParameter(valid_21626323, JArray, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "Dimensions", valid_21626323
  var valid_21626324 = formData.getOrDefault("Namespace")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "Namespace", valid_21626324
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626325: Call_PostDescribeAnomalyDetectors_21626308;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_21626325.validator(path, query, header, formData, body, _)
  let scheme = call_21626325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626325.makeUrl(scheme.get, call_21626325.host, call_21626325.base,
                               call_21626325.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626325, uri, valid, _)

proc call*(call_21626326: Call_PostDescribeAnomalyDetectors_21626308;
          NextToken: string = ""; MaxResults: int = 0; MetricName: string = "";
          Dimensions: JsonNode = nil; Action: string = "DescribeAnomalyDetectors";
          Namespace: string = ""; Version: string = "2010-08-01"): Recallable =
  ## postDescribeAnomalyDetectors
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ##   NextToken: string
  ##            : Use the token returned by the previous operation to request the next page of results.
  ##   MaxResults: int
  ##             : <p>The maximum number of results to return in one operation. The maximum value you can specify is 10.</p> <p>To retrieve the remaining results, make another call with the returned <code>NextToken</code> value. </p>
  ##   MetricName: string
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric name. If there are multiple metrics with this name in different namespaces that have anomaly detection models, they're all returned.
  ##   Dimensions: JArray
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric dimensions. If there are multiple metrics that have these dimensions and have anomaly detection models associated, they're all returned.
  ##   Action: string (required)
  ##   Namespace: string
  ##            : Limits the results to only the anomaly detection models that are associated with the specified namespace.
  ##   Version: string (required)
  var query_21626327 = newJObject()
  var formData_21626328 = newJObject()
  add(formData_21626328, "NextToken", newJString(NextToken))
  add(formData_21626328, "MaxResults", newJInt(MaxResults))
  add(formData_21626328, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_21626328.add "Dimensions", Dimensions
  add(query_21626327, "Action", newJString(Action))
  add(formData_21626328, "Namespace", newJString(Namespace))
  add(query_21626327, "Version", newJString(Version))
  result = call_21626326.call(nil, query_21626327, nil, formData_21626328, nil)

var postDescribeAnomalyDetectors* = Call_PostDescribeAnomalyDetectors_21626308(
    name: "postDescribeAnomalyDetectors", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_PostDescribeAnomalyDetectors_21626309, base: "/",
    makeUrl: url_PostDescribeAnomalyDetectors_21626310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnomalyDetectors_21626288 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeAnomalyDetectors_21626290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAnomalyDetectors_21626289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString
  ##            : Limits the results to only the anomaly detection models that are associated with the specified namespace.
  ##   Dimensions: JArray
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric dimensions. If there are multiple metrics that have these dimensions and have anomaly detection models associated, they're all returned.
  ##   NextToken: JString
  ##            : Use the token returned by the previous operation to request the next page of results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MetricName: JString
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric name. If there are multiple metrics with this name in different namespaces that have anomaly detection models, they're all returned.
  ##   MaxResults: JInt
  ##             : <p>The maximum number of results to return in one operation. The maximum value you can specify is 10.</p> <p>To retrieve the remaining results, make another call with the returned <code>NextToken</code> value. </p>
  section = newJObject()
  var valid_21626291 = query.getOrDefault("Namespace")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "Namespace", valid_21626291
  var valid_21626292 = query.getOrDefault("Dimensions")
  valid_21626292 = validateParameter(valid_21626292, JArray, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "Dimensions", valid_21626292
  var valid_21626293 = query.getOrDefault("NextToken")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "NextToken", valid_21626293
  var valid_21626294 = query.getOrDefault("Action")
  valid_21626294 = validateParameter(valid_21626294, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_21626294 != nil:
    section.add "Action", valid_21626294
  var valid_21626295 = query.getOrDefault("Version")
  valid_21626295 = validateParameter(valid_21626295, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626295 != nil:
    section.add "Version", valid_21626295
  var valid_21626296 = query.getOrDefault("MetricName")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "MetricName", valid_21626296
  var valid_21626297 = query.getOrDefault("MaxResults")
  valid_21626297 = validateParameter(valid_21626297, JInt, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "MaxResults", valid_21626297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626298 = header.getOrDefault("X-Amz-Date")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Date", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Security-Token", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Algorithm", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Signature")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Signature", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Credential")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Credential", valid_21626304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626305: Call_GetDescribeAnomalyDetectors_21626288;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_21626305.validator(path, query, header, formData, body, _)
  let scheme = call_21626305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626305.makeUrl(scheme.get, call_21626305.host, call_21626305.base,
                               call_21626305.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626305, uri, valid, _)

proc call*(call_21626306: Call_GetDescribeAnomalyDetectors_21626288;
          Namespace: string = ""; Dimensions: JsonNode = nil; NextToken: string = "";
          Action: string = "DescribeAnomalyDetectors";
          Version: string = "2010-08-01"; MetricName: string = ""; MaxResults: int = 0): Recallable =
  ## getDescribeAnomalyDetectors
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ##   Namespace: string
  ##            : Limits the results to only the anomaly detection models that are associated with the specified namespace.
  ##   Dimensions: JArray
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric dimensions. If there are multiple metrics that have these dimensions and have anomaly detection models associated, they're all returned.
  ##   NextToken: string
  ##            : Use the token returned by the previous operation to request the next page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricName: string
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric name. If there are multiple metrics with this name in different namespaces that have anomaly detection models, they're all returned.
  ##   MaxResults: int
  ##             : <p>The maximum number of results to return in one operation. The maximum value you can specify is 10.</p> <p>To retrieve the remaining results, make another call with the returned <code>NextToken</code> value. </p>
  var query_21626307 = newJObject()
  add(query_21626307, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_21626307.add "Dimensions", Dimensions
  add(query_21626307, "NextToken", newJString(NextToken))
  add(query_21626307, "Action", newJString(Action))
  add(query_21626307, "Version", newJString(Version))
  add(query_21626307, "MetricName", newJString(MetricName))
  add(query_21626307, "MaxResults", newJInt(MaxResults))
  result = call_21626306.call(nil, query_21626307, nil, nil, nil)

var getDescribeAnomalyDetectors* = Call_GetDescribeAnomalyDetectors_21626288(
    name: "getDescribeAnomalyDetectors", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_GetDescribeAnomalyDetectors_21626289, base: "/",
    makeUrl: url_GetDescribeAnomalyDetectors_21626290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInsightRules_21626346 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeInsightRules_21626348(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeInsightRules_21626347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626349 = query.getOrDefault("Action")
  valid_21626349 = validateParameter(valid_21626349, JString, required = true,
                                   default = newJString("DescribeInsightRules"))
  if valid_21626349 != nil:
    section.add "Action", valid_21626349
  var valid_21626350 = query.getOrDefault("Version")
  valid_21626350 = validateParameter(valid_21626350, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626350 != nil:
    section.add "Version", valid_21626350
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626351 = header.getOrDefault("X-Amz-Date")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Date", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Security-Token", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Algorithm", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Signature")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Signature", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Credential")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Credential", valid_21626357
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Reserved for future use.
  ##   MaxResults: JInt
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  section = newJObject()
  var valid_21626358 = formData.getOrDefault("NextToken")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "NextToken", valid_21626358
  var valid_21626359 = formData.getOrDefault("MaxResults")
  valid_21626359 = validateParameter(valid_21626359, JInt, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "MaxResults", valid_21626359
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626360: Call_PostDescribeInsightRules_21626346;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_21626360.validator(path, query, header, formData, body, _)
  let scheme = call_21626360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626360.makeUrl(scheme.get, call_21626360.host, call_21626360.base,
                               call_21626360.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626360, uri, valid, _)

proc call*(call_21626361: Call_PostDescribeInsightRules_21626346;
          NextToken: string = ""; MaxResults: int = 0;
          Action: string = "DescribeInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDescribeInsightRules
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ##   NextToken: string
  ##            : Reserved for future use.
  ##   MaxResults: int
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626362 = newJObject()
  var formData_21626363 = newJObject()
  add(formData_21626363, "NextToken", newJString(NextToken))
  add(formData_21626363, "MaxResults", newJInt(MaxResults))
  add(query_21626362, "Action", newJString(Action))
  add(query_21626362, "Version", newJString(Version))
  result = call_21626361.call(nil, query_21626362, nil, formData_21626363, nil)

var postDescribeInsightRules* = Call_PostDescribeInsightRules_21626346(
    name: "postDescribeInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_PostDescribeInsightRules_21626347, base: "/",
    makeUrl: url_PostDescribeInsightRules_21626348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInsightRules_21626329 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeInsightRules_21626331(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeInsightRules_21626330(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Reserved for future use.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxResults: JInt
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  section = newJObject()
  var valid_21626332 = query.getOrDefault("NextToken")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "NextToken", valid_21626332
  var valid_21626333 = query.getOrDefault("Action")
  valid_21626333 = validateParameter(valid_21626333, JString, required = true,
                                   default = newJString("DescribeInsightRules"))
  if valid_21626333 != nil:
    section.add "Action", valid_21626333
  var valid_21626334 = query.getOrDefault("Version")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626334 != nil:
    section.add "Version", valid_21626334
  var valid_21626335 = query.getOrDefault("MaxResults")
  valid_21626335 = validateParameter(valid_21626335, JInt, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "MaxResults", valid_21626335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626336 = header.getOrDefault("X-Amz-Date")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Date", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Security-Token", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Algorithm", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Signature")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Signature", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-Credential")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Credential", valid_21626342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626343: Call_GetDescribeInsightRules_21626329;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_21626343.validator(path, query, header, formData, body, _)
  let scheme = call_21626343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626343.makeUrl(scheme.get, call_21626343.host, call_21626343.base,
                               call_21626343.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626343, uri, valid, _)

proc call*(call_21626344: Call_GetDescribeInsightRules_21626329;
          NextToken: string = ""; Action: string = "DescribeInsightRules";
          Version: string = "2010-08-01"; MaxResults: int = 0): Recallable =
  ## getDescribeInsightRules
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ##   NextToken: string
  ##            : Reserved for future use.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxResults: int
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  var query_21626345 = newJObject()
  add(query_21626345, "NextToken", newJString(NextToken))
  add(query_21626345, "Action", newJString(Action))
  add(query_21626345, "Version", newJString(Version))
  add(query_21626345, "MaxResults", newJInt(MaxResults))
  result = call_21626344.call(nil, query_21626345, nil, nil, nil)

var getDescribeInsightRules* = Call_GetDescribeInsightRules_21626329(
    name: "getDescribeInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_GetDescribeInsightRules_21626330, base: "/",
    makeUrl: url_GetDescribeInsightRules_21626331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAlarmActions_21626380 = ref object of OpenApiRestCall_21625435
proc url_PostDisableAlarmActions_21626382(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDisableAlarmActions_21626381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626383 = query.getOrDefault("Action")
  valid_21626383 = validateParameter(valid_21626383, JString, required = true,
                                   default = newJString("DisableAlarmActions"))
  if valid_21626383 != nil:
    section.add "Action", valid_21626383
  var valid_21626384 = query.getOrDefault("Version")
  valid_21626384 = validateParameter(valid_21626384, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626384 != nil:
    section.add "Version", valid_21626384
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626385 = header.getOrDefault("X-Amz-Date")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Date", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Security-Token", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Algorithm", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-Signature")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-Signature", valid_21626389
  var valid_21626390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626390
  var valid_21626391 = header.getOrDefault("X-Amz-Credential")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Credential", valid_21626391
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_21626392 = formData.getOrDefault("AlarmNames")
  valid_21626392 = validateParameter(valid_21626392, JArray, required = true,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "AlarmNames", valid_21626392
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626393: Call_PostDisableAlarmActions_21626380;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_21626393.validator(path, query, header, formData, body, _)
  let scheme = call_21626393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626393.makeUrl(scheme.get, call_21626393.host, call_21626393.base,
                               call_21626393.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626393, uri, valid, _)

proc call*(call_21626394: Call_PostDisableAlarmActions_21626380;
          AlarmNames: JsonNode; Action: string = "DisableAlarmActions";
          Version: string = "2010-08-01"): Recallable =
  ## postDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   Action: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Version: string (required)
  var query_21626395 = newJObject()
  var formData_21626396 = newJObject()
  add(query_21626395, "Action", newJString(Action))
  if AlarmNames != nil:
    formData_21626396.add "AlarmNames", AlarmNames
  add(query_21626395, "Version", newJString(Version))
  result = call_21626394.call(nil, query_21626395, nil, formData_21626396, nil)

var postDisableAlarmActions* = Call_PostDisableAlarmActions_21626380(
    name: "postDisableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_PostDisableAlarmActions_21626381, base: "/",
    makeUrl: url_PostDisableAlarmActions_21626382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAlarmActions_21626364 = ref object of OpenApiRestCall_21625435
proc url_GetDisableAlarmActions_21626366(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisableAlarmActions_21626365(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AlarmNames` field"
  var valid_21626367 = query.getOrDefault("AlarmNames")
  valid_21626367 = validateParameter(valid_21626367, JArray, required = true,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "AlarmNames", valid_21626367
  var valid_21626368 = query.getOrDefault("Action")
  valid_21626368 = validateParameter(valid_21626368, JString, required = true,
                                   default = newJString("DisableAlarmActions"))
  if valid_21626368 != nil:
    section.add "Action", valid_21626368
  var valid_21626369 = query.getOrDefault("Version")
  valid_21626369 = validateParameter(valid_21626369, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626369 != nil:
    section.add "Version", valid_21626369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626370 = header.getOrDefault("X-Amz-Date")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Date", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Security-Token", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Algorithm", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Signature")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Signature", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-Credential")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Credential", valid_21626376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626377: Call_GetDisableAlarmActions_21626364;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_21626377.validator(path, query, header, formData, body, _)
  let scheme = call_21626377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626377.makeUrl(scheme.get, call_21626377.host, call_21626377.base,
                               call_21626377.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626377, uri, valid, _)

proc call*(call_21626378: Call_GetDisableAlarmActions_21626364;
          AlarmNames: JsonNode; Action: string = "DisableAlarmActions";
          Version: string = "2010-08-01"): Recallable =
  ## getDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626379 = newJObject()
  if AlarmNames != nil:
    query_21626379.add "AlarmNames", AlarmNames
  add(query_21626379, "Action", newJString(Action))
  add(query_21626379, "Version", newJString(Version))
  result = call_21626378.call(nil, query_21626379, nil, nil, nil)

var getDisableAlarmActions* = Call_GetDisableAlarmActions_21626364(
    name: "getDisableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_GetDisableAlarmActions_21626365, base: "/",
    makeUrl: url_GetDisableAlarmActions_21626366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableInsightRules_21626413 = ref object of OpenApiRestCall_21625435
proc url_PostDisableInsightRules_21626415(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDisableInsightRules_21626414(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626416 = query.getOrDefault("Action")
  valid_21626416 = validateParameter(valid_21626416, JString, required = true,
                                   default = newJString("DisableInsightRules"))
  if valid_21626416 != nil:
    section.add "Action", valid_21626416
  var valid_21626417 = query.getOrDefault("Version")
  valid_21626417 = validateParameter(valid_21626417, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626417 != nil:
    section.add "Version", valid_21626417
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626418 = header.getOrDefault("X-Amz-Date")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Date", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Security-Token", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Algorithm", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Signature")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Signature", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Credential")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Credential", valid_21626424
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_21626425 = formData.getOrDefault("RuleNames")
  valid_21626425 = validateParameter(valid_21626425, JArray, required = true,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "RuleNames", valid_21626425
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626426: Call_PostDisableInsightRules_21626413;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_21626426.validator(path, query, header, formData, body, _)
  let scheme = call_21626426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626426.makeUrl(scheme.get, call_21626426.host, call_21626426.base,
                               call_21626426.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626426, uri, valid, _)

proc call*(call_21626427: Call_PostDisableInsightRules_21626413;
          RuleNames: JsonNode; Action: string = "DisableInsightRules";
          Version: string = "2010-08-01"): Recallable =
  ## postDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626428 = newJObject()
  var formData_21626429 = newJObject()
  if RuleNames != nil:
    formData_21626429.add "RuleNames", RuleNames
  add(query_21626428, "Action", newJString(Action))
  add(query_21626428, "Version", newJString(Version))
  result = call_21626427.call(nil, query_21626428, nil, formData_21626429, nil)

var postDisableInsightRules* = Call_PostDisableInsightRules_21626413(
    name: "postDisableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_PostDisableInsightRules_21626414, base: "/",
    makeUrl: url_PostDisableInsightRules_21626415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableInsightRules_21626397 = ref object of OpenApiRestCall_21625435
proc url_GetDisableInsightRules_21626399(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisableInsightRules_21626398(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626400 = query.getOrDefault("Action")
  valid_21626400 = validateParameter(valid_21626400, JString, required = true,
                                   default = newJString("DisableInsightRules"))
  if valid_21626400 != nil:
    section.add "Action", valid_21626400
  var valid_21626401 = query.getOrDefault("RuleNames")
  valid_21626401 = validateParameter(valid_21626401, JArray, required = true,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "RuleNames", valid_21626401
  var valid_21626402 = query.getOrDefault("Version")
  valid_21626402 = validateParameter(valid_21626402, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626402 != nil:
    section.add "Version", valid_21626402
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626403 = header.getOrDefault("X-Amz-Date")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Date", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Security-Token", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Algorithm", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Signature")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Signature", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Credential")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Credential", valid_21626409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626410: Call_GetDisableInsightRules_21626397;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_21626410.validator(path, query, header, formData, body, _)
  let scheme = call_21626410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626410.makeUrl(scheme.get, call_21626410.host, call_21626410.base,
                               call_21626410.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626410, uri, valid, _)

proc call*(call_21626411: Call_GetDisableInsightRules_21626397;
          RuleNames: JsonNode; Action: string = "DisableInsightRules";
          Version: string = "2010-08-01"): Recallable =
  ## getDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_21626412 = newJObject()
  add(query_21626412, "Action", newJString(Action))
  if RuleNames != nil:
    query_21626412.add "RuleNames", RuleNames
  add(query_21626412, "Version", newJString(Version))
  result = call_21626411.call(nil, query_21626412, nil, nil, nil)

var getDisableInsightRules* = Call_GetDisableInsightRules_21626397(
    name: "getDisableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_GetDisableInsightRules_21626398, base: "/",
    makeUrl: url_GetDisableInsightRules_21626399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAlarmActions_21626446 = ref object of OpenApiRestCall_21625435
proc url_PostEnableAlarmActions_21626448(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostEnableAlarmActions_21626447(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the actions for the specified alarms.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626449 = query.getOrDefault("Action")
  valid_21626449 = validateParameter(valid_21626449, JString, required = true,
                                   default = newJString("EnableAlarmActions"))
  if valid_21626449 != nil:
    section.add "Action", valid_21626449
  var valid_21626450 = query.getOrDefault("Version")
  valid_21626450 = validateParameter(valid_21626450, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626450 != nil:
    section.add "Version", valid_21626450
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626451 = header.getOrDefault("X-Amz-Date")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Date", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Security-Token", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Algorithm", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Signature")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Signature", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Credential")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Credential", valid_21626457
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_21626458 = formData.getOrDefault("AlarmNames")
  valid_21626458 = validateParameter(valid_21626458, JArray, required = true,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "AlarmNames", valid_21626458
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626459: Call_PostEnableAlarmActions_21626446;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_21626459.validator(path, query, header, formData, body, _)
  let scheme = call_21626459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626459.makeUrl(scheme.get, call_21626459.host, call_21626459.base,
                               call_21626459.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626459, uri, valid, _)

proc call*(call_21626460: Call_PostEnableAlarmActions_21626446;
          AlarmNames: JsonNode; Action: string = "EnableAlarmActions";
          Version: string = "2010-08-01"): Recallable =
  ## postEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   Action: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Version: string (required)
  var query_21626461 = newJObject()
  var formData_21626462 = newJObject()
  add(query_21626461, "Action", newJString(Action))
  if AlarmNames != nil:
    formData_21626462.add "AlarmNames", AlarmNames
  add(query_21626461, "Version", newJString(Version))
  result = call_21626460.call(nil, query_21626461, nil, formData_21626462, nil)

var postEnableAlarmActions* = Call_PostEnableAlarmActions_21626446(
    name: "postEnableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_PostEnableAlarmActions_21626447, base: "/",
    makeUrl: url_PostEnableAlarmActions_21626448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAlarmActions_21626430 = ref object of OpenApiRestCall_21625435
proc url_GetEnableAlarmActions_21626432(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnableAlarmActions_21626431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the actions for the specified alarms.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AlarmNames` field"
  var valid_21626433 = query.getOrDefault("AlarmNames")
  valid_21626433 = validateParameter(valid_21626433, JArray, required = true,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "AlarmNames", valid_21626433
  var valid_21626434 = query.getOrDefault("Action")
  valid_21626434 = validateParameter(valid_21626434, JString, required = true,
                                   default = newJString("EnableAlarmActions"))
  if valid_21626434 != nil:
    section.add "Action", valid_21626434
  var valid_21626435 = query.getOrDefault("Version")
  valid_21626435 = validateParameter(valid_21626435, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626435 != nil:
    section.add "Version", valid_21626435
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626436 = header.getOrDefault("X-Amz-Date")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Date", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Security-Token", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Algorithm", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Signature")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Signature", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Credential")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Credential", valid_21626442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626443: Call_GetEnableAlarmActions_21626430;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_21626443.validator(path, query, header, formData, body, _)
  let scheme = call_21626443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626443.makeUrl(scheme.get, call_21626443.host, call_21626443.base,
                               call_21626443.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626443, uri, valid, _)

proc call*(call_21626444: Call_GetEnableAlarmActions_21626430;
          AlarmNames: JsonNode; Action: string = "EnableAlarmActions";
          Version: string = "2010-08-01"): Recallable =
  ## getEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626445 = newJObject()
  if AlarmNames != nil:
    query_21626445.add "AlarmNames", AlarmNames
  add(query_21626445, "Action", newJString(Action))
  add(query_21626445, "Version", newJString(Version))
  result = call_21626444.call(nil, query_21626445, nil, nil, nil)

var getEnableAlarmActions* = Call_GetEnableAlarmActions_21626430(
    name: "getEnableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_GetEnableAlarmActions_21626431, base: "/",
    makeUrl: url_GetEnableAlarmActions_21626432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableInsightRules_21626479 = ref object of OpenApiRestCall_21625435
proc url_PostEnableInsightRules_21626481(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostEnableInsightRules_21626480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626482 = query.getOrDefault("Action")
  valid_21626482 = validateParameter(valid_21626482, JString, required = true,
                                   default = newJString("EnableInsightRules"))
  if valid_21626482 != nil:
    section.add "Action", valid_21626482
  var valid_21626483 = query.getOrDefault("Version")
  valid_21626483 = validateParameter(valid_21626483, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626483 != nil:
    section.add "Version", valid_21626483
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626484 = header.getOrDefault("X-Amz-Date")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Date", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Security-Token", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Algorithm", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Signature")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Signature", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Credential")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Credential", valid_21626490
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_21626491 = formData.getOrDefault("RuleNames")
  valid_21626491 = validateParameter(valid_21626491, JArray, required = true,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "RuleNames", valid_21626491
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626492: Call_PostEnableInsightRules_21626479;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_21626492.validator(path, query, header, formData, body, _)
  let scheme = call_21626492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626492.makeUrl(scheme.get, call_21626492.host, call_21626492.base,
                               call_21626492.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626492, uri, valid, _)

proc call*(call_21626493: Call_PostEnableInsightRules_21626479;
          RuleNames: JsonNode; Action: string = "EnableInsightRules";
          Version: string = "2010-08-01"): Recallable =
  ## postEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626494 = newJObject()
  var formData_21626495 = newJObject()
  if RuleNames != nil:
    formData_21626495.add "RuleNames", RuleNames
  add(query_21626494, "Action", newJString(Action))
  add(query_21626494, "Version", newJString(Version))
  result = call_21626493.call(nil, query_21626494, nil, formData_21626495, nil)

var postEnableInsightRules* = Call_PostEnableInsightRules_21626479(
    name: "postEnableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_PostEnableInsightRules_21626480, base: "/",
    makeUrl: url_PostEnableInsightRules_21626481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableInsightRules_21626463 = ref object of OpenApiRestCall_21625435
proc url_GetEnableInsightRules_21626465(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnableInsightRules_21626464(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626466 = query.getOrDefault("Action")
  valid_21626466 = validateParameter(valid_21626466, JString, required = true,
                                   default = newJString("EnableInsightRules"))
  if valid_21626466 != nil:
    section.add "Action", valid_21626466
  var valid_21626467 = query.getOrDefault("RuleNames")
  valid_21626467 = validateParameter(valid_21626467, JArray, required = true,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "RuleNames", valid_21626467
  var valid_21626468 = query.getOrDefault("Version")
  valid_21626468 = validateParameter(valid_21626468, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626468 != nil:
    section.add "Version", valid_21626468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626469 = header.getOrDefault("X-Amz-Date")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Date", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Security-Token", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Algorithm", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Signature")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Signature", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Credential")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Credential", valid_21626475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626476: Call_GetEnableInsightRules_21626463;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_21626476.validator(path, query, header, formData, body, _)
  let scheme = call_21626476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626476.makeUrl(scheme.get, call_21626476.host, call_21626476.base,
                               call_21626476.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626476, uri, valid, _)

proc call*(call_21626477: Call_GetEnableInsightRules_21626463; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_21626478 = newJObject()
  add(query_21626478, "Action", newJString(Action))
  if RuleNames != nil:
    query_21626478.add "RuleNames", RuleNames
  add(query_21626478, "Version", newJString(Version))
  result = call_21626477.call(nil, query_21626478, nil, nil, nil)

var getEnableInsightRules* = Call_GetEnableInsightRules_21626463(
    name: "getEnableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_GetEnableInsightRules_21626464, base: "/",
    makeUrl: url_GetEnableInsightRules_21626465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetDashboard_21626512 = ref object of OpenApiRestCall_21625435
proc url_PostGetDashboard_21626514(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetDashboard_21626513(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626515 = query.getOrDefault("Action")
  valid_21626515 = validateParameter(valid_21626515, JString, required = true,
                                   default = newJString("GetDashboard"))
  if valid_21626515 != nil:
    section.add "Action", valid_21626515
  var valid_21626516 = query.getOrDefault("Version")
  valid_21626516 = validateParameter(valid_21626516, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626516 != nil:
    section.add "Version", valid_21626516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626517 = header.getOrDefault("X-Amz-Date")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Date", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Security-Token", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-Algorithm", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-Signature")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-Signature", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-Credential")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Credential", valid_21626523
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_21626524 = formData.getOrDefault("DashboardName")
  valid_21626524 = validateParameter(valid_21626524, JString, required = true,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "DashboardName", valid_21626524
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626525: Call_PostGetDashboard_21626512; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_21626525.validator(path, query, header, formData, body, _)
  let scheme = call_21626525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626525.makeUrl(scheme.get, call_21626525.host, call_21626525.base,
                               call_21626525.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626525, uri, valid, _)

proc call*(call_21626526: Call_PostGetDashboard_21626512; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## postGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Version: string (required)
  var query_21626527 = newJObject()
  var formData_21626528 = newJObject()
  add(query_21626527, "Action", newJString(Action))
  add(formData_21626528, "DashboardName", newJString(DashboardName))
  add(query_21626527, "Version", newJString(Version))
  result = call_21626526.call(nil, query_21626527, nil, formData_21626528, nil)

var postGetDashboard* = Call_PostGetDashboard_21626512(name: "postGetDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_PostGetDashboard_21626513,
    base: "/", makeUrl: url_PostGetDashboard_21626514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetDashboard_21626496 = ref object of OpenApiRestCall_21625435
proc url_GetGetDashboard_21626498(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetDashboard_21626497(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DashboardName` field"
  var valid_21626499 = query.getOrDefault("DashboardName")
  valid_21626499 = validateParameter(valid_21626499, JString, required = true,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "DashboardName", valid_21626499
  var valid_21626500 = query.getOrDefault("Action")
  valid_21626500 = validateParameter(valid_21626500, JString, required = true,
                                   default = newJString("GetDashboard"))
  if valid_21626500 != nil:
    section.add "Action", valid_21626500
  var valid_21626501 = query.getOrDefault("Version")
  valid_21626501 = validateParameter(valid_21626501, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626501 != nil:
    section.add "Version", valid_21626501
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626502 = header.getOrDefault("X-Amz-Date")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Date", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Security-Token", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Algorithm", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Signature")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Signature", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Credential")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Credential", valid_21626508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626509: Call_GetGetDashboard_21626496; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_21626509.validator(path, query, header, formData, body, _)
  let scheme = call_21626509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626509.makeUrl(scheme.get, call_21626509.host, call_21626509.base,
                               call_21626509.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626509, uri, valid, _)

proc call*(call_21626510: Call_GetGetDashboard_21626496; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## getGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626511 = newJObject()
  add(query_21626511, "DashboardName", newJString(DashboardName))
  add(query_21626511, "Action", newJString(Action))
  add(query_21626511, "Version", newJString(Version))
  result = call_21626510.call(nil, query_21626511, nil, nil, nil)

var getGetDashboard* = Call_GetGetDashboard_21626496(name: "getGetDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_GetGetDashboard_21626497,
    base: "/", makeUrl: url_GetGetDashboard_21626498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetInsightRuleReport_21626551 = ref object of OpenApiRestCall_21625435
proc url_PostGetInsightRuleReport_21626553(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetInsightRuleReport_21626552(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626554 = query.getOrDefault("Action")
  valid_21626554 = validateParameter(valid_21626554, JString, required = true,
                                   default = newJString("GetInsightRuleReport"))
  if valid_21626554 != nil:
    section.add "Action", valid_21626554
  var valid_21626555 = query.getOrDefault("Version")
  valid_21626555 = validateParameter(valid_21626555, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626555 != nil:
    section.add "Version", valid_21626555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626556 = header.getOrDefault("X-Amz-Date")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Date", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Security-Token", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Algorithm", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Signature")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Signature", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Credential")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Credential", valid_21626562
  result.add "header", section
  ## parameters in `formData` object:
  ##   Metrics: JArray
  ##          : <p>Specifies which metrics to use for aggregation of contributor values for the report. You can specify one or more of the following metrics:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ##   MaxContributorCount: JInt
  ##                      : The maximum number of contributors to include in the report. The range is 1 to 100. If you omit this, the default of 10 is used.
  ##   RuleName: JString (required)
  ##           : The name of the rule that you want to see data from.
  ##   StartTime: JString (required)
  ##            : The start time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   OrderBy: JString
  ##          : Determines what statistic to use to rank the contributors. Valid values are SUM and MAXIMUM.
  ##   EndTime: JString (required)
  ##          : The end time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   Period: JInt (required)
  ##         : The period, in seconds, to use for the statistics in the <code>InsightRuleMetricDatapoint</code> results.
  section = newJObject()
  var valid_21626563 = formData.getOrDefault("Metrics")
  valid_21626563 = validateParameter(valid_21626563, JArray, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "Metrics", valid_21626563
  var valid_21626564 = formData.getOrDefault("MaxContributorCount")
  valid_21626564 = validateParameter(valid_21626564, JInt, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "MaxContributorCount", valid_21626564
  assert formData != nil,
        "formData argument is necessary due to required `RuleName` field"
  var valid_21626565 = formData.getOrDefault("RuleName")
  valid_21626565 = validateParameter(valid_21626565, JString, required = true,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "RuleName", valid_21626565
  var valid_21626566 = formData.getOrDefault("StartTime")
  valid_21626566 = validateParameter(valid_21626566, JString, required = true,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "StartTime", valid_21626566
  var valid_21626567 = formData.getOrDefault("OrderBy")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "OrderBy", valid_21626567
  var valid_21626568 = formData.getOrDefault("EndTime")
  valid_21626568 = validateParameter(valid_21626568, JString, required = true,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "EndTime", valid_21626568
  var valid_21626569 = formData.getOrDefault("Period")
  valid_21626569 = validateParameter(valid_21626569, JInt, required = true,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "Period", valid_21626569
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626570: Call_PostGetInsightRuleReport_21626551;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_21626570.validator(path, query, header, formData, body, _)
  let scheme = call_21626570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626570.makeUrl(scheme.get, call_21626570.host, call_21626570.base,
                               call_21626570.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626570, uri, valid, _)

proc call*(call_21626571: Call_PostGetInsightRuleReport_21626551; RuleName: string;
          StartTime: string; EndTime: string; Period: int; Metrics: JsonNode = nil;
          MaxContributorCount: int = 0; Action: string = "GetInsightRuleReport";
          OrderBy: string = ""; Version: string = "2010-08-01"): Recallable =
  ## postGetInsightRuleReport
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ##   Metrics: JArray
  ##          : <p>Specifies which metrics to use for aggregation of contributor values for the report. You can specify one or more of the following metrics:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ##   MaxContributorCount: int
  ##                      : The maximum number of contributors to include in the report. The range is 1 to 100. If you omit this, the default of 10 is used.
  ##   RuleName: string (required)
  ##           : The name of the rule that you want to see data from.
  ##   StartTime: string (required)
  ##            : The start time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   Action: string (required)
  ##   OrderBy: string
  ##          : Determines what statistic to use to rank the contributors. Valid values are SUM and MAXIMUM.
  ##   EndTime: string (required)
  ##          : The end time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   Version: string (required)
  ##   Period: int (required)
  ##         : The period, in seconds, to use for the statistics in the <code>InsightRuleMetricDatapoint</code> results.
  var query_21626572 = newJObject()
  var formData_21626573 = newJObject()
  if Metrics != nil:
    formData_21626573.add "Metrics", Metrics
  add(formData_21626573, "MaxContributorCount", newJInt(MaxContributorCount))
  add(formData_21626573, "RuleName", newJString(RuleName))
  add(formData_21626573, "StartTime", newJString(StartTime))
  add(query_21626572, "Action", newJString(Action))
  add(formData_21626573, "OrderBy", newJString(OrderBy))
  add(formData_21626573, "EndTime", newJString(EndTime))
  add(query_21626572, "Version", newJString(Version))
  add(formData_21626573, "Period", newJInt(Period))
  result = call_21626571.call(nil, query_21626572, nil, formData_21626573, nil)

var postGetInsightRuleReport* = Call_PostGetInsightRuleReport_21626551(
    name: "postGetInsightRuleReport", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_PostGetInsightRuleReport_21626552, base: "/",
    makeUrl: url_PostGetInsightRuleReport_21626553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetInsightRuleReport_21626529 = ref object of OpenApiRestCall_21625435
proc url_GetGetInsightRuleReport_21626531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetInsightRuleReport_21626530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RuleName: JString (required)
  ##           : The name of the rule that you want to see data from.
  ##   StartTime: JString (required)
  ##            : The start time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   Action: JString (required)
  ##   Metrics: JArray
  ##          : <p>Specifies which metrics to use for aggregation of contributor values for the report. You can specify one or more of the following metrics:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ##   OrderBy: JString
  ##          : Determines what statistic to use to rank the contributors. Valid values are SUM and MAXIMUM.
  ##   EndTime: JString (required)
  ##          : The end time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   Period: JInt (required)
  ##         : The period, in seconds, to use for the statistics in the <code>InsightRuleMetricDatapoint</code> results.
  ##   MaxContributorCount: JInt
  ##                      : The maximum number of contributors to include in the report. The range is 1 to 100. If you omit this, the default of 10 is used.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `RuleName` field"
  var valid_21626532 = query.getOrDefault("RuleName")
  valid_21626532 = validateParameter(valid_21626532, JString, required = true,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "RuleName", valid_21626532
  var valid_21626533 = query.getOrDefault("StartTime")
  valid_21626533 = validateParameter(valid_21626533, JString, required = true,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "StartTime", valid_21626533
  var valid_21626534 = query.getOrDefault("Action")
  valid_21626534 = validateParameter(valid_21626534, JString, required = true,
                                   default = newJString("GetInsightRuleReport"))
  if valid_21626534 != nil:
    section.add "Action", valid_21626534
  var valid_21626535 = query.getOrDefault("Metrics")
  valid_21626535 = validateParameter(valid_21626535, JArray, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "Metrics", valid_21626535
  var valid_21626536 = query.getOrDefault("OrderBy")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "OrderBy", valid_21626536
  var valid_21626537 = query.getOrDefault("EndTime")
  valid_21626537 = validateParameter(valid_21626537, JString, required = true,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "EndTime", valid_21626537
  var valid_21626538 = query.getOrDefault("Period")
  valid_21626538 = validateParameter(valid_21626538, JInt, required = true,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "Period", valid_21626538
  var valid_21626539 = query.getOrDefault("MaxContributorCount")
  valid_21626539 = validateParameter(valid_21626539, JInt, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "MaxContributorCount", valid_21626539
  var valid_21626540 = query.getOrDefault("Version")
  valid_21626540 = validateParameter(valid_21626540, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626540 != nil:
    section.add "Version", valid_21626540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626541 = header.getOrDefault("X-Amz-Date")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Date", valid_21626541
  var valid_21626542 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Security-Token", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Algorithm", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Signature")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Signature", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Credential")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Credential", valid_21626547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626548: Call_GetGetInsightRuleReport_21626529;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_21626548.validator(path, query, header, formData, body, _)
  let scheme = call_21626548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626548.makeUrl(scheme.get, call_21626548.host, call_21626548.base,
                               call_21626548.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626548, uri, valid, _)

proc call*(call_21626549: Call_GetGetInsightRuleReport_21626529; RuleName: string;
          StartTime: string; EndTime: string; Period: int;
          Action: string = "GetInsightRuleReport"; Metrics: JsonNode = nil;
          OrderBy: string = ""; MaxContributorCount: int = 0;
          Version: string = "2010-08-01"): Recallable =
  ## getGetInsightRuleReport
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ##   RuleName: string (required)
  ##           : The name of the rule that you want to see data from.
  ##   StartTime: string (required)
  ##            : The start time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   Action: string (required)
  ##   Metrics: JArray
  ##          : <p>Specifies which metrics to use for aggregation of contributor values for the report. You can specify one or more of the following metrics:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ##   OrderBy: string
  ##          : Determines what statistic to use to rank the contributors. Valid values are SUM and MAXIMUM.
  ##   EndTime: string (required)
  ##          : The end time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   Period: int (required)
  ##         : The period, in seconds, to use for the statistics in the <code>InsightRuleMetricDatapoint</code> results.
  ##   MaxContributorCount: int
  ##                      : The maximum number of contributors to include in the report. The range is 1 to 100. If you omit this, the default of 10 is used.
  ##   Version: string (required)
  var query_21626550 = newJObject()
  add(query_21626550, "RuleName", newJString(RuleName))
  add(query_21626550, "StartTime", newJString(StartTime))
  add(query_21626550, "Action", newJString(Action))
  if Metrics != nil:
    query_21626550.add "Metrics", Metrics
  add(query_21626550, "OrderBy", newJString(OrderBy))
  add(query_21626550, "EndTime", newJString(EndTime))
  add(query_21626550, "Period", newJInt(Period))
  add(query_21626550, "MaxContributorCount", newJInt(MaxContributorCount))
  add(query_21626550, "Version", newJString(Version))
  result = call_21626549.call(nil, query_21626550, nil, nil, nil)

var getGetInsightRuleReport* = Call_GetGetInsightRuleReport_21626529(
    name: "getGetInsightRuleReport", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_GetGetInsightRuleReport_21626530, base: "/",
    makeUrl: url_GetGetInsightRuleReport_21626531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricData_21626595 = ref object of OpenApiRestCall_21625435
proc url_PostGetMetricData_21626597(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetMetricData_21626596(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626598 = query.getOrDefault("Action")
  valid_21626598 = validateParameter(valid_21626598, JString, required = true,
                                   default = newJString("GetMetricData"))
  if valid_21626598 != nil:
    section.add "Action", valid_21626598
  var valid_21626599 = query.getOrDefault("Version")
  valid_21626599 = validateParameter(valid_21626599, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626599 != nil:
    section.add "Version", valid_21626599
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626600 = header.getOrDefault("X-Amz-Date")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Date", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Security-Token", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Algorithm", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Signature")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Signature", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-Credential")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-Credential", valid_21626606
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Include this value, if it was returned by the previous call, to get the next set of data points.
  ##   ScanBy: JString
  ##         : The order in which data points should be returned. <code>TimestampDescending</code> returns the newest data first and paginates when the <code>MaxDatapoints</code> limit is reached. <code>TimestampAscending</code> returns the oldest data first and paginates when the <code>MaxDatapoints</code> limit is reached.
  ##   StartTime: JString (required)
  ##            : <p>The time stamp indicating the earliest data to be returned.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. </p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>StartTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>StartTime</code>.</p>
  ##   EndTime: JString (required)
  ##          : <p>The time stamp indicating the latest data to be returned.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp.</p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>EndTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>EndTime</code>.</p>
  ##   MetricDataQueries: JArray (required)
  ##                    : The metric queries to be returned. A single <code>GetMetricData</code> call can include as many as 100 <code>MetricDataQuery</code> structures. Each of these structures can specify either a metric to retrieve, or a math expression to perform on retrieved data. 
  ##   MaxDatapoints: JInt
  ##                : The maximum number of data points the request should return before paginating. If you omit this, the default of 100,800 is used.
  section = newJObject()
  var valid_21626607 = formData.getOrDefault("NextToken")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "NextToken", valid_21626607
  var valid_21626608 = formData.getOrDefault("ScanBy")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = newJString("TimestampDescending"))
  if valid_21626608 != nil:
    section.add "ScanBy", valid_21626608
  assert formData != nil,
        "formData argument is necessary due to required `StartTime` field"
  var valid_21626609 = formData.getOrDefault("StartTime")
  valid_21626609 = validateParameter(valid_21626609, JString, required = true,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "StartTime", valid_21626609
  var valid_21626610 = formData.getOrDefault("EndTime")
  valid_21626610 = validateParameter(valid_21626610, JString, required = true,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "EndTime", valid_21626610
  var valid_21626611 = formData.getOrDefault("MetricDataQueries")
  valid_21626611 = validateParameter(valid_21626611, JArray, required = true,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "MetricDataQueries", valid_21626611
  var valid_21626612 = formData.getOrDefault("MaxDatapoints")
  valid_21626612 = validateParameter(valid_21626612, JInt, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "MaxDatapoints", valid_21626612
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626613: Call_PostGetMetricData_21626595; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_21626613.validator(path, query, header, formData, body, _)
  let scheme = call_21626613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626613.makeUrl(scheme.get, call_21626613.host, call_21626613.base,
                               call_21626613.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626613, uri, valid, _)

proc call*(call_21626614: Call_PostGetMetricData_21626595; StartTime: string;
          EndTime: string; MetricDataQueries: JsonNode; NextToken: string = "";
          ScanBy: string = "TimestampDescending"; Action: string = "GetMetricData";
          MaxDatapoints: int = 0; Version: string = "2010-08-01"): Recallable =
  ## postGetMetricData
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ##   NextToken: string
  ##            : Include this value, if it was returned by the previous call, to get the next set of data points.
  ##   ScanBy: string
  ##         : The order in which data points should be returned. <code>TimestampDescending</code> returns the newest data first and paginates when the <code>MaxDatapoints</code> limit is reached. <code>TimestampAscending</code> returns the oldest data first and paginates when the <code>MaxDatapoints</code> limit is reached.
  ##   StartTime: string (required)
  ##            : <p>The time stamp indicating the earliest data to be returned.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. </p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>StartTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>StartTime</code>.</p>
  ##   Action: string (required)
  ##   EndTime: string (required)
  ##          : <p>The time stamp indicating the latest data to be returned.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp.</p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>EndTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>EndTime</code>.</p>
  ##   MetricDataQueries: JArray (required)
  ##                    : The metric queries to be returned. A single <code>GetMetricData</code> call can include as many as 100 <code>MetricDataQuery</code> structures. Each of these structures can specify either a metric to retrieve, or a math expression to perform on retrieved data. 
  ##   MaxDatapoints: int
  ##                : The maximum number of data points the request should return before paginating. If you omit this, the default of 100,800 is used.
  ##   Version: string (required)
  var query_21626615 = newJObject()
  var formData_21626616 = newJObject()
  add(formData_21626616, "NextToken", newJString(NextToken))
  add(formData_21626616, "ScanBy", newJString(ScanBy))
  add(formData_21626616, "StartTime", newJString(StartTime))
  add(query_21626615, "Action", newJString(Action))
  add(formData_21626616, "EndTime", newJString(EndTime))
  if MetricDataQueries != nil:
    formData_21626616.add "MetricDataQueries", MetricDataQueries
  add(formData_21626616, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_21626615, "Version", newJString(Version))
  result = call_21626614.call(nil, query_21626615, nil, formData_21626616, nil)

var postGetMetricData* = Call_PostGetMetricData_21626595(name: "postGetMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_PostGetMetricData_21626596,
    base: "/", makeUrl: url_PostGetMetricData_21626597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricData_21626574 = ref object of OpenApiRestCall_21625435
proc url_GetGetMetricData_21626576(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetMetricData_21626575(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxDatapoints: JInt
  ##                : The maximum number of data points the request should return before paginating. If you omit this, the default of 100,800 is used.
  ##   ScanBy: JString
  ##         : The order in which data points should be returned. <code>TimestampDescending</code> returns the newest data first and paginates when the <code>MaxDatapoints</code> limit is reached. <code>TimestampAscending</code> returns the oldest data first and paginates when the <code>MaxDatapoints</code> limit is reached.
  ##   StartTime: JString (required)
  ##            : <p>The time stamp indicating the earliest data to be returned.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. </p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>StartTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>StartTime</code>.</p>
  ##   NextToken: JString
  ##            : Include this value, if it was returned by the previous call, to get the next set of data points.
  ##   Action: JString (required)
  ##   MetricDataQueries: JArray (required)
  ##                    : The metric queries to be returned. A single <code>GetMetricData</code> call can include as many as 100 <code>MetricDataQuery</code> structures. Each of these structures can specify either a metric to retrieve, or a math expression to perform on retrieved data. 
  ##   EndTime: JString (required)
  ##          : <p>The time stamp indicating the latest data to be returned.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp.</p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>EndTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>EndTime</code>.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626577 = query.getOrDefault("MaxDatapoints")
  valid_21626577 = validateParameter(valid_21626577, JInt, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "MaxDatapoints", valid_21626577
  var valid_21626578 = query.getOrDefault("ScanBy")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = newJString("TimestampDescending"))
  if valid_21626578 != nil:
    section.add "ScanBy", valid_21626578
  assert query != nil,
        "query argument is necessary due to required `StartTime` field"
  var valid_21626579 = query.getOrDefault("StartTime")
  valid_21626579 = validateParameter(valid_21626579, JString, required = true,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "StartTime", valid_21626579
  var valid_21626580 = query.getOrDefault("NextToken")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "NextToken", valid_21626580
  var valid_21626581 = query.getOrDefault("Action")
  valid_21626581 = validateParameter(valid_21626581, JString, required = true,
                                   default = newJString("GetMetricData"))
  if valid_21626581 != nil:
    section.add "Action", valid_21626581
  var valid_21626582 = query.getOrDefault("MetricDataQueries")
  valid_21626582 = validateParameter(valid_21626582, JArray, required = true,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "MetricDataQueries", valid_21626582
  var valid_21626583 = query.getOrDefault("EndTime")
  valid_21626583 = validateParameter(valid_21626583, JString, required = true,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "EndTime", valid_21626583
  var valid_21626584 = query.getOrDefault("Version")
  valid_21626584 = validateParameter(valid_21626584, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626584 != nil:
    section.add "Version", valid_21626584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626585 = header.getOrDefault("X-Amz-Date")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Date", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Security-Token", valid_21626586
  var valid_21626587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Algorithm", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Signature")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-Signature", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Credential")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Credential", valid_21626591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626592: Call_GetGetMetricData_21626574; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_21626592.validator(path, query, header, formData, body, _)
  let scheme = call_21626592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626592.makeUrl(scheme.get, call_21626592.host, call_21626592.base,
                               call_21626592.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626592, uri, valid, _)

proc call*(call_21626593: Call_GetGetMetricData_21626574; StartTime: string;
          MetricDataQueries: JsonNode; EndTime: string; MaxDatapoints: int = 0;
          ScanBy: string = "TimestampDescending"; NextToken: string = "";
          Action: string = "GetMetricData"; Version: string = "2010-08-01"): Recallable =
  ## getGetMetricData
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ##   MaxDatapoints: int
  ##                : The maximum number of data points the request should return before paginating. If you omit this, the default of 100,800 is used.
  ##   ScanBy: string
  ##         : The order in which data points should be returned. <code>TimestampDescending</code> returns the newest data first and paginates when the <code>MaxDatapoints</code> limit is reached. <code>TimestampAscending</code> returns the oldest data first and paginates when the <code>MaxDatapoints</code> limit is reached.
  ##   StartTime: string (required)
  ##            : <p>The time stamp indicating the earliest data to be returned.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. </p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>StartTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>StartTime</code>.</p>
  ##   NextToken: string
  ##            : Include this value, if it was returned by the previous call, to get the next set of data points.
  ##   Action: string (required)
  ##   MetricDataQueries: JArray (required)
  ##                    : The metric queries to be returned. A single <code>GetMetricData</code> call can include as many as 100 <code>MetricDataQuery</code> structures. Each of these structures can specify either a metric to retrieve, or a math expression to perform on retrieved data. 
  ##   EndTime: string (required)
  ##          : <p>The time stamp indicating the latest data to be returned.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp.</p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>EndTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>EndTime</code>.</p>
  ##   Version: string (required)
  var query_21626594 = newJObject()
  add(query_21626594, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_21626594, "ScanBy", newJString(ScanBy))
  add(query_21626594, "StartTime", newJString(StartTime))
  add(query_21626594, "NextToken", newJString(NextToken))
  add(query_21626594, "Action", newJString(Action))
  if MetricDataQueries != nil:
    query_21626594.add "MetricDataQueries", MetricDataQueries
  add(query_21626594, "EndTime", newJString(EndTime))
  add(query_21626594, "Version", newJString(Version))
  result = call_21626593.call(nil, query_21626594, nil, nil, nil)

var getGetMetricData* = Call_GetGetMetricData_21626574(name: "getGetMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_GetGetMetricData_21626575,
    base: "/", makeUrl: url_GetGetMetricData_21626576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricStatistics_21626641 = ref object of OpenApiRestCall_21625435
proc url_PostGetMetricStatistics_21626643(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetMetricStatistics_21626642(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626644 = query.getOrDefault("Action")
  valid_21626644 = validateParameter(valid_21626644, JString, required = true,
                                   default = newJString("GetMetricStatistics"))
  if valid_21626644 != nil:
    section.add "Action", valid_21626644
  var valid_21626645 = query.getOrDefault("Version")
  valid_21626645 = validateParameter(valid_21626645, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626645 != nil:
    section.add "Version", valid_21626645
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626646 = header.getOrDefault("X-Amz-Date")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Date", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Security-Token", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Algorithm", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Signature")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Signature", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Credential")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Credential", valid_21626652
  result.add "header", section
  ## parameters in `formData` object:
  ##   Statistics: JArray
  ##             : The metric statistics, other than percentile. For percentile statistics, use <code>ExtendedStatistics</code>. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both.
  ##   MetricName: JString (required)
  ##             : The name of the metric, with or without spaces.
  ##   Dimensions: JArray
  ##             : The dimensions. If the metric contains multiple dimensions, you must include a value for each dimension. CloudWatch treats each unique combination of dimensions as a separate metric. If a specific combination of dimensions was not published, you can't retrieve statistics for it. You must specify the same dimensions that were used when the metrics were created. For an example, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#dimension-combinations">Dimension Combinations</a> in the <i>Amazon CloudWatch User Guide</i>. For more information about specifying dimensions, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   StartTime: JString (required)
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   Namespace: JString (required)
  ##            : The namespace of the metric, with or without spaces.
  ##   ExtendedStatistics: JArray
  ##                     : The percentile statistics. Specify values between p0.0 and p100. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both. Percentile statistics are not available for metrics when any of the metric values are negative numbers.
  ##   EndTime: JString (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Unit: JString
  ##       : The unit for a given metric. If you omit <code>Unit</code>, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.
  ##   Period: JInt (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  section = newJObject()
  var valid_21626653 = formData.getOrDefault("Statistics")
  valid_21626653 = validateParameter(valid_21626653, JArray, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "Statistics", valid_21626653
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_21626654 = formData.getOrDefault("MetricName")
  valid_21626654 = validateParameter(valid_21626654, JString, required = true,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "MetricName", valid_21626654
  var valid_21626655 = formData.getOrDefault("Dimensions")
  valid_21626655 = validateParameter(valid_21626655, JArray, required = false,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "Dimensions", valid_21626655
  var valid_21626656 = formData.getOrDefault("StartTime")
  valid_21626656 = validateParameter(valid_21626656, JString, required = true,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "StartTime", valid_21626656
  var valid_21626657 = formData.getOrDefault("Namespace")
  valid_21626657 = validateParameter(valid_21626657, JString, required = true,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "Namespace", valid_21626657
  var valid_21626658 = formData.getOrDefault("ExtendedStatistics")
  valid_21626658 = validateParameter(valid_21626658, JArray, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "ExtendedStatistics", valid_21626658
  var valid_21626659 = formData.getOrDefault("EndTime")
  valid_21626659 = validateParameter(valid_21626659, JString, required = true,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "EndTime", valid_21626659
  var valid_21626660 = formData.getOrDefault("Unit")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = newJString("Seconds"))
  if valid_21626660 != nil:
    section.add "Unit", valid_21626660
  var valid_21626661 = formData.getOrDefault("Period")
  valid_21626661 = validateParameter(valid_21626661, JInt, required = true,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "Period", valid_21626661
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626662: Call_PostGetMetricStatistics_21626641;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_21626662.validator(path, query, header, formData, body, _)
  let scheme = call_21626662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626662.makeUrl(scheme.get, call_21626662.host, call_21626662.base,
                               call_21626662.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626662, uri, valid, _)

proc call*(call_21626663: Call_PostGetMetricStatistics_21626641;
          MetricName: string; StartTime: string; Namespace: string; EndTime: string;
          Period: int; Statistics: JsonNode = nil; Dimensions: JsonNode = nil;
          Action: string = "GetMetricStatistics";
          ExtendedStatistics: JsonNode = nil; Unit: string = "Seconds";
          Version: string = "2010-08-01"): Recallable =
  ## postGetMetricStatistics
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ##   Statistics: JArray
  ##             : The metric statistics, other than percentile. For percentile statistics, use <code>ExtendedStatistics</code>. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both.
  ##   MetricName: string (required)
  ##             : The name of the metric, with or without spaces.
  ##   Dimensions: JArray
  ##             : The dimensions. If the metric contains multiple dimensions, you must include a value for each dimension. CloudWatch treats each unique combination of dimensions as a separate metric. If a specific combination of dimensions was not published, you can't retrieve statistics for it. You must specify the same dimensions that were used when the metrics were created. For an example, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#dimension-combinations">Dimension Combinations</a> in the <i>Amazon CloudWatch User Guide</i>. For more information about specifying dimensions, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   StartTime: string (required)
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   Action: string (required)
  ##   Namespace: string (required)
  ##            : The namespace of the metric, with or without spaces.
  ##   ExtendedStatistics: JArray
  ##                     : The percentile statistics. Specify values between p0.0 and p100. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both. Percentile statistics are not available for metrics when any of the metric values are negative numbers.
  ##   EndTime: string (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Unit: string
  ##       : The unit for a given metric. If you omit <code>Unit</code>, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.
  ##   Version: string (required)
  ##   Period: int (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  var query_21626664 = newJObject()
  var formData_21626665 = newJObject()
  if Statistics != nil:
    formData_21626665.add "Statistics", Statistics
  add(formData_21626665, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_21626665.add "Dimensions", Dimensions
  add(formData_21626665, "StartTime", newJString(StartTime))
  add(query_21626664, "Action", newJString(Action))
  add(formData_21626665, "Namespace", newJString(Namespace))
  if ExtendedStatistics != nil:
    formData_21626665.add "ExtendedStatistics", ExtendedStatistics
  add(formData_21626665, "EndTime", newJString(EndTime))
  add(formData_21626665, "Unit", newJString(Unit))
  add(query_21626664, "Version", newJString(Version))
  add(formData_21626665, "Period", newJInt(Period))
  result = call_21626663.call(nil, query_21626664, nil, formData_21626665, nil)

var postGetMetricStatistics* = Call_PostGetMetricStatistics_21626641(
    name: "postGetMetricStatistics", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_PostGetMetricStatistics_21626642, base: "/",
    makeUrl: url_PostGetMetricStatistics_21626643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricStatistics_21626617 = ref object of OpenApiRestCall_21625435
proc url_GetGetMetricStatistics_21626619(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetMetricStatistics_21626618(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString (required)
  ##            : The namespace of the metric, with or without spaces.
  ##   Unit: JString
  ##       : The unit for a given metric. If you omit <code>Unit</code>, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.
  ##   StartTime: JString (required)
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   Dimensions: JArray
  ##             : The dimensions. If the metric contains multiple dimensions, you must include a value for each dimension. CloudWatch treats each unique combination of dimensions as a separate metric. If a specific combination of dimensions was not published, you can't retrieve statistics for it. You must specify the same dimensions that were used when the metrics were created. For an example, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#dimension-combinations">Dimension Combinations</a> in the <i>Amazon CloudWatch User Guide</i>. For more information about specifying dimensions, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   Action: JString (required)
  ##   ExtendedStatistics: JArray
  ##                     : The percentile statistics. Specify values between p0.0 and p100. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both. Percentile statistics are not available for metrics when any of the metric values are negative numbers.
  ##   Statistics: JArray
  ##             : The metric statistics, other than percentile. For percentile statistics, use <code>ExtendedStatistics</code>. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both.
  ##   EndTime: JString (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Period: JInt (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  ##   MetricName: JString (required)
  ##             : The name of the metric, with or without spaces.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_21626620 = query.getOrDefault("Namespace")
  valid_21626620 = validateParameter(valid_21626620, JString, required = true,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "Namespace", valid_21626620
  var valid_21626621 = query.getOrDefault("Unit")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = newJString("Seconds"))
  if valid_21626621 != nil:
    section.add "Unit", valid_21626621
  var valid_21626622 = query.getOrDefault("StartTime")
  valid_21626622 = validateParameter(valid_21626622, JString, required = true,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "StartTime", valid_21626622
  var valid_21626623 = query.getOrDefault("Dimensions")
  valid_21626623 = validateParameter(valid_21626623, JArray, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "Dimensions", valid_21626623
  var valid_21626624 = query.getOrDefault("Action")
  valid_21626624 = validateParameter(valid_21626624, JString, required = true,
                                   default = newJString("GetMetricStatistics"))
  if valid_21626624 != nil:
    section.add "Action", valid_21626624
  var valid_21626625 = query.getOrDefault("ExtendedStatistics")
  valid_21626625 = validateParameter(valid_21626625, JArray, required = false,
                                   default = nil)
  if valid_21626625 != nil:
    section.add "ExtendedStatistics", valid_21626625
  var valid_21626626 = query.getOrDefault("Statistics")
  valid_21626626 = validateParameter(valid_21626626, JArray, required = false,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "Statistics", valid_21626626
  var valid_21626627 = query.getOrDefault("EndTime")
  valid_21626627 = validateParameter(valid_21626627, JString, required = true,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "EndTime", valid_21626627
  var valid_21626628 = query.getOrDefault("Period")
  valid_21626628 = validateParameter(valid_21626628, JInt, required = true,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "Period", valid_21626628
  var valid_21626629 = query.getOrDefault("MetricName")
  valid_21626629 = validateParameter(valid_21626629, JString, required = true,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "MetricName", valid_21626629
  var valid_21626630 = query.getOrDefault("Version")
  valid_21626630 = validateParameter(valid_21626630, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626630 != nil:
    section.add "Version", valid_21626630
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626631 = header.getOrDefault("X-Amz-Date")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Date", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Security-Token", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Algorithm", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Signature")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Signature", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Credential")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Credential", valid_21626637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626638: Call_GetGetMetricStatistics_21626617;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_21626638.validator(path, query, header, formData, body, _)
  let scheme = call_21626638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626638.makeUrl(scheme.get, call_21626638.host, call_21626638.base,
                               call_21626638.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626638, uri, valid, _)

proc call*(call_21626639: Call_GetGetMetricStatistics_21626617; Namespace: string;
          StartTime: string; EndTime: string; Period: int; MetricName: string;
          Unit: string = "Seconds"; Dimensions: JsonNode = nil;
          Action: string = "GetMetricStatistics";
          ExtendedStatistics: JsonNode = nil; Statistics: JsonNode = nil;
          Version: string = "2010-08-01"): Recallable =
  ## getGetMetricStatistics
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ##   Namespace: string (required)
  ##            : The namespace of the metric, with or without spaces.
  ##   Unit: string
  ##       : The unit for a given metric. If you omit <code>Unit</code>, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.
  ##   StartTime: string (required)
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   Dimensions: JArray
  ##             : The dimensions. If the metric contains multiple dimensions, you must include a value for each dimension. CloudWatch treats each unique combination of dimensions as a separate metric. If a specific combination of dimensions was not published, you can't retrieve statistics for it. You must specify the same dimensions that were used when the metrics were created. For an example, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#dimension-combinations">Dimension Combinations</a> in the <i>Amazon CloudWatch User Guide</i>. For more information about specifying dimensions, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   Action: string (required)
  ##   ExtendedStatistics: JArray
  ##                     : The percentile statistics. Specify values between p0.0 and p100. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both. Percentile statistics are not available for metrics when any of the metric values are negative numbers.
  ##   Statistics: JArray
  ##             : The metric statistics, other than percentile. For percentile statistics, use <code>ExtendedStatistics</code>. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both.
  ##   EndTime: string (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Period: int (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  ##   MetricName: string (required)
  ##             : The name of the metric, with or without spaces.
  ##   Version: string (required)
  var query_21626640 = newJObject()
  add(query_21626640, "Namespace", newJString(Namespace))
  add(query_21626640, "Unit", newJString(Unit))
  add(query_21626640, "StartTime", newJString(StartTime))
  if Dimensions != nil:
    query_21626640.add "Dimensions", Dimensions
  add(query_21626640, "Action", newJString(Action))
  if ExtendedStatistics != nil:
    query_21626640.add "ExtendedStatistics", ExtendedStatistics
  if Statistics != nil:
    query_21626640.add "Statistics", Statistics
  add(query_21626640, "EndTime", newJString(EndTime))
  add(query_21626640, "Period", newJInt(Period))
  add(query_21626640, "MetricName", newJString(MetricName))
  add(query_21626640, "Version", newJString(Version))
  result = call_21626639.call(nil, query_21626640, nil, nil, nil)

var getGetMetricStatistics* = Call_GetGetMetricStatistics_21626617(
    name: "getGetMetricStatistics", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_GetGetMetricStatistics_21626618, base: "/",
    makeUrl: url_GetGetMetricStatistics_21626619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricWidgetImage_21626683 = ref object of OpenApiRestCall_21625435
proc url_PostGetMetricWidgetImage_21626685(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetMetricWidgetImage_21626684(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626686 = query.getOrDefault("Action")
  valid_21626686 = validateParameter(valid_21626686, JString, required = true,
                                   default = newJString("GetMetricWidgetImage"))
  if valid_21626686 != nil:
    section.add "Action", valid_21626686
  var valid_21626687 = query.getOrDefault("Version")
  valid_21626687 = validateParameter(valid_21626687, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626687 != nil:
    section.add "Version", valid_21626687
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626688 = header.getOrDefault("X-Amz-Date")
  valid_21626688 = validateParameter(valid_21626688, JString, required = false,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "X-Amz-Date", valid_21626688
  var valid_21626689 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626689 = validateParameter(valid_21626689, JString, required = false,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "X-Amz-Security-Token", valid_21626689
  var valid_21626690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Algorithm", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Signature")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Signature", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Credential")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Credential", valid_21626694
  result.add "header", section
  ## parameters in `formData` object:
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  section = newJObject()
  var valid_21626695 = formData.getOrDefault("OutputFormat")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "OutputFormat", valid_21626695
  assert formData != nil,
        "formData argument is necessary due to required `MetricWidget` field"
  var valid_21626696 = formData.getOrDefault("MetricWidget")
  valid_21626696 = validateParameter(valid_21626696, JString, required = true,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "MetricWidget", valid_21626696
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626697: Call_PostGetMetricWidgetImage_21626683;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_21626697.validator(path, query, header, formData, body, _)
  let scheme = call_21626697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626697.makeUrl(scheme.get, call_21626697.host, call_21626697.base,
                               call_21626697.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626697, uri, valid, _)

proc call*(call_21626698: Call_PostGetMetricWidgetImage_21626683;
          MetricWidget: string; OutputFormat: string = "";
          Action: string = "GetMetricWidgetImage"; Version: string = "2010-08-01"): Recallable =
  ## postGetMetricWidgetImage
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ##   OutputFormat: string
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   MetricWidget: string (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626699 = newJObject()
  var formData_21626700 = newJObject()
  add(formData_21626700, "OutputFormat", newJString(OutputFormat))
  add(formData_21626700, "MetricWidget", newJString(MetricWidget))
  add(query_21626699, "Action", newJString(Action))
  add(query_21626699, "Version", newJString(Version))
  result = call_21626698.call(nil, query_21626699, nil, formData_21626700, nil)

var postGetMetricWidgetImage* = Call_PostGetMetricWidgetImage_21626683(
    name: "postGetMetricWidgetImage", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_PostGetMetricWidgetImage_21626684, base: "/",
    makeUrl: url_PostGetMetricWidgetImage_21626685,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricWidgetImage_21626666 = ref object of OpenApiRestCall_21625435
proc url_GetGetMetricWidgetImage_21626668(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetMetricWidgetImage_21626667(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `MetricWidget` field"
  var valid_21626669 = query.getOrDefault("MetricWidget")
  valid_21626669 = validateParameter(valid_21626669, JString, required = true,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "MetricWidget", valid_21626669
  var valid_21626670 = query.getOrDefault("OutputFormat")
  valid_21626670 = validateParameter(valid_21626670, JString, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "OutputFormat", valid_21626670
  var valid_21626671 = query.getOrDefault("Action")
  valid_21626671 = validateParameter(valid_21626671, JString, required = true,
                                   default = newJString("GetMetricWidgetImage"))
  if valid_21626671 != nil:
    section.add "Action", valid_21626671
  var valid_21626672 = query.getOrDefault("Version")
  valid_21626672 = validateParameter(valid_21626672, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626672 != nil:
    section.add "Version", valid_21626672
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626673 = header.getOrDefault("X-Amz-Date")
  valid_21626673 = validateParameter(valid_21626673, JString, required = false,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "X-Amz-Date", valid_21626673
  var valid_21626674 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626674 = validateParameter(valid_21626674, JString, required = false,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "X-Amz-Security-Token", valid_21626674
  var valid_21626675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Algorithm", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Signature")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Signature", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Credential")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Credential", valid_21626679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626680: Call_GetGetMetricWidgetImage_21626666;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_21626680.validator(path, query, header, formData, body, _)
  let scheme = call_21626680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626680.makeUrl(scheme.get, call_21626680.host, call_21626680.base,
                               call_21626680.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626680, uri, valid, _)

proc call*(call_21626681: Call_GetGetMetricWidgetImage_21626666;
          MetricWidget: string; OutputFormat: string = "";
          Action: string = "GetMetricWidgetImage"; Version: string = "2010-08-01"): Recallable =
  ## getGetMetricWidgetImage
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ##   MetricWidget: string (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   OutputFormat: string
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626682 = newJObject()
  add(query_21626682, "MetricWidget", newJString(MetricWidget))
  add(query_21626682, "OutputFormat", newJString(OutputFormat))
  add(query_21626682, "Action", newJString(Action))
  add(query_21626682, "Version", newJString(Version))
  result = call_21626681.call(nil, query_21626682, nil, nil, nil)

var getGetMetricWidgetImage* = Call_GetGetMetricWidgetImage_21626666(
    name: "getGetMetricWidgetImage", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_GetGetMetricWidgetImage_21626667, base: "/",
    makeUrl: url_GetGetMetricWidgetImage_21626668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDashboards_21626718 = ref object of OpenApiRestCall_21625435
proc url_PostListDashboards_21626720(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListDashboards_21626719(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626721 = query.getOrDefault("Action")
  valid_21626721 = validateParameter(valid_21626721, JString, required = true,
                                   default = newJString("ListDashboards"))
  if valid_21626721 != nil:
    section.add "Action", valid_21626721
  var valid_21626722 = query.getOrDefault("Version")
  valid_21626722 = validateParameter(valid_21626722, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626722 != nil:
    section.add "Version", valid_21626722
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626723 = header.getOrDefault("X-Amz-Date")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Date", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Security-Token", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Algorithm", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Signature")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Signature", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Credential")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Credential", valid_21626729
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   DashboardNamePrefix: JString
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  section = newJObject()
  var valid_21626730 = formData.getOrDefault("NextToken")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "NextToken", valid_21626730
  var valid_21626731 = formData.getOrDefault("DashboardNamePrefix")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "DashboardNamePrefix", valid_21626731
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626732: Call_PostListDashboards_21626718; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_21626732.validator(path, query, header, formData, body, _)
  let scheme = call_21626732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626732.makeUrl(scheme.get, call_21626732.host, call_21626732.base,
                               call_21626732.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626732, uri, valid, _)

proc call*(call_21626733: Call_PostListDashboards_21626718; NextToken: string = "";
          Action: string = "ListDashboards"; DashboardNamePrefix: string = "";
          Version: string = "2010-08-01"): Recallable =
  ## postListDashboards
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Action: string (required)
  ##   DashboardNamePrefix: string
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  ##   Version: string (required)
  var query_21626734 = newJObject()
  var formData_21626735 = newJObject()
  add(formData_21626735, "NextToken", newJString(NextToken))
  add(query_21626734, "Action", newJString(Action))
  add(formData_21626735, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_21626734, "Version", newJString(Version))
  result = call_21626733.call(nil, query_21626734, nil, formData_21626735, nil)

var postListDashboards* = Call_PostListDashboards_21626718(
    name: "postListDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListDashboards",
    validator: validate_PostListDashboards_21626719, base: "/",
    makeUrl: url_PostListDashboards_21626720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDashboards_21626701 = ref object of OpenApiRestCall_21625435
proc url_GetListDashboards_21626703(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListDashboards_21626702(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DashboardNamePrefix: JString
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626704 = query.getOrDefault("DashboardNamePrefix")
  valid_21626704 = validateParameter(valid_21626704, JString, required = false,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "DashboardNamePrefix", valid_21626704
  var valid_21626705 = query.getOrDefault("NextToken")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "NextToken", valid_21626705
  var valid_21626706 = query.getOrDefault("Action")
  valid_21626706 = validateParameter(valid_21626706, JString, required = true,
                                   default = newJString("ListDashboards"))
  if valid_21626706 != nil:
    section.add "Action", valid_21626706
  var valid_21626707 = query.getOrDefault("Version")
  valid_21626707 = validateParameter(valid_21626707, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626707 != nil:
    section.add "Version", valid_21626707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626708 = header.getOrDefault("X-Amz-Date")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Date", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Security-Token", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Algorithm", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Signature")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Signature", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Credential")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Credential", valid_21626714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626715: Call_GetListDashboards_21626701; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_21626715.validator(path, query, header, formData, body, _)
  let scheme = call_21626715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626715.makeUrl(scheme.get, call_21626715.host, call_21626715.base,
                               call_21626715.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626715, uri, valid, _)

proc call*(call_21626716: Call_GetListDashboards_21626701;
          DashboardNamePrefix: string = ""; NextToken: string = "";
          Action: string = "ListDashboards"; Version: string = "2010-08-01"): Recallable =
  ## getListDashboards
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ##   DashboardNamePrefix: string
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626717 = newJObject()
  add(query_21626717, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_21626717, "NextToken", newJString(NextToken))
  add(query_21626717, "Action", newJString(Action))
  add(query_21626717, "Version", newJString(Version))
  result = call_21626716.call(nil, query_21626717, nil, nil, nil)

var getListDashboards* = Call_GetListDashboards_21626701(name: "getListDashboards",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListDashboards", validator: validate_GetListDashboards_21626702,
    base: "/", makeUrl: url_GetListDashboards_21626703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListMetrics_21626755 = ref object of OpenApiRestCall_21625435
proc url_PostListMetrics_21626757(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListMetrics_21626756(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626758 = query.getOrDefault("Action")
  valid_21626758 = validateParameter(valid_21626758, JString, required = true,
                                   default = newJString("ListMetrics"))
  if valid_21626758 != nil:
    section.add "Action", valid_21626758
  var valid_21626759 = query.getOrDefault("Version")
  valid_21626759 = validateParameter(valid_21626759, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626759 != nil:
    section.add "Version", valid_21626759
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626760 = header.getOrDefault("X-Amz-Date")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-Date", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Security-Token", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Algorithm", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Signature")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Signature", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Credential")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Credential", valid_21626766
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   MetricName: JString
  ##             : The name of the metric to filter against.
  ##   Dimensions: JArray
  ##             : The dimensions to filter against.
  ##   Namespace: JString
  ##            : The namespace to filter against.
  section = newJObject()
  var valid_21626767 = formData.getOrDefault("NextToken")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "NextToken", valid_21626767
  var valid_21626768 = formData.getOrDefault("MetricName")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "MetricName", valid_21626768
  var valid_21626769 = formData.getOrDefault("Dimensions")
  valid_21626769 = validateParameter(valid_21626769, JArray, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "Dimensions", valid_21626769
  var valid_21626770 = formData.getOrDefault("Namespace")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "Namespace", valid_21626770
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626771: Call_PostListMetrics_21626755; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_21626771.validator(path, query, header, formData, body, _)
  let scheme = call_21626771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626771.makeUrl(scheme.get, call_21626771.host, call_21626771.base,
                               call_21626771.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626771, uri, valid, _)

proc call*(call_21626772: Call_PostListMetrics_21626755; NextToken: string = "";
          MetricName: string = ""; Dimensions: JsonNode = nil;
          Action: string = "ListMetrics"; Namespace: string = "";
          Version: string = "2010-08-01"): Recallable =
  ## postListMetrics
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   MetricName: string
  ##             : The name of the metric to filter against.
  ##   Dimensions: JArray
  ##             : The dimensions to filter against.
  ##   Action: string (required)
  ##   Namespace: string
  ##            : The namespace to filter against.
  ##   Version: string (required)
  var query_21626773 = newJObject()
  var formData_21626774 = newJObject()
  add(formData_21626774, "NextToken", newJString(NextToken))
  add(formData_21626774, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_21626774.add "Dimensions", Dimensions
  add(query_21626773, "Action", newJString(Action))
  add(formData_21626774, "Namespace", newJString(Namespace))
  add(query_21626773, "Version", newJString(Version))
  result = call_21626772.call(nil, query_21626773, nil, formData_21626774, nil)

var postListMetrics* = Call_PostListMetrics_21626755(name: "postListMetrics",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_PostListMetrics_21626756,
    base: "/", makeUrl: url_PostListMetrics_21626757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListMetrics_21626736 = ref object of OpenApiRestCall_21625435
proc url_GetListMetrics_21626738(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListMetrics_21626737(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString
  ##            : The namespace to filter against.
  ##   Dimensions: JArray
  ##             : The dimensions to filter against.
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MetricName: JString
  ##             : The name of the metric to filter against.
  section = newJObject()
  var valid_21626739 = query.getOrDefault("Namespace")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "Namespace", valid_21626739
  var valid_21626740 = query.getOrDefault("Dimensions")
  valid_21626740 = validateParameter(valid_21626740, JArray, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "Dimensions", valid_21626740
  var valid_21626741 = query.getOrDefault("NextToken")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "NextToken", valid_21626741
  var valid_21626742 = query.getOrDefault("Action")
  valid_21626742 = validateParameter(valid_21626742, JString, required = true,
                                   default = newJString("ListMetrics"))
  if valid_21626742 != nil:
    section.add "Action", valid_21626742
  var valid_21626743 = query.getOrDefault("Version")
  valid_21626743 = validateParameter(valid_21626743, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626743 != nil:
    section.add "Version", valid_21626743
  var valid_21626744 = query.getOrDefault("MetricName")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "MetricName", valid_21626744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626745 = header.getOrDefault("X-Amz-Date")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Date", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Security-Token", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Algorithm", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Signature")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Signature", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Credential")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Credential", valid_21626751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626752: Call_GetListMetrics_21626736; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_21626752.validator(path, query, header, formData, body, _)
  let scheme = call_21626752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626752.makeUrl(scheme.get, call_21626752.host, call_21626752.base,
                               call_21626752.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626752, uri, valid, _)

proc call*(call_21626753: Call_GetListMetrics_21626736; Namespace: string = "";
          Dimensions: JsonNode = nil; NextToken: string = "";
          Action: string = "ListMetrics"; Version: string = "2010-08-01";
          MetricName: string = ""): Recallable =
  ## getListMetrics
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ##   Namespace: string
  ##            : The namespace to filter against.
  ##   Dimensions: JArray
  ##             : The dimensions to filter against.
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricName: string
  ##             : The name of the metric to filter against.
  var query_21626754 = newJObject()
  add(query_21626754, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_21626754.add "Dimensions", Dimensions
  add(query_21626754, "NextToken", newJString(NextToken))
  add(query_21626754, "Action", newJString(Action))
  add(query_21626754, "Version", newJString(Version))
  add(query_21626754, "MetricName", newJString(MetricName))
  result = call_21626753.call(nil, query_21626754, nil, nil, nil)

var getListMetrics* = Call_GetListMetrics_21626736(name: "getListMetrics",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_GetListMetrics_21626737,
    base: "/", makeUrl: url_GetListMetrics_21626738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_21626791 = ref object of OpenApiRestCall_21625435
proc url_PostListTagsForResource_21626793(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_21626792(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626794 = query.getOrDefault("Action")
  valid_21626794 = validateParameter(valid_21626794, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21626794 != nil:
    section.add "Action", valid_21626794
  var valid_21626795 = query.getOrDefault("Version")
  valid_21626795 = validateParameter(valid_21626795, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626795 != nil:
    section.add "Version", valid_21626795
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626796 = header.getOrDefault("X-Amz-Date")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Date", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Security-Token", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Algorithm", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Signature")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Signature", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-Credential")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-Credential", valid_21626802
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceARN` field"
  var valid_21626803 = formData.getOrDefault("ResourceARN")
  valid_21626803 = validateParameter(valid_21626803, JString, required = true,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "ResourceARN", valid_21626803
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626804: Call_PostListTagsForResource_21626791;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_21626804.validator(path, query, header, formData, body, _)
  let scheme = call_21626804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626804.makeUrl(scheme.get, call_21626804.host, call_21626804.base,
                               call_21626804.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626804, uri, valid, _)

proc call*(call_21626805: Call_PostListTagsForResource_21626791;
          ResourceARN: string; Action: string = "ListTagsForResource";
          Version: string = "2010-08-01"): Recallable =
  ## postListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_21626806 = newJObject()
  var formData_21626807 = newJObject()
  add(query_21626806, "Action", newJString(Action))
  add(formData_21626807, "ResourceARN", newJString(ResourceARN))
  add(query_21626806, "Version", newJString(Version))
  result = call_21626805.call(nil, query_21626806, nil, formData_21626807, nil)

var postListTagsForResource* = Call_PostListTagsForResource_21626791(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_21626792, base: "/",
    makeUrl: url_PostListTagsForResource_21626793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_21626775 = ref object of OpenApiRestCall_21625435
proc url_GetListTagsForResource_21626777(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_21626776(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceARN` field"
  var valid_21626778 = query.getOrDefault("ResourceARN")
  valid_21626778 = validateParameter(valid_21626778, JString, required = true,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "ResourceARN", valid_21626778
  var valid_21626779 = query.getOrDefault("Action")
  valid_21626779 = validateParameter(valid_21626779, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21626779 != nil:
    section.add "Action", valid_21626779
  var valid_21626780 = query.getOrDefault("Version")
  valid_21626780 = validateParameter(valid_21626780, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626780 != nil:
    section.add "Version", valid_21626780
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626781 = header.getOrDefault("X-Amz-Date")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-Date", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Security-Token", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Algorithm", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Signature")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Signature", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-Credential")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Credential", valid_21626787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626788: Call_GetListTagsForResource_21626775;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_21626788.validator(path, query, header, formData, body, _)
  let scheme = call_21626788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626788.makeUrl(scheme.get, call_21626788.host, call_21626788.base,
                               call_21626788.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626788, uri, valid, _)

proc call*(call_21626789: Call_GetListTagsForResource_21626775;
          ResourceARN: string; Action: string = "ListTagsForResource";
          Version: string = "2010-08-01"): Recallable =
  ## getListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626790 = newJObject()
  add(query_21626790, "ResourceARN", newJString(ResourceARN))
  add(query_21626790, "Action", newJString(Action))
  add(query_21626790, "Version", newJString(Version))
  result = call_21626789.call(nil, query_21626790, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_21626775(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_21626776, base: "/",
    makeUrl: url_GetListTagsForResource_21626777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAnomalyDetector_21626829 = ref object of OpenApiRestCall_21625435
proc url_PostPutAnomalyDetector_21626831(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutAnomalyDetector_21626830(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626832 = query.getOrDefault("Action")
  valid_21626832 = validateParameter(valid_21626832, JString, required = true,
                                   default = newJString("PutAnomalyDetector"))
  if valid_21626832 != nil:
    section.add "Action", valid_21626832
  var valid_21626833 = query.getOrDefault("Version")
  valid_21626833 = validateParameter(valid_21626833, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626833 != nil:
    section.add "Version", valid_21626833
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626834 = header.getOrDefault("X-Amz-Date")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Date", valid_21626834
  var valid_21626835 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Security-Token", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Algorithm", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Signature")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Signature", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-Credential")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Credential", valid_21626840
  result.add "header", section
  ## parameters in `formData` object:
  ##   Configuration.ExcludedTimeRanges: JArray
  ##                                   : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## An array of time ranges to exclude from use when the anomaly detection model is trained. Use this to make sure that events that could cause unusual values for the metric, such as deployments, aren't used when CloudWatch creates the model.
  ##   Configuration.MetricTimezone: JString
  ##                               : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## <p>The time zone to use for the metric. This is useful to enable the model to automatically account for daylight savings time changes if the metric is sensitive to such time changes.</p> <p>To specify a time zone, use the name of the time zone as specified in the standard tz database. For more information, see <a href="https://en.wikipedia.org/wiki/Tz_database">tz database</a>.</p>
  ##   MetricName: JString (required)
  ##             : The name of the metric to create the anomaly detection model for.
  ##   Dimensions: JArray
  ##             : The metric dimensions to create the anomaly detection model for.
  ##   Stat: JString (required)
  ##       : The statistic to use for the metric and the anomaly detection model.
  ##   Namespace: JString (required)
  ##            : The namespace of the metric to create the anomaly detection model for.
  section = newJObject()
  var valid_21626841 = formData.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_21626841 = validateParameter(valid_21626841, JArray, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_21626841
  var valid_21626842 = formData.getOrDefault("Configuration.MetricTimezone")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "Configuration.MetricTimezone", valid_21626842
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_21626843 = formData.getOrDefault("MetricName")
  valid_21626843 = validateParameter(valid_21626843, JString, required = true,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "MetricName", valid_21626843
  var valid_21626844 = formData.getOrDefault("Dimensions")
  valid_21626844 = validateParameter(valid_21626844, JArray, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "Dimensions", valid_21626844
  var valid_21626845 = formData.getOrDefault("Stat")
  valid_21626845 = validateParameter(valid_21626845, JString, required = true,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "Stat", valid_21626845
  var valid_21626846 = formData.getOrDefault("Namespace")
  valid_21626846 = validateParameter(valid_21626846, JString, required = true,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "Namespace", valid_21626846
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626847: Call_PostPutAnomalyDetector_21626829;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_21626847.validator(path, query, header, formData, body, _)
  let scheme = call_21626847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626847.makeUrl(scheme.get, call_21626847.host, call_21626847.base,
                               call_21626847.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626847, uri, valid, _)

proc call*(call_21626848: Call_PostPutAnomalyDetector_21626829; MetricName: string;
          Stat: string; Namespace: string;
          ConfigurationExcludedTimeRanges: JsonNode = nil;
          ConfigurationMetricTimezone: string = ""; Dimensions: JsonNode = nil;
          Action: string = "PutAnomalyDetector"; Version: string = "2010-08-01"): Recallable =
  ## postPutAnomalyDetector
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ##   ConfigurationExcludedTimeRanges: JArray
  ##                                  : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## An array of time ranges to exclude from use when the anomaly detection model is trained. Use this to make sure that events that could cause unusual values for the metric, such as deployments, aren't used when CloudWatch creates the model.
  ##   ConfigurationMetricTimezone: string
  ##                              : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## <p>The time zone to use for the metric. This is useful to enable the model to automatically account for daylight savings time changes if the metric is sensitive to such time changes.</p> <p>To specify a time zone, use the name of the time zone as specified in the standard tz database. For more information, see <a href="https://en.wikipedia.org/wiki/Tz_database">tz database</a>.</p>
  ##   MetricName: string (required)
  ##             : The name of the metric to create the anomaly detection model for.
  ##   Dimensions: JArray
  ##             : The metric dimensions to create the anomaly detection model for.
  ##   Action: string (required)
  ##   Stat: string (required)
  ##       : The statistic to use for the metric and the anomaly detection model.
  ##   Namespace: string (required)
  ##            : The namespace of the metric to create the anomaly detection model for.
  ##   Version: string (required)
  var query_21626849 = newJObject()
  var formData_21626850 = newJObject()
  if ConfigurationExcludedTimeRanges != nil:
    formData_21626850.add "Configuration.ExcludedTimeRanges",
                         ConfigurationExcludedTimeRanges
  add(formData_21626850, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  add(formData_21626850, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_21626850.add "Dimensions", Dimensions
  add(query_21626849, "Action", newJString(Action))
  add(formData_21626850, "Stat", newJString(Stat))
  add(formData_21626850, "Namespace", newJString(Namespace))
  add(query_21626849, "Version", newJString(Version))
  result = call_21626848.call(nil, query_21626849, nil, formData_21626850, nil)

var postPutAnomalyDetector* = Call_PostPutAnomalyDetector_21626829(
    name: "postPutAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_PostPutAnomalyDetector_21626830, base: "/",
    makeUrl: url_PostPutAnomalyDetector_21626831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAnomalyDetector_21626808 = ref object of OpenApiRestCall_21625435
proc url_GetPutAnomalyDetector_21626810(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutAnomalyDetector_21626809(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString (required)
  ##            : The namespace of the metric to create the anomaly detection model for.
  ##   Stat: JString (required)
  ##       : The statistic to use for the metric and the anomaly detection model.
  ##   Configuration.MetricTimezone: JString
  ##                               : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## <p>The time zone to use for the metric. This is useful to enable the model to automatically account for daylight savings time changes if the metric is sensitive to such time changes.</p> <p>To specify a time zone, use the name of the time zone as specified in the standard tz database. For more information, see <a href="https://en.wikipedia.org/wiki/Tz_database">tz database</a>.</p>
  ##   Dimensions: JArray
  ##             : The metric dimensions to create the anomaly detection model for.
  ##   Action: JString (required)
  ##   Configuration.ExcludedTimeRanges: JArray
  ##                                   : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## An array of time ranges to exclude from use when the anomaly detection model is trained. Use this to make sure that events that could cause unusual values for the metric, such as deployments, aren't used when CloudWatch creates the model.
  ##   Version: JString (required)
  ##   MetricName: JString (required)
  ##             : The name of the metric to create the anomaly detection model for.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_21626811 = query.getOrDefault("Namespace")
  valid_21626811 = validateParameter(valid_21626811, JString, required = true,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "Namespace", valid_21626811
  var valid_21626812 = query.getOrDefault("Stat")
  valid_21626812 = validateParameter(valid_21626812, JString, required = true,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "Stat", valid_21626812
  var valid_21626813 = query.getOrDefault("Configuration.MetricTimezone")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "Configuration.MetricTimezone", valid_21626813
  var valid_21626814 = query.getOrDefault("Dimensions")
  valid_21626814 = validateParameter(valid_21626814, JArray, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "Dimensions", valid_21626814
  var valid_21626815 = query.getOrDefault("Action")
  valid_21626815 = validateParameter(valid_21626815, JString, required = true,
                                   default = newJString("PutAnomalyDetector"))
  if valid_21626815 != nil:
    section.add "Action", valid_21626815
  var valid_21626816 = query.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_21626816 = validateParameter(valid_21626816, JArray, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_21626816
  var valid_21626817 = query.getOrDefault("Version")
  valid_21626817 = validateParameter(valid_21626817, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626817 != nil:
    section.add "Version", valid_21626817
  var valid_21626818 = query.getOrDefault("MetricName")
  valid_21626818 = validateParameter(valid_21626818, JString, required = true,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "MetricName", valid_21626818
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626819 = header.getOrDefault("X-Amz-Date")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Date", valid_21626819
  var valid_21626820 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Security-Token", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Algorithm", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Signature")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Signature", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Credential")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Credential", valid_21626825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626826: Call_GetPutAnomalyDetector_21626808;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_21626826.validator(path, query, header, formData, body, _)
  let scheme = call_21626826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626826.makeUrl(scheme.get, call_21626826.host, call_21626826.base,
                               call_21626826.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626826, uri, valid, _)

proc call*(call_21626827: Call_GetPutAnomalyDetector_21626808; Namespace: string;
          Stat: string; MetricName: string;
          ConfigurationMetricTimezone: string = ""; Dimensions: JsonNode = nil;
          Action: string = "PutAnomalyDetector";
          ConfigurationExcludedTimeRanges: JsonNode = nil;
          Version: string = "2010-08-01"): Recallable =
  ## getPutAnomalyDetector
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ##   Namespace: string (required)
  ##            : The namespace of the metric to create the anomaly detection model for.
  ##   Stat: string (required)
  ##       : The statistic to use for the metric and the anomaly detection model.
  ##   ConfigurationMetricTimezone: string
  ##                              : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## <p>The time zone to use for the metric. This is useful to enable the model to automatically account for daylight savings time changes if the metric is sensitive to such time changes.</p> <p>To specify a time zone, use the name of the time zone as specified in the standard tz database. For more information, see <a href="https://en.wikipedia.org/wiki/Tz_database">tz database</a>.</p>
  ##   Dimensions: JArray
  ##             : The metric dimensions to create the anomaly detection model for.
  ##   Action: string (required)
  ##   ConfigurationExcludedTimeRanges: JArray
  ##                                  : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## An array of time ranges to exclude from use when the anomaly detection model is trained. Use this to make sure that events that could cause unusual values for the metric, such as deployments, aren't used when CloudWatch creates the model.
  ##   Version: string (required)
  ##   MetricName: string (required)
  ##             : The name of the metric to create the anomaly detection model for.
  var query_21626828 = newJObject()
  add(query_21626828, "Namespace", newJString(Namespace))
  add(query_21626828, "Stat", newJString(Stat))
  add(query_21626828, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  if Dimensions != nil:
    query_21626828.add "Dimensions", Dimensions
  add(query_21626828, "Action", newJString(Action))
  if ConfigurationExcludedTimeRanges != nil:
    query_21626828.add "Configuration.ExcludedTimeRanges",
                      ConfigurationExcludedTimeRanges
  add(query_21626828, "Version", newJString(Version))
  add(query_21626828, "MetricName", newJString(MetricName))
  result = call_21626827.call(nil, query_21626828, nil, nil, nil)

var getPutAnomalyDetector* = Call_GetPutAnomalyDetector_21626808(
    name: "getPutAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_GetPutAnomalyDetector_21626809, base: "/",
    makeUrl: url_GetPutAnomalyDetector_21626810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutDashboard_21626868 = ref object of OpenApiRestCall_21625435
proc url_PostPutDashboard_21626870(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutDashboard_21626869(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626871 = query.getOrDefault("Action")
  valid_21626871 = validateParameter(valid_21626871, JString, required = true,
                                   default = newJString("PutDashboard"))
  if valid_21626871 != nil:
    section.add "Action", valid_21626871
  var valid_21626872 = query.getOrDefault("Version")
  valid_21626872 = validateParameter(valid_21626872, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626872 != nil:
    section.add "Version", valid_21626872
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626873 = header.getOrDefault("X-Amz-Date")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Date", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Security-Token", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-Algorithm", valid_21626876
  var valid_21626877 = header.getOrDefault("X-Amz-Signature")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "X-Amz-Signature", valid_21626877
  var valid_21626878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626878
  var valid_21626879 = header.getOrDefault("X-Amz-Credential")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "X-Amz-Credential", valid_21626879
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_21626880 = formData.getOrDefault("DashboardName")
  valid_21626880 = validateParameter(valid_21626880, JString, required = true,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "DashboardName", valid_21626880
  var valid_21626881 = formData.getOrDefault("DashboardBody")
  valid_21626881 = validateParameter(valid_21626881, JString, required = true,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "DashboardBody", valid_21626881
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626882: Call_PostPutDashboard_21626868; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_21626882.validator(path, query, header, formData, body, _)
  let scheme = call_21626882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626882.makeUrl(scheme.get, call_21626882.host, call_21626882.base,
                               call_21626882.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626882, uri, valid, _)

proc call*(call_21626883: Call_PostPutDashboard_21626868; DashboardName: string;
          DashboardBody: string; Action: string = "PutDashboard";
          Version: string = "2010-08-01"): Recallable =
  ## postPutDashboard
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   DashboardBody: string (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  ##   Version: string (required)
  var query_21626884 = newJObject()
  var formData_21626885 = newJObject()
  add(query_21626884, "Action", newJString(Action))
  add(formData_21626885, "DashboardName", newJString(DashboardName))
  add(formData_21626885, "DashboardBody", newJString(DashboardBody))
  add(query_21626884, "Version", newJString(Version))
  result = call_21626883.call(nil, query_21626884, nil, formData_21626885, nil)

var postPutDashboard* = Call_PostPutDashboard_21626868(name: "postPutDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_PostPutDashboard_21626869,
    base: "/", makeUrl: url_PostPutDashboard_21626870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutDashboard_21626851 = ref object of OpenApiRestCall_21625435
proc url_GetPutDashboard_21626853(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutDashboard_21626852(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   Action: JString (required)
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DashboardName` field"
  var valid_21626854 = query.getOrDefault("DashboardName")
  valid_21626854 = validateParameter(valid_21626854, JString, required = true,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "DashboardName", valid_21626854
  var valid_21626855 = query.getOrDefault("Action")
  valid_21626855 = validateParameter(valid_21626855, JString, required = true,
                                   default = newJString("PutDashboard"))
  if valid_21626855 != nil:
    section.add "Action", valid_21626855
  var valid_21626856 = query.getOrDefault("DashboardBody")
  valid_21626856 = validateParameter(valid_21626856, JString, required = true,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "DashboardBody", valid_21626856
  var valid_21626857 = query.getOrDefault("Version")
  valid_21626857 = validateParameter(valid_21626857, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626857 != nil:
    section.add "Version", valid_21626857
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626858 = header.getOrDefault("X-Amz-Date")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Date", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Security-Token", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Algorithm", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-Signature")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "X-Amz-Signature", valid_21626862
  var valid_21626863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626863
  var valid_21626864 = header.getOrDefault("X-Amz-Credential")
  valid_21626864 = validateParameter(valid_21626864, JString, required = false,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "X-Amz-Credential", valid_21626864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626865: Call_GetPutDashboard_21626851; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_21626865.validator(path, query, header, formData, body, _)
  let scheme = call_21626865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626865.makeUrl(scheme.get, call_21626865.host, call_21626865.base,
                               call_21626865.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626865, uri, valid, _)

proc call*(call_21626866: Call_GetPutDashboard_21626851; DashboardName: string;
          DashboardBody: string; Action: string = "PutDashboard";
          Version: string = "2010-08-01"): Recallable =
  ## getPutDashboard
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   Action: string (required)
  ##   DashboardBody: string (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  ##   Version: string (required)
  var query_21626867 = newJObject()
  add(query_21626867, "DashboardName", newJString(DashboardName))
  add(query_21626867, "Action", newJString(Action))
  add(query_21626867, "DashboardBody", newJString(DashboardBody))
  add(query_21626867, "Version", newJString(Version))
  result = call_21626866.call(nil, query_21626867, nil, nil, nil)

var getPutDashboard* = Call_GetPutDashboard_21626851(name: "getPutDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_GetPutDashboard_21626852,
    base: "/", makeUrl: url_GetPutDashboard_21626853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutInsightRule_21626904 = ref object of OpenApiRestCall_21625435
proc url_PostPutInsightRule_21626906(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutInsightRule_21626905(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626907 = query.getOrDefault("Action")
  valid_21626907 = validateParameter(valid_21626907, JString, required = true,
                                   default = newJString("PutInsightRule"))
  if valid_21626907 != nil:
    section.add "Action", valid_21626907
  var valid_21626908 = query.getOrDefault("Version")
  valid_21626908 = validateParameter(valid_21626908, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626908 != nil:
    section.add "Version", valid_21626908
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626909 = header.getOrDefault("X-Amz-Date")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Date", valid_21626909
  var valid_21626910 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Security-Token", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Algorithm", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Signature")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Signature", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-Credential")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-Credential", valid_21626915
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleName: JString (required)
  ##           : A unique name for the rule.
  ##   RuleState: JString
  ##            : The state of the rule. Valid values are ENABLED and DISABLED.
  ##   RuleDefinition: JString (required)
  ##                 : The definition of the rule, as a JSON object. For details on the valid syntax, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights-RuleSyntax.html">Contributor Insights Rule Syntax</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleName` field"
  var valid_21626916 = formData.getOrDefault("RuleName")
  valid_21626916 = validateParameter(valid_21626916, JString, required = true,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "RuleName", valid_21626916
  var valid_21626917 = formData.getOrDefault("RuleState")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "RuleState", valid_21626917
  var valid_21626918 = formData.getOrDefault("RuleDefinition")
  valid_21626918 = validateParameter(valid_21626918, JString, required = true,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "RuleDefinition", valid_21626918
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626919: Call_PostPutInsightRule_21626904; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_21626919.validator(path, query, header, formData, body, _)
  let scheme = call_21626919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626919.makeUrl(scheme.get, call_21626919.host, call_21626919.base,
                               call_21626919.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626919, uri, valid, _)

proc call*(call_21626920: Call_PostPutInsightRule_21626904; RuleName: string;
          RuleDefinition: string; Action: string = "PutInsightRule";
          RuleState: string = ""; Version: string = "2010-08-01"): Recallable =
  ## postPutInsightRule
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   RuleName: string (required)
  ##           : A unique name for the rule.
  ##   Action: string (required)
  ##   RuleState: string
  ##            : The state of the rule. Valid values are ENABLED and DISABLED.
  ##   RuleDefinition: string (required)
  ##                 : The definition of the rule, as a JSON object. For details on the valid syntax, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights-RuleSyntax.html">Contributor Insights Rule Syntax</a>.
  ##   Version: string (required)
  var query_21626921 = newJObject()
  var formData_21626922 = newJObject()
  add(formData_21626922, "RuleName", newJString(RuleName))
  add(query_21626921, "Action", newJString(Action))
  add(formData_21626922, "RuleState", newJString(RuleState))
  add(formData_21626922, "RuleDefinition", newJString(RuleDefinition))
  add(query_21626921, "Version", newJString(Version))
  result = call_21626920.call(nil, query_21626921, nil, formData_21626922, nil)

var postPutInsightRule* = Call_PostPutInsightRule_21626904(
    name: "postPutInsightRule", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutInsightRule",
    validator: validate_PostPutInsightRule_21626905, base: "/",
    makeUrl: url_PostPutInsightRule_21626906, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutInsightRule_21626886 = ref object of OpenApiRestCall_21625435
proc url_GetPutInsightRule_21626888(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutInsightRule_21626887(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RuleName: JString (required)
  ##           : A unique name for the rule.
  ##   Action: JString (required)
  ##   RuleDefinition: JString (required)
  ##                 : The definition of the rule, as a JSON object. For details on the valid syntax, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights-RuleSyntax.html">Contributor Insights Rule Syntax</a>.
  ##   RuleState: JString
  ##            : The state of the rule. Valid values are ENABLED and DISABLED.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `RuleName` field"
  var valid_21626889 = query.getOrDefault("RuleName")
  valid_21626889 = validateParameter(valid_21626889, JString, required = true,
                                   default = nil)
  if valid_21626889 != nil:
    section.add "RuleName", valid_21626889
  var valid_21626890 = query.getOrDefault("Action")
  valid_21626890 = validateParameter(valid_21626890, JString, required = true,
                                   default = newJString("PutInsightRule"))
  if valid_21626890 != nil:
    section.add "Action", valid_21626890
  var valid_21626891 = query.getOrDefault("RuleDefinition")
  valid_21626891 = validateParameter(valid_21626891, JString, required = true,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "RuleDefinition", valid_21626891
  var valid_21626892 = query.getOrDefault("RuleState")
  valid_21626892 = validateParameter(valid_21626892, JString, required = false,
                                   default = nil)
  if valid_21626892 != nil:
    section.add "RuleState", valid_21626892
  var valid_21626893 = query.getOrDefault("Version")
  valid_21626893 = validateParameter(valid_21626893, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626893 != nil:
    section.add "Version", valid_21626893
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626894 = header.getOrDefault("X-Amz-Date")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "X-Amz-Date", valid_21626894
  var valid_21626895 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Security-Token", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Algorithm", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Signature")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Signature", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Credential")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Credential", valid_21626900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626901: Call_GetPutInsightRule_21626886; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_21626901.validator(path, query, header, formData, body, _)
  let scheme = call_21626901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626901.makeUrl(scheme.get, call_21626901.host, call_21626901.base,
                               call_21626901.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626901, uri, valid, _)

proc call*(call_21626902: Call_GetPutInsightRule_21626886; RuleName: string;
          RuleDefinition: string; Action: string = "PutInsightRule";
          RuleState: string = ""; Version: string = "2010-08-01"): Recallable =
  ## getPutInsightRule
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   RuleName: string (required)
  ##           : A unique name for the rule.
  ##   Action: string (required)
  ##   RuleDefinition: string (required)
  ##                 : The definition of the rule, as a JSON object. For details on the valid syntax, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights-RuleSyntax.html">Contributor Insights Rule Syntax</a>.
  ##   RuleState: string
  ##            : The state of the rule. Valid values are ENABLED and DISABLED.
  ##   Version: string (required)
  var query_21626903 = newJObject()
  add(query_21626903, "RuleName", newJString(RuleName))
  add(query_21626903, "Action", newJString(Action))
  add(query_21626903, "RuleDefinition", newJString(RuleDefinition))
  add(query_21626903, "RuleState", newJString(RuleState))
  add(query_21626903, "Version", newJString(Version))
  result = call_21626902.call(nil, query_21626903, nil, nil, nil)

var getPutInsightRule* = Call_GetPutInsightRule_21626886(name: "getPutInsightRule",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutInsightRule", validator: validate_GetPutInsightRule_21626887,
    base: "/", makeUrl: url_GetPutInsightRule_21626888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricAlarm_21626960 = ref object of OpenApiRestCall_21625435
proc url_PostPutMetricAlarm_21626962(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutMetricAlarm_21626961(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626963 = query.getOrDefault("Action")
  valid_21626963 = validateParameter(valid_21626963, JString, required = true,
                                   default = newJString("PutMetricAlarm"))
  if valid_21626963 != nil:
    section.add "Action", valid_21626963
  var valid_21626964 = query.getOrDefault("Version")
  valid_21626964 = validateParameter(valid_21626964, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626964 != nil:
    section.add "Version", valid_21626964
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626965 = header.getOrDefault("X-Amz-Date")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Date", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Security-Token", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-Algorithm", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-Signature")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-Signature", valid_21626969
  var valid_21626970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-Credential")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-Credential", valid_21626971
  result.add "header", section
  ## parameters in `formData` object:
  ##   ActionsEnabled: JBool
  ##                 : Indicates whether actions should be executed during any changes to the alarm state. The default is <code>TRUE</code>.
  ##   Threshold: JFloat
  ##            : <p>The value against which the specified statistic is compared.</p> <p>This parameter is required for alarms based on static thresholds, but should not be used for alarms based on anomaly detection models.</p>
  ##   ExtendedStatistic: JString
  ##                    : The percentile statistic for the metric specified in <code>MetricName</code>. Specify a value between p0.0 and p100. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   Metrics: JArray
  ##          : <p>An array of <code>MetricDataQuery</code> structures that enable you to create an alarm based on the result of a metric math expression. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>Each item in the <code>Metrics</code> array either retrieves a metric or performs a math expression.</p> <p>One item in the <code>Metrics</code> array is the expression that the alarm watches. You designate this expression by setting <code>ReturnValue</code> to true for this object in the array. For more information, see <a>MetricDataQuery</a>.</p> <p>If you use the <code>Metrics</code> parameter, you cannot include the <code>MetricName</code>, <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters of <code>PutMetricAlarm</code> in the same operation. Instead, you retrieve the metrics you are using in your math expression as part of the <code>Metrics</code> array.</p>
  ##   MetricName: JString
  ##             : <p>The name for the metric associated with the alarm. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>If you are creating an alarm based on a math expression, you cannot specify this parameter, or any of the <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters. Instead, you specify all this information in the <code>Metrics</code> array.</p>
  ##   TreatMissingData: JString
  ##                   : <p> Sets how this alarm is to handle missing data points. If <code>TreatMissingData</code> is omitted, the default behavior of <code>missing</code> is used. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarms-and-missing-data">Configuring How CloudWatch Alarms Treats Missing Data</a>.</p> <p>Valid Values: <code>breaching | notBreaching | ignore | missing</code> </p>
  ##   AlarmDescription: JString
  ##                   : The description for the alarm.
  ##   Dimensions: JArray
  ##             : The dimensions for the metric specified in <code>MetricName</code>.
  ##   ComparisonOperator: JString (required)
  ##                     : <p> The arithmetic operation to use when comparing the specified statistic and threshold. The specified statistic value is used as the first operand.</p> <p>The values <code>LessThanLowerOrGreaterThanUpperThreshold</code>, <code>LessThanLowerThreshold</code>, and <code>GreaterThanUpperThreshold</code> are used only for alarms based on anomaly detection models.</p>
  ##   Tags: JArray
  ##       : <p>A list of key-value pairs to associate with the alarm. You can associate as many as 50 tags with an alarm.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p>
  ##   ThresholdMetricId: JString
  ##                    : <p>If this is an alarm based on an anomaly detection model, make this value match the ID of the <code>ANOMALY_DETECTION_BAND</code> function.</p> <p>For an example of how to use this parameter, see the <b>Anomaly Detection Model Alarm</b> example on this page.</p> <p>If your alarm uses this parameter, it cannot have Auto Scaling actions.</p>
  ##   OKActions: JArray
  ##            : <p>The actions to execute when this alarm transitions to an <code>OK</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Statistic: JString
  ##            : The statistic for the metric specified in <code>MetricName</code>, other than percentile. For percentile statistics, use <code>ExtendedStatistic</code>. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   EvaluationPeriods: JInt (required)
  ##                    : <p>The number of periods over which data is compared to the specified threshold. If you are setting an alarm that requires that a number of consecutive data points be breaching to trigger the alarm, this value specifies that number. If you are setting an "M out of N" alarm, this value is the N.</p> <p>An alarm's total current evaluation period can be no longer than one day, so this number multiplied by <code>Period</code> cannot be more than 86,400 seconds.</p>
  ##   DatapointsToAlarm: JInt
  ##                    : The number of data points that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarm-evaluation">Evaluating an Alarm</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   AlarmName: JString (required)
  ##            : The name for the alarm. This name must be unique within your AWS account.
  ##   Namespace: JString
  ##            : The namespace for the metric associated specified in <code>MetricName</code>.
  ##   InsufficientDataActions: JArray
  ##                          : <p>The actions to execute when this alarm transitions to the <code>INSUFFICIENT_DATA</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>&gt;arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   AlarmActions: JArray
  ##               : <p>The actions to execute when this alarm transitions to the <code>ALARM</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   EvaluateLowSampleCountPercentile: JString
  ##                                   : <p> Used only for alarms based on percentiles. If you specify <code>ignore</code>, the alarm state does not change during periods with too few data points to be statistically significant. If you specify <code>evaluate</code> or omit this parameter, the alarm is always evaluated and possibly changes state no matter how many data points are available. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#percentiles-with-low-samples">Percentile-Based CloudWatch Alarms and Low Data Samples</a>.</p> <p>Valid Values: <code>evaluate | ignore</code> </p>
  ##   Unit: JString
  ##       : <p>The unit of measure for the statistic. For example, the units for the Amazon EC2 NetworkIn metric are Bytes because NetworkIn tracks the number of bytes that an instance receives on all network interfaces. You can also specify a unit when you create a custom metric. Units help provide conceptual meaning to your data. Metric data points that specify a unit of measure, such as Percent, are aggregated separately.</p> <p>If you don't specify <code>Unit</code>, CloudWatch retrieves all unit types that have been published for the metric and attempts to evaluate the alarm. Usually metrics are published with only one unit, so the alarm will work as intended.</p> <p>However, if the metric is published with multiple types of units and you don't specify a unit, the alarm's behavior is not defined and will behave un-predictably.</p> <p>We recommend omitting <code>Unit</code> so that you don't inadvertently specify an incorrect unit that is not published for this metric. Doing so causes the alarm to be stuck in the <code>INSUFFICIENT DATA</code> state.</p>
  ##   Period: JInt
  ##         : <p>The length, in seconds, used each time the metric specified in <code>MetricName</code> is evaluated. Valid values are 10, 30, and any multiple of 60.</p> <p> <code>Period</code> is required for alarms based on static thresholds. If you are creating an alarm based on a metric math expression, you specify the period for each metric within the objects in the <code>Metrics</code> array.</p> <p>Be sure to specify 10 or 30 only for metrics that are stored by a <code>PutMetricData</code> call with a <code>StorageResolution</code> of 1. If you specify a period of 10 or 30 for a metric that does not have sub-minute resolution, the alarm still attempts to gather data at the period rate that you specify. In this case, it does not receive data for the attempts that do not correspond to a one-minute data resolution, and the alarm may often lapse into INSUFFICENT_DATA status. Specifying 10 or 30 also sets this alarm as a high-resolution alarm, which has a higher charge than other alarms. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>An alarm's total current evaluation period can be no longer than one day, so <code>Period</code> multiplied by <code>EvaluationPeriods</code> cannot be more than 86,400 seconds.</p>
  section = newJObject()
  var valid_21626972 = formData.getOrDefault("ActionsEnabled")
  valid_21626972 = validateParameter(valid_21626972, JBool, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "ActionsEnabled", valid_21626972
  var valid_21626973 = formData.getOrDefault("Threshold")
  valid_21626973 = validateParameter(valid_21626973, JFloat, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "Threshold", valid_21626973
  var valid_21626974 = formData.getOrDefault("ExtendedStatistic")
  valid_21626974 = validateParameter(valid_21626974, JString, required = false,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "ExtendedStatistic", valid_21626974
  var valid_21626975 = formData.getOrDefault("Metrics")
  valid_21626975 = validateParameter(valid_21626975, JArray, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "Metrics", valid_21626975
  var valid_21626976 = formData.getOrDefault("MetricName")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "MetricName", valid_21626976
  var valid_21626977 = formData.getOrDefault("TreatMissingData")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "TreatMissingData", valid_21626977
  var valid_21626978 = formData.getOrDefault("AlarmDescription")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "AlarmDescription", valid_21626978
  var valid_21626979 = formData.getOrDefault("Dimensions")
  valid_21626979 = validateParameter(valid_21626979, JArray, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "Dimensions", valid_21626979
  var valid_21626980 = formData.getOrDefault("ComparisonOperator")
  valid_21626980 = validateParameter(valid_21626980, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_21626980 != nil:
    section.add "ComparisonOperator", valid_21626980
  var valid_21626981 = formData.getOrDefault("Tags")
  valid_21626981 = validateParameter(valid_21626981, JArray, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "Tags", valid_21626981
  var valid_21626982 = formData.getOrDefault("ThresholdMetricId")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "ThresholdMetricId", valid_21626982
  var valid_21626983 = formData.getOrDefault("OKActions")
  valid_21626983 = validateParameter(valid_21626983, JArray, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "OKActions", valid_21626983
  var valid_21626984 = formData.getOrDefault("Statistic")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = newJString("SampleCount"))
  if valid_21626984 != nil:
    section.add "Statistic", valid_21626984
  var valid_21626985 = formData.getOrDefault("EvaluationPeriods")
  valid_21626985 = validateParameter(valid_21626985, JInt, required = true,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "EvaluationPeriods", valid_21626985
  var valid_21626986 = formData.getOrDefault("DatapointsToAlarm")
  valid_21626986 = validateParameter(valid_21626986, JInt, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "DatapointsToAlarm", valid_21626986
  var valid_21626987 = formData.getOrDefault("AlarmName")
  valid_21626987 = validateParameter(valid_21626987, JString, required = true,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "AlarmName", valid_21626987
  var valid_21626988 = formData.getOrDefault("Namespace")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "Namespace", valid_21626988
  var valid_21626989 = formData.getOrDefault("InsufficientDataActions")
  valid_21626989 = validateParameter(valid_21626989, JArray, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "InsufficientDataActions", valid_21626989
  var valid_21626990 = formData.getOrDefault("AlarmActions")
  valid_21626990 = validateParameter(valid_21626990, JArray, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "AlarmActions", valid_21626990
  var valid_21626991 = formData.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_21626991
  var valid_21626992 = formData.getOrDefault("Unit")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = newJString("Seconds"))
  if valid_21626992 != nil:
    section.add "Unit", valid_21626992
  var valid_21626993 = formData.getOrDefault("Period")
  valid_21626993 = validateParameter(valid_21626993, JInt, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "Period", valid_21626993
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626994: Call_PostPutMetricAlarm_21626960; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_21626994.validator(path, query, header, formData, body, _)
  let scheme = call_21626994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626994.makeUrl(scheme.get, call_21626994.host, call_21626994.base,
                               call_21626994.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626994, uri, valid, _)

proc call*(call_21626995: Call_PostPutMetricAlarm_21626960; EvaluationPeriods: int;
          AlarmName: string; ActionsEnabled: bool = false; Threshold: float = 0.0;
          ExtendedStatistic: string = ""; Metrics: JsonNode = nil;
          MetricName: string = ""; TreatMissingData: string = "";
          AlarmDescription: string = ""; Dimensions: JsonNode = nil;
          ComparisonOperator: string = "GreaterThanOrEqualToThreshold";
          Tags: JsonNode = nil; ThresholdMetricId: string = "";
          Action: string = "PutMetricAlarm"; OKActions: JsonNode = nil;
          Statistic: string = "SampleCount"; DatapointsToAlarm: int = 0;
          Namespace: string = ""; InsufficientDataActions: JsonNode = nil;
          AlarmActions: JsonNode = nil;
          EvaluateLowSampleCountPercentile: string = ""; Unit: string = "Seconds";
          Version: string = "2010-08-01"; Period: int = 0): Recallable =
  ## postPutMetricAlarm
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ##   ActionsEnabled: bool
  ##                 : Indicates whether actions should be executed during any changes to the alarm state. The default is <code>TRUE</code>.
  ##   Threshold: float
  ##            : <p>The value against which the specified statistic is compared.</p> <p>This parameter is required for alarms based on static thresholds, but should not be used for alarms based on anomaly detection models.</p>
  ##   ExtendedStatistic: string
  ##                    : The percentile statistic for the metric specified in <code>MetricName</code>. Specify a value between p0.0 and p100. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   Metrics: JArray
  ##          : <p>An array of <code>MetricDataQuery</code> structures that enable you to create an alarm based on the result of a metric math expression. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>Each item in the <code>Metrics</code> array either retrieves a metric or performs a math expression.</p> <p>One item in the <code>Metrics</code> array is the expression that the alarm watches. You designate this expression by setting <code>ReturnValue</code> to true for this object in the array. For more information, see <a>MetricDataQuery</a>.</p> <p>If you use the <code>Metrics</code> parameter, you cannot include the <code>MetricName</code>, <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters of <code>PutMetricAlarm</code> in the same operation. Instead, you retrieve the metrics you are using in your math expression as part of the <code>Metrics</code> array.</p>
  ##   MetricName: string
  ##             : <p>The name for the metric associated with the alarm. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>If you are creating an alarm based on a math expression, you cannot specify this parameter, or any of the <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters. Instead, you specify all this information in the <code>Metrics</code> array.</p>
  ##   TreatMissingData: string
  ##                   : <p> Sets how this alarm is to handle missing data points. If <code>TreatMissingData</code> is omitted, the default behavior of <code>missing</code> is used. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarms-and-missing-data">Configuring How CloudWatch Alarms Treats Missing Data</a>.</p> <p>Valid Values: <code>breaching | notBreaching | ignore | missing</code> </p>
  ##   AlarmDescription: string
  ##                   : The description for the alarm.
  ##   Dimensions: JArray
  ##             : The dimensions for the metric specified in <code>MetricName</code>.
  ##   ComparisonOperator: string (required)
  ##                     : <p> The arithmetic operation to use when comparing the specified statistic and threshold. The specified statistic value is used as the first operand.</p> <p>The values <code>LessThanLowerOrGreaterThanUpperThreshold</code>, <code>LessThanLowerThreshold</code>, and <code>GreaterThanUpperThreshold</code> are used only for alarms based on anomaly detection models.</p>
  ##   Tags: JArray
  ##       : <p>A list of key-value pairs to associate with the alarm. You can associate as many as 50 tags with an alarm.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p>
  ##   ThresholdMetricId: string
  ##                    : <p>If this is an alarm based on an anomaly detection model, make this value match the ID of the <code>ANOMALY_DETECTION_BAND</code> function.</p> <p>For an example of how to use this parameter, see the <b>Anomaly Detection Model Alarm</b> example on this page.</p> <p>If your alarm uses this parameter, it cannot have Auto Scaling actions.</p>
  ##   Action: string (required)
  ##   OKActions: JArray
  ##            : <p>The actions to execute when this alarm transitions to an <code>OK</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Statistic: string
  ##            : The statistic for the metric specified in <code>MetricName</code>, other than percentile. For percentile statistics, use <code>ExtendedStatistic</code>. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   EvaluationPeriods: int (required)
  ##                    : <p>The number of periods over which data is compared to the specified threshold. If you are setting an alarm that requires that a number of consecutive data points be breaching to trigger the alarm, this value specifies that number. If you are setting an "M out of N" alarm, this value is the N.</p> <p>An alarm's total current evaluation period can be no longer than one day, so this number multiplied by <code>Period</code> cannot be more than 86,400 seconds.</p>
  ##   DatapointsToAlarm: int
  ##                    : The number of data points that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarm-evaluation">Evaluating an Alarm</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   AlarmName: string (required)
  ##            : The name for the alarm. This name must be unique within your AWS account.
  ##   Namespace: string
  ##            : The namespace for the metric associated specified in <code>MetricName</code>.
  ##   InsufficientDataActions: JArray
  ##                          : <p>The actions to execute when this alarm transitions to the <code>INSUFFICIENT_DATA</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>&gt;arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   AlarmActions: JArray
  ##               : <p>The actions to execute when this alarm transitions to the <code>ALARM</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   EvaluateLowSampleCountPercentile: string
  ##                                   : <p> Used only for alarms based on percentiles. If you specify <code>ignore</code>, the alarm state does not change during periods with too few data points to be statistically significant. If you specify <code>evaluate</code> or omit this parameter, the alarm is always evaluated and possibly changes state no matter how many data points are available. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#percentiles-with-low-samples">Percentile-Based CloudWatch Alarms and Low Data Samples</a>.</p> <p>Valid Values: <code>evaluate | ignore</code> </p>
  ##   Unit: string
  ##       : <p>The unit of measure for the statistic. For example, the units for the Amazon EC2 NetworkIn metric are Bytes because NetworkIn tracks the number of bytes that an instance receives on all network interfaces. You can also specify a unit when you create a custom metric. Units help provide conceptual meaning to your data. Metric data points that specify a unit of measure, such as Percent, are aggregated separately.</p> <p>If you don't specify <code>Unit</code>, CloudWatch retrieves all unit types that have been published for the metric and attempts to evaluate the alarm. Usually metrics are published with only one unit, so the alarm will work as intended.</p> <p>However, if the metric is published with multiple types of units and you don't specify a unit, the alarm's behavior is not defined and will behave un-predictably.</p> <p>We recommend omitting <code>Unit</code> so that you don't inadvertently specify an incorrect unit that is not published for this metric. Doing so causes the alarm to be stuck in the <code>INSUFFICIENT DATA</code> state.</p>
  ##   Version: string (required)
  ##   Period: int
  ##         : <p>The length, in seconds, used each time the metric specified in <code>MetricName</code> is evaluated. Valid values are 10, 30, and any multiple of 60.</p> <p> <code>Period</code> is required for alarms based on static thresholds. If you are creating an alarm based on a metric math expression, you specify the period for each metric within the objects in the <code>Metrics</code> array.</p> <p>Be sure to specify 10 or 30 only for metrics that are stored by a <code>PutMetricData</code> call with a <code>StorageResolution</code> of 1. If you specify a period of 10 or 30 for a metric that does not have sub-minute resolution, the alarm still attempts to gather data at the period rate that you specify. In this case, it does not receive data for the attempts that do not correspond to a one-minute data resolution, and the alarm may often lapse into INSUFFICENT_DATA status. Specifying 10 or 30 also sets this alarm as a high-resolution alarm, which has a higher charge than other alarms. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>An alarm's total current evaluation period can be no longer than one day, so <code>Period</code> multiplied by <code>EvaluationPeriods</code> cannot be more than 86,400 seconds.</p>
  var query_21626996 = newJObject()
  var formData_21626997 = newJObject()
  add(formData_21626997, "ActionsEnabled", newJBool(ActionsEnabled))
  add(formData_21626997, "Threshold", newJFloat(Threshold))
  add(formData_21626997, "ExtendedStatistic", newJString(ExtendedStatistic))
  if Metrics != nil:
    formData_21626997.add "Metrics", Metrics
  add(formData_21626997, "MetricName", newJString(MetricName))
  add(formData_21626997, "TreatMissingData", newJString(TreatMissingData))
  add(formData_21626997, "AlarmDescription", newJString(AlarmDescription))
  if Dimensions != nil:
    formData_21626997.add "Dimensions", Dimensions
  add(formData_21626997, "ComparisonOperator", newJString(ComparisonOperator))
  if Tags != nil:
    formData_21626997.add "Tags", Tags
  add(formData_21626997, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_21626996, "Action", newJString(Action))
  if OKActions != nil:
    formData_21626997.add "OKActions", OKActions
  add(formData_21626997, "Statistic", newJString(Statistic))
  add(formData_21626997, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(formData_21626997, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(formData_21626997, "AlarmName", newJString(AlarmName))
  add(formData_21626997, "Namespace", newJString(Namespace))
  if InsufficientDataActions != nil:
    formData_21626997.add "InsufficientDataActions", InsufficientDataActions
  if AlarmActions != nil:
    formData_21626997.add "AlarmActions", AlarmActions
  add(formData_21626997, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  add(formData_21626997, "Unit", newJString(Unit))
  add(query_21626996, "Version", newJString(Version))
  add(formData_21626997, "Period", newJInt(Period))
  result = call_21626995.call(nil, query_21626996, nil, formData_21626997, nil)

var postPutMetricAlarm* = Call_PostPutMetricAlarm_21626960(
    name: "postPutMetricAlarm", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutMetricAlarm",
    validator: validate_PostPutMetricAlarm_21626961, base: "/",
    makeUrl: url_PostPutMetricAlarm_21626962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricAlarm_21626923 = ref object of OpenApiRestCall_21625435
proc url_GetPutMetricAlarm_21626925(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutMetricAlarm_21626924(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString
  ##            : The namespace for the metric associated specified in <code>MetricName</code>.
  ##   DatapointsToAlarm: JInt
  ##                    : The number of data points that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarm-evaluation">Evaluating an Alarm</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   AlarmName: JString (required)
  ##            : The name for the alarm. This name must be unique within your AWS account.
  ##   Unit: JString
  ##       : <p>The unit of measure for the statistic. For example, the units for the Amazon EC2 NetworkIn metric are Bytes because NetworkIn tracks the number of bytes that an instance receives on all network interfaces. You can also specify a unit when you create a custom metric. Units help provide conceptual meaning to your data. Metric data points that specify a unit of measure, such as Percent, are aggregated separately.</p> <p>If you don't specify <code>Unit</code>, CloudWatch retrieves all unit types that have been published for the metric and attempts to evaluate the alarm. Usually metrics are published with only one unit, so the alarm will work as intended.</p> <p>However, if the metric is published with multiple types of units and you don't specify a unit, the alarm's behavior is not defined and will behave un-predictably.</p> <p>We recommend omitting <code>Unit</code> so that you don't inadvertently specify an incorrect unit that is not published for this metric. Doing so causes the alarm to be stuck in the <code>INSUFFICIENT DATA</code> state.</p>
  ##   Threshold: JFloat
  ##            : <p>The value against which the specified statistic is compared.</p> <p>This parameter is required for alarms based on static thresholds, but should not be used for alarms based on anomaly detection models.</p>
  ##   ExtendedStatistic: JString
  ##                    : The percentile statistic for the metric specified in <code>MetricName</code>. Specify a value between p0.0 and p100. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   TreatMissingData: JString
  ##                   : <p> Sets how this alarm is to handle missing data points. If <code>TreatMissingData</code> is omitted, the default behavior of <code>missing</code> is used. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarms-and-missing-data">Configuring How CloudWatch Alarms Treats Missing Data</a>.</p> <p>Valid Values: <code>breaching | notBreaching | ignore | missing</code> </p>
  ##   Dimensions: JArray
  ##             : The dimensions for the metric specified in <code>MetricName</code>.
  ##   Tags: JArray
  ##       : <p>A list of key-value pairs to associate with the alarm. You can associate as many as 50 tags with an alarm.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p>
  ##   Action: JString (required)
  ##   EvaluationPeriods: JInt (required)
  ##                    : <p>The number of periods over which data is compared to the specified threshold. If you are setting an alarm that requires that a number of consecutive data points be breaching to trigger the alarm, this value specifies that number. If you are setting an "M out of N" alarm, this value is the N.</p> <p>An alarm's total current evaluation period can be no longer than one day, so this number multiplied by <code>Period</code> cannot be more than 86,400 seconds.</p>
  ##   ActionsEnabled: JBool
  ##                 : Indicates whether actions should be executed during any changes to the alarm state. The default is <code>TRUE</code>.
  ##   ComparisonOperator: JString (required)
  ##                     : <p> The arithmetic operation to use when comparing the specified statistic and threshold. The specified statistic value is used as the first operand.</p> <p>The values <code>LessThanLowerOrGreaterThanUpperThreshold</code>, <code>LessThanLowerThreshold</code>, and <code>GreaterThanUpperThreshold</code> are used only for alarms based on anomaly detection models.</p>
  ##   EvaluateLowSampleCountPercentile: JString
  ##                                   : <p> Used only for alarms based on percentiles. If you specify <code>ignore</code>, the alarm state does not change during periods with too few data points to be statistically significant. If you specify <code>evaluate</code> or omit this parameter, the alarm is always evaluated and possibly changes state no matter how many data points are available. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#percentiles-with-low-samples">Percentile-Based CloudWatch Alarms and Low Data Samples</a>.</p> <p>Valid Values: <code>evaluate | ignore</code> </p>
  ##   Metrics: JArray
  ##          : <p>An array of <code>MetricDataQuery</code> structures that enable you to create an alarm based on the result of a metric math expression. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>Each item in the <code>Metrics</code> array either retrieves a metric or performs a math expression.</p> <p>One item in the <code>Metrics</code> array is the expression that the alarm watches. You designate this expression by setting <code>ReturnValue</code> to true for this object in the array. For more information, see <a>MetricDataQuery</a>.</p> <p>If you use the <code>Metrics</code> parameter, you cannot include the <code>MetricName</code>, <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters of <code>PutMetricAlarm</code> in the same operation. Instead, you retrieve the metrics you are using in your math expression as part of the <code>Metrics</code> array.</p>
  ##   InsufficientDataActions: JArray
  ##                          : <p>The actions to execute when this alarm transitions to the <code>INSUFFICIENT_DATA</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>&gt;arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   AlarmDescription: JString
  ##                   : The description for the alarm.
  ##   AlarmActions: JArray
  ##               : <p>The actions to execute when this alarm transitions to the <code>ALARM</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Period: JInt
  ##         : <p>The length, in seconds, used each time the metric specified in <code>MetricName</code> is evaluated. Valid values are 10, 30, and any multiple of 60.</p> <p> <code>Period</code> is required for alarms based on static thresholds. If you are creating an alarm based on a metric math expression, you specify the period for each metric within the objects in the <code>Metrics</code> array.</p> <p>Be sure to specify 10 or 30 only for metrics that are stored by a <code>PutMetricData</code> call with a <code>StorageResolution</code> of 1. If you specify a period of 10 or 30 for a metric that does not have sub-minute resolution, the alarm still attempts to gather data at the period rate that you specify. In this case, it does not receive data for the attempts that do not correspond to a one-minute data resolution, and the alarm may often lapse into INSUFFICENT_DATA status. Specifying 10 or 30 also sets this alarm as a high-resolution alarm, which has a higher charge than other alarms. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>An alarm's total current evaluation period can be no longer than one day, so <code>Period</code> multiplied by <code>EvaluationPeriods</code> cannot be more than 86,400 seconds.</p>
  ##   MetricName: JString
  ##             : <p>The name for the metric associated with the alarm. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>If you are creating an alarm based on a math expression, you cannot specify this parameter, or any of the <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters. Instead, you specify all this information in the <code>Metrics</code> array.</p>
  ##   Statistic: JString
  ##            : The statistic for the metric specified in <code>MetricName</code>, other than percentile. For percentile statistics, use <code>ExtendedStatistic</code>. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   ThresholdMetricId: JString
  ##                    : <p>If this is an alarm based on an anomaly detection model, make this value match the ID of the <code>ANOMALY_DETECTION_BAND</code> function.</p> <p>For an example of how to use this parameter, see the <b>Anomaly Detection Model Alarm</b> example on this page.</p> <p>If your alarm uses this parameter, it cannot have Auto Scaling actions.</p>
  ##   Version: JString (required)
  ##   OKActions: JArray
  ##            : <p>The actions to execute when this alarm transitions to an <code>OK</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  section = newJObject()
  var valid_21626926 = query.getOrDefault("Namespace")
  valid_21626926 = validateParameter(valid_21626926, JString, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "Namespace", valid_21626926
  var valid_21626927 = query.getOrDefault("DatapointsToAlarm")
  valid_21626927 = validateParameter(valid_21626927, JInt, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "DatapointsToAlarm", valid_21626927
  assert query != nil,
        "query argument is necessary due to required `AlarmName` field"
  var valid_21626928 = query.getOrDefault("AlarmName")
  valid_21626928 = validateParameter(valid_21626928, JString, required = true,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "AlarmName", valid_21626928
  var valid_21626929 = query.getOrDefault("Unit")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = newJString("Seconds"))
  if valid_21626929 != nil:
    section.add "Unit", valid_21626929
  var valid_21626930 = query.getOrDefault("Threshold")
  valid_21626930 = validateParameter(valid_21626930, JFloat, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "Threshold", valid_21626930
  var valid_21626931 = query.getOrDefault("ExtendedStatistic")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "ExtendedStatistic", valid_21626931
  var valid_21626932 = query.getOrDefault("TreatMissingData")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "TreatMissingData", valid_21626932
  var valid_21626933 = query.getOrDefault("Dimensions")
  valid_21626933 = validateParameter(valid_21626933, JArray, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "Dimensions", valid_21626933
  var valid_21626934 = query.getOrDefault("Tags")
  valid_21626934 = validateParameter(valid_21626934, JArray, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "Tags", valid_21626934
  var valid_21626935 = query.getOrDefault("Action")
  valid_21626935 = validateParameter(valid_21626935, JString, required = true,
                                   default = newJString("PutMetricAlarm"))
  if valid_21626935 != nil:
    section.add "Action", valid_21626935
  var valid_21626936 = query.getOrDefault("EvaluationPeriods")
  valid_21626936 = validateParameter(valid_21626936, JInt, required = true,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "EvaluationPeriods", valid_21626936
  var valid_21626937 = query.getOrDefault("ActionsEnabled")
  valid_21626937 = validateParameter(valid_21626937, JBool, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "ActionsEnabled", valid_21626937
  var valid_21626938 = query.getOrDefault("ComparisonOperator")
  valid_21626938 = validateParameter(valid_21626938, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_21626938 != nil:
    section.add "ComparisonOperator", valid_21626938
  var valid_21626939 = query.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_21626939 = validateParameter(valid_21626939, JString, required = false,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_21626939
  var valid_21626940 = query.getOrDefault("Metrics")
  valid_21626940 = validateParameter(valid_21626940, JArray, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "Metrics", valid_21626940
  var valid_21626941 = query.getOrDefault("InsufficientDataActions")
  valid_21626941 = validateParameter(valid_21626941, JArray, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "InsufficientDataActions", valid_21626941
  var valid_21626942 = query.getOrDefault("AlarmDescription")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "AlarmDescription", valid_21626942
  var valid_21626943 = query.getOrDefault("AlarmActions")
  valid_21626943 = validateParameter(valid_21626943, JArray, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "AlarmActions", valid_21626943
  var valid_21626944 = query.getOrDefault("Period")
  valid_21626944 = validateParameter(valid_21626944, JInt, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "Period", valid_21626944
  var valid_21626945 = query.getOrDefault("MetricName")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "MetricName", valid_21626945
  var valid_21626946 = query.getOrDefault("Statistic")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = newJString("SampleCount"))
  if valid_21626946 != nil:
    section.add "Statistic", valid_21626946
  var valid_21626947 = query.getOrDefault("ThresholdMetricId")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "ThresholdMetricId", valid_21626947
  var valid_21626948 = query.getOrDefault("Version")
  valid_21626948 = validateParameter(valid_21626948, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21626948 != nil:
    section.add "Version", valid_21626948
  var valid_21626949 = query.getOrDefault("OKActions")
  valid_21626949 = validateParameter(valid_21626949, JArray, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "OKActions", valid_21626949
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626950 = header.getOrDefault("X-Amz-Date")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Date", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Security-Token", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "X-Amz-Algorithm", valid_21626953
  var valid_21626954 = header.getOrDefault("X-Amz-Signature")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Signature", valid_21626954
  var valid_21626955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626955
  var valid_21626956 = header.getOrDefault("X-Amz-Credential")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "X-Amz-Credential", valid_21626956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626957: Call_GetPutMetricAlarm_21626923; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_21626957.validator(path, query, header, formData, body, _)
  let scheme = call_21626957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626957.makeUrl(scheme.get, call_21626957.host, call_21626957.base,
                               call_21626957.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626957, uri, valid, _)

proc call*(call_21626958: Call_GetPutMetricAlarm_21626923; AlarmName: string;
          EvaluationPeriods: int; Namespace: string = ""; DatapointsToAlarm: int = 0;
          Unit: string = "Seconds"; Threshold: float = 0.0;
          ExtendedStatistic: string = ""; TreatMissingData: string = "";
          Dimensions: JsonNode = nil; Tags: JsonNode = nil;
          Action: string = "PutMetricAlarm"; ActionsEnabled: bool = false;
          ComparisonOperator: string = "GreaterThanOrEqualToThreshold";
          EvaluateLowSampleCountPercentile: string = ""; Metrics: JsonNode = nil;
          InsufficientDataActions: JsonNode = nil; AlarmDescription: string = "";
          AlarmActions: JsonNode = nil; Period: int = 0; MetricName: string = "";
          Statistic: string = "SampleCount"; ThresholdMetricId: string = "";
          Version: string = "2010-08-01"; OKActions: JsonNode = nil): Recallable =
  ## getPutMetricAlarm
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ##   Namespace: string
  ##            : The namespace for the metric associated specified in <code>MetricName</code>.
  ##   DatapointsToAlarm: int
  ##                    : The number of data points that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarm-evaluation">Evaluating an Alarm</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   AlarmName: string (required)
  ##            : The name for the alarm. This name must be unique within your AWS account.
  ##   Unit: string
  ##       : <p>The unit of measure for the statistic. For example, the units for the Amazon EC2 NetworkIn metric are Bytes because NetworkIn tracks the number of bytes that an instance receives on all network interfaces. You can also specify a unit when you create a custom metric. Units help provide conceptual meaning to your data. Metric data points that specify a unit of measure, such as Percent, are aggregated separately.</p> <p>If you don't specify <code>Unit</code>, CloudWatch retrieves all unit types that have been published for the metric and attempts to evaluate the alarm. Usually metrics are published with only one unit, so the alarm will work as intended.</p> <p>However, if the metric is published with multiple types of units and you don't specify a unit, the alarm's behavior is not defined and will behave un-predictably.</p> <p>We recommend omitting <code>Unit</code> so that you don't inadvertently specify an incorrect unit that is not published for this metric. Doing so causes the alarm to be stuck in the <code>INSUFFICIENT DATA</code> state.</p>
  ##   Threshold: float
  ##            : <p>The value against which the specified statistic is compared.</p> <p>This parameter is required for alarms based on static thresholds, but should not be used for alarms based on anomaly detection models.</p>
  ##   ExtendedStatistic: string
  ##                    : The percentile statistic for the metric specified in <code>MetricName</code>. Specify a value between p0.0 and p100. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   TreatMissingData: string
  ##                   : <p> Sets how this alarm is to handle missing data points. If <code>TreatMissingData</code> is omitted, the default behavior of <code>missing</code> is used. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarms-and-missing-data">Configuring How CloudWatch Alarms Treats Missing Data</a>.</p> <p>Valid Values: <code>breaching | notBreaching | ignore | missing</code> </p>
  ##   Dimensions: JArray
  ##             : The dimensions for the metric specified in <code>MetricName</code>.
  ##   Tags: JArray
  ##       : <p>A list of key-value pairs to associate with the alarm. You can associate as many as 50 tags with an alarm.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p>
  ##   Action: string (required)
  ##   EvaluationPeriods: int (required)
  ##                    : <p>The number of periods over which data is compared to the specified threshold. If you are setting an alarm that requires that a number of consecutive data points be breaching to trigger the alarm, this value specifies that number. If you are setting an "M out of N" alarm, this value is the N.</p> <p>An alarm's total current evaluation period can be no longer than one day, so this number multiplied by <code>Period</code> cannot be more than 86,400 seconds.</p>
  ##   ActionsEnabled: bool
  ##                 : Indicates whether actions should be executed during any changes to the alarm state. The default is <code>TRUE</code>.
  ##   ComparisonOperator: string (required)
  ##                     : <p> The arithmetic operation to use when comparing the specified statistic and threshold. The specified statistic value is used as the first operand.</p> <p>The values <code>LessThanLowerOrGreaterThanUpperThreshold</code>, <code>LessThanLowerThreshold</code>, and <code>GreaterThanUpperThreshold</code> are used only for alarms based on anomaly detection models.</p>
  ##   EvaluateLowSampleCountPercentile: string
  ##                                   : <p> Used only for alarms based on percentiles. If you specify <code>ignore</code>, the alarm state does not change during periods with too few data points to be statistically significant. If you specify <code>evaluate</code> or omit this parameter, the alarm is always evaluated and possibly changes state no matter how many data points are available. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#percentiles-with-low-samples">Percentile-Based CloudWatch Alarms and Low Data Samples</a>.</p> <p>Valid Values: <code>evaluate | ignore</code> </p>
  ##   Metrics: JArray
  ##          : <p>An array of <code>MetricDataQuery</code> structures that enable you to create an alarm based on the result of a metric math expression. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>Each item in the <code>Metrics</code> array either retrieves a metric or performs a math expression.</p> <p>One item in the <code>Metrics</code> array is the expression that the alarm watches. You designate this expression by setting <code>ReturnValue</code> to true for this object in the array. For more information, see <a>MetricDataQuery</a>.</p> <p>If you use the <code>Metrics</code> parameter, you cannot include the <code>MetricName</code>, <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters of <code>PutMetricAlarm</code> in the same operation. Instead, you retrieve the metrics you are using in your math expression as part of the <code>Metrics</code> array.</p>
  ##   InsufficientDataActions: JArray
  ##                          : <p>The actions to execute when this alarm transitions to the <code>INSUFFICIENT_DATA</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>&gt;arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   AlarmDescription: string
  ##                   : The description for the alarm.
  ##   AlarmActions: JArray
  ##               : <p>The actions to execute when this alarm transitions to the <code>ALARM</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Period: int
  ##         : <p>The length, in seconds, used each time the metric specified in <code>MetricName</code> is evaluated. Valid values are 10, 30, and any multiple of 60.</p> <p> <code>Period</code> is required for alarms based on static thresholds. If you are creating an alarm based on a metric math expression, you specify the period for each metric within the objects in the <code>Metrics</code> array.</p> <p>Be sure to specify 10 or 30 only for metrics that are stored by a <code>PutMetricData</code> call with a <code>StorageResolution</code> of 1. If you specify a period of 10 or 30 for a metric that does not have sub-minute resolution, the alarm still attempts to gather data at the period rate that you specify. In this case, it does not receive data for the attempts that do not correspond to a one-minute data resolution, and the alarm may often lapse into INSUFFICENT_DATA status. Specifying 10 or 30 also sets this alarm as a high-resolution alarm, which has a higher charge than other alarms. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>An alarm's total current evaluation period can be no longer than one day, so <code>Period</code> multiplied by <code>EvaluationPeriods</code> cannot be more than 86,400 seconds.</p>
  ##   MetricName: string
  ##             : <p>The name for the metric associated with the alarm. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>If you are creating an alarm based on a math expression, you cannot specify this parameter, or any of the <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters. Instead, you specify all this information in the <code>Metrics</code> array.</p>
  ##   Statistic: string
  ##            : The statistic for the metric specified in <code>MetricName</code>, other than percentile. For percentile statistics, use <code>ExtendedStatistic</code>. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   ThresholdMetricId: string
  ##                    : <p>If this is an alarm based on an anomaly detection model, make this value match the ID of the <code>ANOMALY_DETECTION_BAND</code> function.</p> <p>For an example of how to use this parameter, see the <b>Anomaly Detection Model Alarm</b> example on this page.</p> <p>If your alarm uses this parameter, it cannot have Auto Scaling actions.</p>
  ##   Version: string (required)
  ##   OKActions: JArray
  ##            : <p>The actions to execute when this alarm transitions to an <code>OK</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  var query_21626959 = newJObject()
  add(query_21626959, "Namespace", newJString(Namespace))
  add(query_21626959, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(query_21626959, "AlarmName", newJString(AlarmName))
  add(query_21626959, "Unit", newJString(Unit))
  add(query_21626959, "Threshold", newJFloat(Threshold))
  add(query_21626959, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_21626959, "TreatMissingData", newJString(TreatMissingData))
  if Dimensions != nil:
    query_21626959.add "Dimensions", Dimensions
  if Tags != nil:
    query_21626959.add "Tags", Tags
  add(query_21626959, "Action", newJString(Action))
  add(query_21626959, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(query_21626959, "ActionsEnabled", newJBool(ActionsEnabled))
  add(query_21626959, "ComparisonOperator", newJString(ComparisonOperator))
  add(query_21626959, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  if Metrics != nil:
    query_21626959.add "Metrics", Metrics
  if InsufficientDataActions != nil:
    query_21626959.add "InsufficientDataActions", InsufficientDataActions
  add(query_21626959, "AlarmDescription", newJString(AlarmDescription))
  if AlarmActions != nil:
    query_21626959.add "AlarmActions", AlarmActions
  add(query_21626959, "Period", newJInt(Period))
  add(query_21626959, "MetricName", newJString(MetricName))
  add(query_21626959, "Statistic", newJString(Statistic))
  add(query_21626959, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_21626959, "Version", newJString(Version))
  if OKActions != nil:
    query_21626959.add "OKActions", OKActions
  result = call_21626958.call(nil, query_21626959, nil, nil, nil)

var getPutMetricAlarm* = Call_GetPutMetricAlarm_21626923(name: "getPutMetricAlarm",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricAlarm", validator: validate_GetPutMetricAlarm_21626924,
    base: "/", makeUrl: url_GetPutMetricAlarm_21626925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricData_21627015 = ref object of OpenApiRestCall_21625435
proc url_PostPutMetricData_21627017(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutMetricData_21627016(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627018 = query.getOrDefault("Action")
  valid_21627018 = validateParameter(valid_21627018, JString, required = true,
                                   default = newJString("PutMetricData"))
  if valid_21627018 != nil:
    section.add "Action", valid_21627018
  var valid_21627019 = query.getOrDefault("Version")
  valid_21627019 = validateParameter(valid_21627019, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21627019 != nil:
    section.add "Version", valid_21627019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627020 = header.getOrDefault("X-Amz-Date")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Date", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-Security-Token", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Algorithm", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-Signature")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-Signature", valid_21627024
  var valid_21627025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627025
  var valid_21627026 = header.getOrDefault("X-Amz-Credential")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Credential", valid_21627026
  result.add "header", section
  ## parameters in `formData` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Namespace` field"
  var valid_21627027 = formData.getOrDefault("Namespace")
  valid_21627027 = validateParameter(valid_21627027, JString, required = true,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "Namespace", valid_21627027
  var valid_21627028 = formData.getOrDefault("MetricData")
  valid_21627028 = validateParameter(valid_21627028, JArray, required = true,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "MetricData", valid_21627028
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627029: Call_PostPutMetricData_21627015; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_21627029.validator(path, query, header, formData, body, _)
  let scheme = call_21627029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627029.makeUrl(scheme.get, call_21627029.host, call_21627029.base,
                               call_21627029.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627029, uri, valid, _)

proc call*(call_21627030: Call_PostPutMetricData_21627015; Namespace: string;
          MetricData: JsonNode; Action: string = "PutMetricData";
          Version: string = "2010-08-01"): Recallable =
  ## postPutMetricData
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Namespace: string (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  ##   Version: string (required)
  var query_21627031 = newJObject()
  var formData_21627032 = newJObject()
  add(query_21627031, "Action", newJString(Action))
  add(formData_21627032, "Namespace", newJString(Namespace))
  if MetricData != nil:
    formData_21627032.add "MetricData", MetricData
  add(query_21627031, "Version", newJString(Version))
  result = call_21627030.call(nil, query_21627031, nil, formData_21627032, nil)

var postPutMetricData* = Call_PostPutMetricData_21627015(name: "postPutMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_PostPutMetricData_21627016,
    base: "/", makeUrl: url_PostPutMetricData_21627017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricData_21626998 = ref object of OpenApiRestCall_21625435
proc url_GetPutMetricData_21627000(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutMetricData_21626999(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_21627001 = query.getOrDefault("Namespace")
  valid_21627001 = validateParameter(valid_21627001, JString, required = true,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "Namespace", valid_21627001
  var valid_21627002 = query.getOrDefault("MetricData")
  valid_21627002 = validateParameter(valid_21627002, JArray, required = true,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "MetricData", valid_21627002
  var valid_21627003 = query.getOrDefault("Action")
  valid_21627003 = validateParameter(valid_21627003, JString, required = true,
                                   default = newJString("PutMetricData"))
  if valid_21627003 != nil:
    section.add "Action", valid_21627003
  var valid_21627004 = query.getOrDefault("Version")
  valid_21627004 = validateParameter(valid_21627004, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21627004 != nil:
    section.add "Version", valid_21627004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627005 = header.getOrDefault("X-Amz-Date")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "X-Amz-Date", valid_21627005
  var valid_21627006 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627006 = validateParameter(valid_21627006, JString, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "X-Amz-Security-Token", valid_21627006
  var valid_21627007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627007 = validateParameter(valid_21627007, JString, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627007
  var valid_21627008 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "X-Amz-Algorithm", valid_21627008
  var valid_21627009 = header.getOrDefault("X-Amz-Signature")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "X-Amz-Signature", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Credential")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Credential", valid_21627011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627012: Call_GetPutMetricData_21626998; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_21627012.validator(path, query, header, formData, body, _)
  let scheme = call_21627012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627012.makeUrl(scheme.get, call_21627012.host, call_21627012.base,
                               call_21627012.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627012, uri, valid, _)

proc call*(call_21627013: Call_GetPutMetricData_21626998; Namespace: string;
          MetricData: JsonNode; Action: string = "PutMetricData";
          Version: string = "2010-08-01"): Recallable =
  ## getPutMetricData
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ##   Namespace: string (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627014 = newJObject()
  add(query_21627014, "Namespace", newJString(Namespace))
  if MetricData != nil:
    query_21627014.add "MetricData", MetricData
  add(query_21627014, "Action", newJString(Action))
  add(query_21627014, "Version", newJString(Version))
  result = call_21627013.call(nil, query_21627014, nil, nil, nil)

var getPutMetricData* = Call_GetPutMetricData_21626998(name: "getPutMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_GetPutMetricData_21626999,
    base: "/", makeUrl: url_GetPutMetricData_21627000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetAlarmState_21627052 = ref object of OpenApiRestCall_21625435
proc url_PostSetAlarmState_21627054(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetAlarmState_21627053(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627055 = query.getOrDefault("Action")
  valid_21627055 = validateParameter(valid_21627055, JString, required = true,
                                   default = newJString("SetAlarmState"))
  if valid_21627055 != nil:
    section.add "Action", valid_21627055
  var valid_21627056 = query.getOrDefault("Version")
  valid_21627056 = validateParameter(valid_21627056, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21627056 != nil:
    section.add "Version", valid_21627056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627057 = header.getOrDefault("X-Amz-Date")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Date", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-Security-Token", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627059
  var valid_21627060 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627060 = validateParameter(valid_21627060, JString, required = false,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "X-Amz-Algorithm", valid_21627060
  var valid_21627061 = header.getOrDefault("X-Amz-Signature")
  valid_21627061 = validateParameter(valid_21627061, JString, required = false,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "X-Amz-Signature", valid_21627061
  var valid_21627062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627062 = validateParameter(valid_21627062, JString, required = false,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627062
  var valid_21627063 = header.getOrDefault("X-Amz-Credential")
  valid_21627063 = validateParameter(valid_21627063, JString, required = false,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "X-Amz-Credential", valid_21627063
  result.add "header", section
  ## parameters in `formData` object:
  ##   StateReasonData: JString
  ##                  : The reason that this alarm is set to this specific state, in JSON format.
  ##   StateReason: JString (required)
  ##              : The reason that this alarm is set to this specific state, in text format.
  ##   StateValue: JString (required)
  ##             : The value of the state.
  ##   AlarmName: JString (required)
  ##            : The name for the alarm. This name must be unique within the AWS account. The maximum length is 255 characters.
  section = newJObject()
  var valid_21627064 = formData.getOrDefault("StateReasonData")
  valid_21627064 = validateParameter(valid_21627064, JString, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "StateReasonData", valid_21627064
  assert formData != nil,
        "formData argument is necessary due to required `StateReason` field"
  var valid_21627065 = formData.getOrDefault("StateReason")
  valid_21627065 = validateParameter(valid_21627065, JString, required = true,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "StateReason", valid_21627065
  var valid_21627066 = formData.getOrDefault("StateValue")
  valid_21627066 = validateParameter(valid_21627066, JString, required = true,
                                   default = newJString("OK"))
  if valid_21627066 != nil:
    section.add "StateValue", valid_21627066
  var valid_21627067 = formData.getOrDefault("AlarmName")
  valid_21627067 = validateParameter(valid_21627067, JString, required = true,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "AlarmName", valid_21627067
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627068: Call_PostSetAlarmState_21627052; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_21627068.validator(path, query, header, formData, body, _)
  let scheme = call_21627068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627068.makeUrl(scheme.get, call_21627068.host, call_21627068.base,
                               call_21627068.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627068, uri, valid, _)

proc call*(call_21627069: Call_PostSetAlarmState_21627052; StateReason: string;
          AlarmName: string; StateReasonData: string = ""; StateValue: string = "OK";
          Action: string = "SetAlarmState"; Version: string = "2010-08-01"): Recallable =
  ## postSetAlarmState
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ##   StateReasonData: string
  ##                  : The reason that this alarm is set to this specific state, in JSON format.
  ##   StateReason: string (required)
  ##              : The reason that this alarm is set to this specific state, in text format.
  ##   StateValue: string (required)
  ##             : The value of the state.
  ##   Action: string (required)
  ##   AlarmName: string (required)
  ##            : The name for the alarm. This name must be unique within the AWS account. The maximum length is 255 characters.
  ##   Version: string (required)
  var query_21627070 = newJObject()
  var formData_21627071 = newJObject()
  add(formData_21627071, "StateReasonData", newJString(StateReasonData))
  add(formData_21627071, "StateReason", newJString(StateReason))
  add(formData_21627071, "StateValue", newJString(StateValue))
  add(query_21627070, "Action", newJString(Action))
  add(formData_21627071, "AlarmName", newJString(AlarmName))
  add(query_21627070, "Version", newJString(Version))
  result = call_21627069.call(nil, query_21627070, nil, formData_21627071, nil)

var postSetAlarmState* = Call_PostSetAlarmState_21627052(name: "postSetAlarmState",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_PostSetAlarmState_21627053,
    base: "/", makeUrl: url_PostSetAlarmState_21627054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetAlarmState_21627033 = ref object of OpenApiRestCall_21625435
proc url_GetSetAlarmState_21627035(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetAlarmState_21627034(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AlarmName: JString (required)
  ##            : The name for the alarm. This name must be unique within the AWS account. The maximum length is 255 characters.
  ##   Action: JString (required)
  ##   StateValue: JString (required)
  ##             : The value of the state.
  ##   StateReasonData: JString
  ##                  : The reason that this alarm is set to this specific state, in JSON format.
  ##   StateReason: JString (required)
  ##              : The reason that this alarm is set to this specific state, in text format.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AlarmName` field"
  var valid_21627036 = query.getOrDefault("AlarmName")
  valid_21627036 = validateParameter(valid_21627036, JString, required = true,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "AlarmName", valid_21627036
  var valid_21627037 = query.getOrDefault("Action")
  valid_21627037 = validateParameter(valid_21627037, JString, required = true,
                                   default = newJString("SetAlarmState"))
  if valid_21627037 != nil:
    section.add "Action", valid_21627037
  var valid_21627038 = query.getOrDefault("StateValue")
  valid_21627038 = validateParameter(valid_21627038, JString, required = true,
                                   default = newJString("OK"))
  if valid_21627038 != nil:
    section.add "StateValue", valid_21627038
  var valid_21627039 = query.getOrDefault("StateReasonData")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "StateReasonData", valid_21627039
  var valid_21627040 = query.getOrDefault("StateReason")
  valid_21627040 = validateParameter(valid_21627040, JString, required = true,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "StateReason", valid_21627040
  var valid_21627041 = query.getOrDefault("Version")
  valid_21627041 = validateParameter(valid_21627041, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21627041 != nil:
    section.add "Version", valid_21627041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627042 = header.getOrDefault("X-Amz-Date")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Date", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "X-Amz-Security-Token", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627044
  var valid_21627045 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "X-Amz-Algorithm", valid_21627045
  var valid_21627046 = header.getOrDefault("X-Amz-Signature")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "X-Amz-Signature", valid_21627046
  var valid_21627047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627047 = validateParameter(valid_21627047, JString, required = false,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627047
  var valid_21627048 = header.getOrDefault("X-Amz-Credential")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "X-Amz-Credential", valid_21627048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627049: Call_GetSetAlarmState_21627033; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_21627049.validator(path, query, header, formData, body, _)
  let scheme = call_21627049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627049.makeUrl(scheme.get, call_21627049.host, call_21627049.base,
                               call_21627049.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627049, uri, valid, _)

proc call*(call_21627050: Call_GetSetAlarmState_21627033; AlarmName: string;
          StateReason: string; Action: string = "SetAlarmState";
          StateValue: string = "OK"; StateReasonData: string = "";
          Version: string = "2010-08-01"): Recallable =
  ## getSetAlarmState
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ##   AlarmName: string (required)
  ##            : The name for the alarm. This name must be unique within the AWS account. The maximum length is 255 characters.
  ##   Action: string (required)
  ##   StateValue: string (required)
  ##             : The value of the state.
  ##   StateReasonData: string
  ##                  : The reason that this alarm is set to this specific state, in JSON format.
  ##   StateReason: string (required)
  ##              : The reason that this alarm is set to this specific state, in text format.
  ##   Version: string (required)
  var query_21627051 = newJObject()
  add(query_21627051, "AlarmName", newJString(AlarmName))
  add(query_21627051, "Action", newJString(Action))
  add(query_21627051, "StateValue", newJString(StateValue))
  add(query_21627051, "StateReasonData", newJString(StateReasonData))
  add(query_21627051, "StateReason", newJString(StateReason))
  add(query_21627051, "Version", newJString(Version))
  result = call_21627050.call(nil, query_21627051, nil, nil, nil)

var getSetAlarmState* = Call_GetSetAlarmState_21627033(name: "getSetAlarmState",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_GetSetAlarmState_21627034,
    base: "/", makeUrl: url_GetSetAlarmState_21627035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_21627089 = ref object of OpenApiRestCall_21625435
proc url_PostTagResource_21627091(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostTagResource_21627090(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627092 = query.getOrDefault("Action")
  valid_21627092 = validateParameter(valid_21627092, JString, required = true,
                                   default = newJString("TagResource"))
  if valid_21627092 != nil:
    section.add "Action", valid_21627092
  var valid_21627093 = query.getOrDefault("Version")
  valid_21627093 = validateParameter(valid_21627093, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21627093 != nil:
    section.add "Version", valid_21627093
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627094 = header.getOrDefault("X-Amz-Date")
  valid_21627094 = validateParameter(valid_21627094, JString, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "X-Amz-Date", valid_21627094
  var valid_21627095 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627095 = validateParameter(valid_21627095, JString, required = false,
                                   default = nil)
  if valid_21627095 != nil:
    section.add "X-Amz-Security-Token", valid_21627095
  var valid_21627096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627096 = validateParameter(valid_21627096, JString, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627096
  var valid_21627097 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627097 = validateParameter(valid_21627097, JString, required = false,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "X-Amz-Algorithm", valid_21627097
  var valid_21627098 = header.getOrDefault("X-Amz-Signature")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "X-Amz-Signature", valid_21627098
  var valid_21627099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627099 = validateParameter(valid_21627099, JString, required = false,
                                   default = nil)
  if valid_21627099 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Credential")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Credential", valid_21627100
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the alarm.
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch alarm that you're adding tags to. The ARN format is 
  ## <code>arn:aws:cloudwatch:<i>Region</i>:<i>account-id</i>:alarm:<i>alarm-name</i> </code> 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_21627101 = formData.getOrDefault("Tags")
  valid_21627101 = validateParameter(valid_21627101, JArray, required = true,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "Tags", valid_21627101
  var valid_21627102 = formData.getOrDefault("ResourceARN")
  valid_21627102 = validateParameter(valid_21627102, JString, required = true,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "ResourceARN", valid_21627102
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627103: Call_PostTagResource_21627089; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_21627103.validator(path, query, header, formData, body, _)
  let scheme = call_21627103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627103.makeUrl(scheme.get, call_21627103.host, call_21627103.base,
                               call_21627103.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627103, uri, valid, _)

proc call*(call_21627104: Call_PostTagResource_21627089; Tags: JsonNode;
          ResourceARN: string; Action: string = "TagResource";
          Version: string = "2010-08-01"): Recallable =
  ## postTagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the alarm.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch alarm that you're adding tags to. The ARN format is 
  ## <code>arn:aws:cloudwatch:<i>Region</i>:<i>account-id</i>:alarm:<i>alarm-name</i> </code> 
  ##   Version: string (required)
  var query_21627105 = newJObject()
  var formData_21627106 = newJObject()
  if Tags != nil:
    formData_21627106.add "Tags", Tags
  add(query_21627105, "Action", newJString(Action))
  add(formData_21627106, "ResourceARN", newJString(ResourceARN))
  add(query_21627105, "Version", newJString(Version))
  result = call_21627104.call(nil, query_21627105, nil, formData_21627106, nil)

var postTagResource* = Call_PostTagResource_21627089(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_21627090,
    base: "/", makeUrl: url_PostTagResource_21627091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_21627072 = ref object of OpenApiRestCall_21625435
proc url_GetTagResource_21627074(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTagResource_21627073(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch alarm that you're adding tags to. The ARN format is 
  ## <code>arn:aws:cloudwatch:<i>Region</i>:<i>account-id</i>:alarm:<i>alarm-name</i> </code> 
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the alarm.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceARN` field"
  var valid_21627075 = query.getOrDefault("ResourceARN")
  valid_21627075 = validateParameter(valid_21627075, JString, required = true,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "ResourceARN", valid_21627075
  var valid_21627076 = query.getOrDefault("Tags")
  valid_21627076 = validateParameter(valid_21627076, JArray, required = true,
                                   default = nil)
  if valid_21627076 != nil:
    section.add "Tags", valid_21627076
  var valid_21627077 = query.getOrDefault("Action")
  valid_21627077 = validateParameter(valid_21627077, JString, required = true,
                                   default = newJString("TagResource"))
  if valid_21627077 != nil:
    section.add "Action", valid_21627077
  var valid_21627078 = query.getOrDefault("Version")
  valid_21627078 = validateParameter(valid_21627078, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21627078 != nil:
    section.add "Version", valid_21627078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627079 = header.getOrDefault("X-Amz-Date")
  valid_21627079 = validateParameter(valid_21627079, JString, required = false,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "X-Amz-Date", valid_21627079
  var valid_21627080 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627080 = validateParameter(valid_21627080, JString, required = false,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "X-Amz-Security-Token", valid_21627080
  var valid_21627081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627081 = validateParameter(valid_21627081, JString, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627081
  var valid_21627082 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "X-Amz-Algorithm", valid_21627082
  var valid_21627083 = header.getOrDefault("X-Amz-Signature")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-Signature", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627084
  var valid_21627085 = header.getOrDefault("X-Amz-Credential")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Credential", valid_21627085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627086: Call_GetTagResource_21627072; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_21627086.validator(path, query, header, formData, body, _)
  let scheme = call_21627086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627086.makeUrl(scheme.get, call_21627086.host, call_21627086.base,
                               call_21627086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627086, uri, valid, _)

proc call*(call_21627087: Call_GetTagResource_21627072; ResourceARN: string;
          Tags: JsonNode; Action: string = "TagResource";
          Version: string = "2010-08-01"): Recallable =
  ## getTagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch alarm that you're adding tags to. The ARN format is 
  ## <code>arn:aws:cloudwatch:<i>Region</i>:<i>account-id</i>:alarm:<i>alarm-name</i> </code> 
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the alarm.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627088 = newJObject()
  add(query_21627088, "ResourceARN", newJString(ResourceARN))
  if Tags != nil:
    query_21627088.add "Tags", Tags
  add(query_21627088, "Action", newJString(Action))
  add(query_21627088, "Version", newJString(Version))
  result = call_21627087.call(nil, query_21627088, nil, nil, nil)

var getTagResource* = Call_GetTagResource_21627072(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_21627073,
    base: "/", makeUrl: url_GetTagResource_21627074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_21627124 = ref object of OpenApiRestCall_21625435
proc url_PostUntagResource_21627126(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUntagResource_21627125(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes one or more tags from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627127 = query.getOrDefault("Action")
  valid_21627127 = validateParameter(valid_21627127, JString, required = true,
                                   default = newJString("UntagResource"))
  if valid_21627127 != nil:
    section.add "Action", valid_21627127
  var valid_21627128 = query.getOrDefault("Version")
  valid_21627128 = validateParameter(valid_21627128, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21627128 != nil:
    section.add "Version", valid_21627128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627129 = header.getOrDefault("X-Amz-Date")
  valid_21627129 = validateParameter(valid_21627129, JString, required = false,
                                   default = nil)
  if valid_21627129 != nil:
    section.add "X-Amz-Date", valid_21627129
  var valid_21627130 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627130 = validateParameter(valid_21627130, JString, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "X-Amz-Security-Token", valid_21627130
  var valid_21627131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627131
  var valid_21627132 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627132 = validateParameter(valid_21627132, JString, required = false,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "X-Amz-Algorithm", valid_21627132
  var valid_21627133 = header.getOrDefault("X-Amz-Signature")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-Signature", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627134
  var valid_21627135 = header.getOrDefault("X-Amz-Credential")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-Credential", valid_21627135
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you're removing tags from. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the resource.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceARN` field"
  var valid_21627136 = formData.getOrDefault("ResourceARN")
  valid_21627136 = validateParameter(valid_21627136, JString, required = true,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "ResourceARN", valid_21627136
  var valid_21627137 = formData.getOrDefault("TagKeys")
  valid_21627137 = validateParameter(valid_21627137, JArray, required = true,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "TagKeys", valid_21627137
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627138: Call_PostUntagResource_21627124; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_21627138.validator(path, query, header, formData, body, _)
  let scheme = call_21627138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627138.makeUrl(scheme.get, call_21627138.host, call_21627138.base,
                               call_21627138.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627138, uri, valid, _)

proc call*(call_21627139: Call_PostUntagResource_21627124; ResourceARN: string;
          TagKeys: JsonNode; Action: string = "UntagResource";
          Version: string = "2010-08-01"): Recallable =
  ## postUntagResource
  ## Removes one or more tags from the specified resource.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you're removing tags from. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the resource.
  ##   Version: string (required)
  var query_21627140 = newJObject()
  var formData_21627141 = newJObject()
  add(query_21627140, "Action", newJString(Action))
  add(formData_21627141, "ResourceARN", newJString(ResourceARN))
  if TagKeys != nil:
    formData_21627141.add "TagKeys", TagKeys
  add(query_21627140, "Version", newJString(Version))
  result = call_21627139.call(nil, query_21627140, nil, formData_21627141, nil)

var postUntagResource* = Call_PostUntagResource_21627124(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_21627125,
    base: "/", makeUrl: url_PostUntagResource_21627126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_21627107 = ref object of OpenApiRestCall_21625435
proc url_GetUntagResource_21627109(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUntagResource_21627108(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes one or more tags from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you're removing tags from. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the resource.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceARN` field"
  var valid_21627110 = query.getOrDefault("ResourceARN")
  valid_21627110 = validateParameter(valid_21627110, JString, required = true,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "ResourceARN", valid_21627110
  var valid_21627111 = query.getOrDefault("Action")
  valid_21627111 = validateParameter(valid_21627111, JString, required = true,
                                   default = newJString("UntagResource"))
  if valid_21627111 != nil:
    section.add "Action", valid_21627111
  var valid_21627112 = query.getOrDefault("TagKeys")
  valid_21627112 = validateParameter(valid_21627112, JArray, required = true,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "TagKeys", valid_21627112
  var valid_21627113 = query.getOrDefault("Version")
  valid_21627113 = validateParameter(valid_21627113, JString, required = true,
                                   default = newJString("2010-08-01"))
  if valid_21627113 != nil:
    section.add "Version", valid_21627113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627114 = header.getOrDefault("X-Amz-Date")
  valid_21627114 = validateParameter(valid_21627114, JString, required = false,
                                   default = nil)
  if valid_21627114 != nil:
    section.add "X-Amz-Date", valid_21627114
  var valid_21627115 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-Security-Token", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Algorithm", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-Signature")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-Signature", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-Credential")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-Credential", valid_21627120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627121: Call_GetUntagResource_21627107; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_21627121.validator(path, query, header, formData, body, _)
  let scheme = call_21627121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627121.makeUrl(scheme.get, call_21627121.host, call_21627121.base,
                               call_21627121.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627121, uri, valid, _)

proc call*(call_21627122: Call_GetUntagResource_21627107; ResourceARN: string;
          TagKeys: JsonNode; Action: string = "UntagResource";
          Version: string = "2010-08-01"): Recallable =
  ## getUntagResource
  ## Removes one or more tags from the specified resource.
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you're removing tags from. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the resource.
  ##   Version: string (required)
  var query_21627123 = newJObject()
  add(query_21627123, "ResourceARN", newJString(ResourceARN))
  add(query_21627123, "Action", newJString(Action))
  if TagKeys != nil:
    query_21627123.add "TagKeys", TagKeys
  add(query_21627123, "Version", newJString(Version))
  result = call_21627122.call(nil, query_21627123, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_21627107(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_21627108,
    base: "/", makeUrl: url_GetUntagResource_21627109,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}