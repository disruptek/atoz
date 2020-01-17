
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostDeleteAlarms_606198 = ref object of OpenApiRestCall_605589
proc url_PostDeleteAlarms_606200(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteAlarms_606199(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606201 = query.getOrDefault("Action")
  valid_606201 = validateParameter(valid_606201, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_606201 != nil:
    section.add "Action", valid_606201
  var valid_606202 = query.getOrDefault("Version")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606202 != nil:
    section.add "Version", valid_606202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606203 = header.getOrDefault("X-Amz-Signature")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Signature", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Content-Sha256", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Date")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Date", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Credential")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Credential", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Security-Token")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Security-Token", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Algorithm")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Algorithm", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-SignedHeaders", valid_606209
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_606210 = formData.getOrDefault("AlarmNames")
  valid_606210 = validateParameter(valid_606210, JArray, required = true, default = nil)
  if valid_606210 != nil:
    section.add "AlarmNames", valid_606210
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606211: Call_PostDeleteAlarms_606198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_606211.validator(path, query, header, formData, body)
  let scheme = call_606211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606211.url(scheme.get, call_606211.host, call_606211.base,
                         call_606211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606211, url, valid)

proc call*(call_606212: Call_PostDeleteAlarms_606198; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  var query_606213 = newJObject()
  var formData_606214 = newJObject()
  add(query_606213, "Action", newJString(Action))
  add(query_606213, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_606214.add "AlarmNames", AlarmNames
  result = call_606212.call(nil, query_606213, nil, formData_606214, nil)

var postDeleteAlarms* = Call_PostDeleteAlarms_606198(name: "postDeleteAlarms",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_PostDeleteAlarms_606199,
    base: "/", url: url_PostDeleteAlarms_606200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAlarms_605927 = ref object of OpenApiRestCall_605589
proc url_GetDeleteAlarms_605929(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteAlarms_605928(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_606041 = query.getOrDefault("AlarmNames")
  valid_606041 = validateParameter(valid_606041, JArray, required = true, default = nil)
  if valid_606041 != nil:
    section.add "AlarmNames", valid_606041
  var valid_606055 = query.getOrDefault("Action")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_606055 != nil:
    section.add "Action", valid_606055
  var valid_606056 = query.getOrDefault("Version")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606056 != nil:
    section.add "Version", valid_606056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606057 = header.getOrDefault("X-Amz-Signature")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Signature", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Content-Sha256", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Date")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Date", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Credential")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Credential", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Security-Token")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Security-Token", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Algorithm")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Algorithm", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-SignedHeaders", valid_606063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_GetDeleteAlarms_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_GetDeleteAlarms_605927; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606158 = newJObject()
  if AlarmNames != nil:
    query_606158.add "AlarmNames", AlarmNames
  add(query_606158, "Action", newJString(Action))
  add(query_606158, "Version", newJString(Version))
  result = call_606157.call(nil, query_606158, nil, nil, nil)

var getDeleteAlarms* = Call_GetDeleteAlarms_605927(name: "getDeleteAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_GetDeleteAlarms_605928,
    base: "/", url: url_GetDeleteAlarms_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnomalyDetector_606234 = ref object of OpenApiRestCall_605589
proc url_PostDeleteAnomalyDetector_606236(protocol: Scheme; host: string;
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

proc validate_PostDeleteAnomalyDetector_606235(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606237 = query.getOrDefault("Action")
  valid_606237 = validateParameter(valid_606237, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_606237 != nil:
    section.add "Action", valid_606237
  var valid_606238 = query.getOrDefault("Version")
  valid_606238 = validateParameter(valid_606238, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606238 != nil:
    section.add "Version", valid_606238
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606239 = header.getOrDefault("X-Amz-Signature")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Signature", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Content-Sha256", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Date")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Date", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Credential")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Credential", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Security-Token")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Security-Token", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Algorithm")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Algorithm", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-SignedHeaders", valid_606245
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stat: JString (required)
  ##       : The statistic associated with the anomaly detection model to delete.
  ##   MetricName: JString (required)
  ##             : The metric name associated with the anomaly detection model to delete.
  ##   Dimensions: JArray
  ##             : The metric dimensions associated with the anomaly detection model to delete.
  ##   Namespace: JString (required)
  ##            : The namespace associated with the anomaly detection model to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stat` field"
  var valid_606246 = formData.getOrDefault("Stat")
  valid_606246 = validateParameter(valid_606246, JString, required = true,
                                 default = nil)
  if valid_606246 != nil:
    section.add "Stat", valid_606246
  var valid_606247 = formData.getOrDefault("MetricName")
  valid_606247 = validateParameter(valid_606247, JString, required = true,
                                 default = nil)
  if valid_606247 != nil:
    section.add "MetricName", valid_606247
  var valid_606248 = formData.getOrDefault("Dimensions")
  valid_606248 = validateParameter(valid_606248, JArray, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "Dimensions", valid_606248
  var valid_606249 = formData.getOrDefault("Namespace")
  valid_606249 = validateParameter(valid_606249, JString, required = true,
                                 default = nil)
  if valid_606249 != nil:
    section.add "Namespace", valid_606249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606250: Call_PostDeleteAnomalyDetector_606234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_606250.validator(path, query, header, formData, body)
  let scheme = call_606250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606250.url(scheme.get, call_606250.host, call_606250.base,
                         call_606250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606250, url, valid)

proc call*(call_606251: Call_PostDeleteAnomalyDetector_606234; Stat: string;
          MetricName: string; Namespace: string;
          Action: string = "DeleteAnomalyDetector"; Dimensions: JsonNode = nil;
          Version: string = "2010-08-01"): Recallable =
  ## postDeleteAnomalyDetector
  ## Deletes the specified anomaly detection model from your account.
  ##   Stat: string (required)
  ##       : The statistic associated with the anomaly detection model to delete.
  ##   MetricName: string (required)
  ##             : The metric name associated with the anomaly detection model to delete.
  ##   Action: string (required)
  ##   Dimensions: JArray
  ##             : The metric dimensions associated with the anomaly detection model to delete.
  ##   Namespace: string (required)
  ##            : The namespace associated with the anomaly detection model to delete.
  ##   Version: string (required)
  var query_606252 = newJObject()
  var formData_606253 = newJObject()
  add(formData_606253, "Stat", newJString(Stat))
  add(formData_606253, "MetricName", newJString(MetricName))
  add(query_606252, "Action", newJString(Action))
  if Dimensions != nil:
    formData_606253.add "Dimensions", Dimensions
  add(formData_606253, "Namespace", newJString(Namespace))
  add(query_606252, "Version", newJString(Version))
  result = call_606251.call(nil, query_606252, nil, formData_606253, nil)

var postDeleteAnomalyDetector* = Call_PostDeleteAnomalyDetector_606234(
    name: "postDeleteAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_PostDeleteAnomalyDetector_606235, base: "/",
    url: url_PostDeleteAnomalyDetector_606236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnomalyDetector_606215 = ref object of OpenApiRestCall_605589
proc url_GetDeleteAnomalyDetector_606217(protocol: Scheme; host: string;
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

proc validate_GetDeleteAnomalyDetector_606216(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString (required)
  ##            : The namespace associated with the anomaly detection model to delete.
  ##   Dimensions: JArray
  ##             : The metric dimensions associated with the anomaly detection model to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MetricName: JString (required)
  ##             : The metric name associated with the anomaly detection model to delete.
  ##   Stat: JString (required)
  ##       : The statistic associated with the anomaly detection model to delete.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_606218 = query.getOrDefault("Namespace")
  valid_606218 = validateParameter(valid_606218, JString, required = true,
                                 default = nil)
  if valid_606218 != nil:
    section.add "Namespace", valid_606218
  var valid_606219 = query.getOrDefault("Dimensions")
  valid_606219 = validateParameter(valid_606219, JArray, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "Dimensions", valid_606219
  var valid_606220 = query.getOrDefault("Action")
  valid_606220 = validateParameter(valid_606220, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_606220 != nil:
    section.add "Action", valid_606220
  var valid_606221 = query.getOrDefault("Version")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606221 != nil:
    section.add "Version", valid_606221
  var valid_606222 = query.getOrDefault("MetricName")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = nil)
  if valid_606222 != nil:
    section.add "MetricName", valid_606222
  var valid_606223 = query.getOrDefault("Stat")
  valid_606223 = validateParameter(valid_606223, JString, required = true,
                                 default = nil)
  if valid_606223 != nil:
    section.add "Stat", valid_606223
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606224 = header.getOrDefault("X-Amz-Signature")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Signature", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Content-Sha256", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Date")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Date", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Credential")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Credential", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Security-Token")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Security-Token", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Algorithm")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Algorithm", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-SignedHeaders", valid_606230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606231: Call_GetDeleteAnomalyDetector_606215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_606231.validator(path, query, header, formData, body)
  let scheme = call_606231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606231.url(scheme.get, call_606231.host, call_606231.base,
                         call_606231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606231, url, valid)

proc call*(call_606232: Call_GetDeleteAnomalyDetector_606215; Namespace: string;
          MetricName: string; Stat: string; Dimensions: JsonNode = nil;
          Action: string = "DeleteAnomalyDetector"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteAnomalyDetector
  ## Deletes the specified anomaly detection model from your account.
  ##   Namespace: string (required)
  ##            : The namespace associated with the anomaly detection model to delete.
  ##   Dimensions: JArray
  ##             : The metric dimensions associated with the anomaly detection model to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricName: string (required)
  ##             : The metric name associated with the anomaly detection model to delete.
  ##   Stat: string (required)
  ##       : The statistic associated with the anomaly detection model to delete.
  var query_606233 = newJObject()
  add(query_606233, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_606233.add "Dimensions", Dimensions
  add(query_606233, "Action", newJString(Action))
  add(query_606233, "Version", newJString(Version))
  add(query_606233, "MetricName", newJString(MetricName))
  add(query_606233, "Stat", newJString(Stat))
  result = call_606232.call(nil, query_606233, nil, nil, nil)

var getDeleteAnomalyDetector* = Call_GetDeleteAnomalyDetector_606215(
    name: "getDeleteAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_GetDeleteAnomalyDetector_606216, base: "/",
    url: url_GetDeleteAnomalyDetector_606217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDashboards_606270 = ref object of OpenApiRestCall_605589
proc url_PostDeleteDashboards_606272(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDashboards_606271(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606273 = query.getOrDefault("Action")
  valid_606273 = validateParameter(valid_606273, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_606273 != nil:
    section.add "Action", valid_606273
  var valid_606274 = query.getOrDefault("Version")
  valid_606274 = validateParameter(valid_606274, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606274 != nil:
    section.add "Version", valid_606274
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardNames` field"
  var valid_606282 = formData.getOrDefault("DashboardNames")
  valid_606282 = validateParameter(valid_606282, JArray, required = true, default = nil)
  if valid_606282 != nil:
    section.add "DashboardNames", valid_606282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_PostDeleteDashboards_606270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_PostDeleteDashboards_606270; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606285 = newJObject()
  var formData_606286 = newJObject()
  if DashboardNames != nil:
    formData_606286.add "DashboardNames", DashboardNames
  add(query_606285, "Action", newJString(Action))
  add(query_606285, "Version", newJString(Version))
  result = call_606284.call(nil, query_606285, nil, formData_606286, nil)

var postDeleteDashboards* = Call_PostDeleteDashboards_606270(
    name: "postDeleteDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_PostDeleteDashboards_606271, base: "/",
    url: url_PostDeleteDashboards_606272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDashboards_606254 = ref object of OpenApiRestCall_605589
proc url_GetDeleteDashboards_606256(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDashboards_606255(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DashboardNames` field"
  var valid_606257 = query.getOrDefault("DashboardNames")
  valid_606257 = validateParameter(valid_606257, JArray, required = true, default = nil)
  if valid_606257 != nil:
    section.add "DashboardNames", valid_606257
  var valid_606258 = query.getOrDefault("Action")
  valid_606258 = validateParameter(valid_606258, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_606258 != nil:
    section.add "Action", valid_606258
  var valid_606259 = query.getOrDefault("Version")
  valid_606259 = validateParameter(valid_606259, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606259 != nil:
    section.add "Version", valid_606259
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606267: Call_GetDeleteDashboards_606254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_606267.validator(path, query, header, formData, body)
  let scheme = call_606267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606267.url(scheme.get, call_606267.host, call_606267.base,
                         call_606267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606267, url, valid)

proc call*(call_606268: Call_GetDeleteDashboards_606254; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606269 = newJObject()
  if DashboardNames != nil:
    query_606269.add "DashboardNames", DashboardNames
  add(query_606269, "Action", newJString(Action))
  add(query_606269, "Version", newJString(Version))
  result = call_606268.call(nil, query_606269, nil, nil, nil)

var getDeleteDashboards* = Call_GetDeleteDashboards_606254(
    name: "getDeleteDashboards", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_GetDeleteDashboards_606255, base: "/",
    url: url_GetDeleteDashboards_606256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteInsightRules_606303 = ref object of OpenApiRestCall_605589
proc url_PostDeleteInsightRules_606305(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteInsightRules_606304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606306 = query.getOrDefault("Action")
  valid_606306 = validateParameter(valid_606306, JString, required = true,
                                 default = newJString("DeleteInsightRules"))
  if valid_606306 != nil:
    section.add "Action", valid_606306
  var valid_606307 = query.getOrDefault("Version")
  valid_606307 = validateParameter(valid_606307, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606307 != nil:
    section.add "Version", valid_606307
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606308 = header.getOrDefault("X-Amz-Signature")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Signature", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Content-Sha256", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Date")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Date", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Credential")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Credential", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Security-Token")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Security-Token", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Algorithm")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Algorithm", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-SignedHeaders", valid_606314
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_606315 = formData.getOrDefault("RuleNames")
  valid_606315 = validateParameter(valid_606315, JArray, required = true, default = nil)
  if valid_606315 != nil:
    section.add "RuleNames", valid_606315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606316: Call_PostDeleteInsightRules_606303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_606316.validator(path, query, header, formData, body)
  let scheme = call_606316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606316.url(scheme.get, call_606316.host, call_606316.base,
                         call_606316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606316, url, valid)

proc call*(call_606317: Call_PostDeleteInsightRules_606303; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606318 = newJObject()
  var formData_606319 = newJObject()
  if RuleNames != nil:
    formData_606319.add "RuleNames", RuleNames
  add(query_606318, "Action", newJString(Action))
  add(query_606318, "Version", newJString(Version))
  result = call_606317.call(nil, query_606318, nil, formData_606319, nil)

var postDeleteInsightRules* = Call_PostDeleteInsightRules_606303(
    name: "postDeleteInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_PostDeleteInsightRules_606304, base: "/",
    url: url_PostDeleteInsightRules_606305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteInsightRules_606287 = ref object of OpenApiRestCall_605589
proc url_GetDeleteInsightRules_606289(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteInsightRules_606288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606290 = query.getOrDefault("Action")
  valid_606290 = validateParameter(valid_606290, JString, required = true,
                                 default = newJString("DeleteInsightRules"))
  if valid_606290 != nil:
    section.add "Action", valid_606290
  var valid_606291 = query.getOrDefault("RuleNames")
  valid_606291 = validateParameter(valid_606291, JArray, required = true, default = nil)
  if valid_606291 != nil:
    section.add "RuleNames", valid_606291
  var valid_606292 = query.getOrDefault("Version")
  valid_606292 = validateParameter(valid_606292, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606292 != nil:
    section.add "Version", valid_606292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606293 = header.getOrDefault("X-Amz-Signature")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Signature", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Content-Sha256", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Date")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Date", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Credential")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Credential", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Security-Token")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Security-Token", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Algorithm")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Algorithm", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-SignedHeaders", valid_606299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606300: Call_GetDeleteInsightRules_606287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_606300.validator(path, query, header, formData, body)
  let scheme = call_606300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606300.url(scheme.get, call_606300.host, call_606300.base,
                         call_606300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606300, url, valid)

proc call*(call_606301: Call_GetDeleteInsightRules_606287; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_606302 = newJObject()
  add(query_606302, "Action", newJString(Action))
  if RuleNames != nil:
    query_606302.add "RuleNames", RuleNames
  add(query_606302, "Version", newJString(Version))
  result = call_606301.call(nil, query_606302, nil, nil, nil)

var getDeleteInsightRules* = Call_GetDeleteInsightRules_606287(
    name: "getDeleteInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_GetDeleteInsightRules_606288, base: "/",
    url: url_GetDeleteInsightRules_606289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmHistory_606341 = ref object of OpenApiRestCall_605589
proc url_PostDescribeAlarmHistory_606343(protocol: Scheme; host: string;
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

proc validate_PostDescribeAlarmHistory_606342(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606344 = query.getOrDefault("Action")
  valid_606344 = validateParameter(valid_606344, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_606344 != nil:
    section.add "Action", valid_606344
  var valid_606345 = query.getOrDefault("Version")
  valid_606345 = validateParameter(valid_606345, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606345 != nil:
    section.add "Version", valid_606345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606346 = header.getOrDefault("X-Amz-Signature")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Signature", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Content-Sha256", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Date")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Date", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Credential")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Credential", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Security-Token")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Security-Token", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Algorithm")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Algorithm", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-SignedHeaders", valid_606352
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmName: JString
  ##            : The name of the alarm.
  ##   HistoryItemType: JString
  ##                  : The type of alarm histories to retrieve.
  ##   MaxRecords: JInt
  ##             : The maximum number of alarm history records to retrieve.
  ##   EndDate: JString
  ##          : The ending date to retrieve alarm history.
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   StartDate: JString
  ##            : The starting date to retrieve alarm history.
  section = newJObject()
  var valid_606353 = formData.getOrDefault("AlarmName")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "AlarmName", valid_606353
  var valid_606354 = formData.getOrDefault("HistoryItemType")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_606354 != nil:
    section.add "HistoryItemType", valid_606354
  var valid_606355 = formData.getOrDefault("MaxRecords")
  valid_606355 = validateParameter(valid_606355, JInt, required = false, default = nil)
  if valid_606355 != nil:
    section.add "MaxRecords", valid_606355
  var valid_606356 = formData.getOrDefault("EndDate")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "EndDate", valid_606356
  var valid_606357 = formData.getOrDefault("NextToken")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "NextToken", valid_606357
  var valid_606358 = formData.getOrDefault("StartDate")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "StartDate", valid_606358
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606359: Call_PostDescribeAlarmHistory_606341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_606359.validator(path, query, header, formData, body)
  let scheme = call_606359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606359.url(scheme.get, call_606359.host, call_606359.base,
                         call_606359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606359, url, valid)

proc call*(call_606360: Call_PostDescribeAlarmHistory_606341;
          AlarmName: string = ""; HistoryItemType: string = "ConfigurationUpdate";
          MaxRecords: int = 0; EndDate: string = ""; NextToken: string = "";
          StartDate: string = ""; Action: string = "DescribeAlarmHistory";
          Version: string = "2010-08-01"): Recallable =
  ## postDescribeAlarmHistory
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ##   AlarmName: string
  ##            : The name of the alarm.
  ##   HistoryItemType: string
  ##                  : The type of alarm histories to retrieve.
  ##   MaxRecords: int
  ##             : The maximum number of alarm history records to retrieve.
  ##   EndDate: string
  ##          : The ending date to retrieve alarm history.
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   StartDate: string
  ##            : The starting date to retrieve alarm history.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606361 = newJObject()
  var formData_606362 = newJObject()
  add(formData_606362, "AlarmName", newJString(AlarmName))
  add(formData_606362, "HistoryItemType", newJString(HistoryItemType))
  add(formData_606362, "MaxRecords", newJInt(MaxRecords))
  add(formData_606362, "EndDate", newJString(EndDate))
  add(formData_606362, "NextToken", newJString(NextToken))
  add(formData_606362, "StartDate", newJString(StartDate))
  add(query_606361, "Action", newJString(Action))
  add(query_606361, "Version", newJString(Version))
  result = call_606360.call(nil, query_606361, nil, formData_606362, nil)

var postDescribeAlarmHistory* = Call_PostDescribeAlarmHistory_606341(
    name: "postDescribeAlarmHistory", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_PostDescribeAlarmHistory_606342, base: "/",
    url: url_PostDescribeAlarmHistory_606343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmHistory_606320 = ref object of OpenApiRestCall_605589
proc url_GetDescribeAlarmHistory_606322(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetDescribeAlarmHistory_606321(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString
  ##          : The ending date to retrieve alarm history.
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   HistoryItemType: JString
  ##                  : The type of alarm histories to retrieve.
  ##   Action: JString (required)
  ##   AlarmName: JString
  ##            : The name of the alarm.
  ##   StartDate: JString
  ##            : The starting date to retrieve alarm history.
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  ##             : The maximum number of alarm history records to retrieve.
  section = newJObject()
  var valid_606323 = query.getOrDefault("EndDate")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "EndDate", valid_606323
  var valid_606324 = query.getOrDefault("NextToken")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "NextToken", valid_606324
  var valid_606325 = query.getOrDefault("HistoryItemType")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_606325 != nil:
    section.add "HistoryItemType", valid_606325
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606326 = query.getOrDefault("Action")
  valid_606326 = validateParameter(valid_606326, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_606326 != nil:
    section.add "Action", valid_606326
  var valid_606327 = query.getOrDefault("AlarmName")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "AlarmName", valid_606327
  var valid_606328 = query.getOrDefault("StartDate")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "StartDate", valid_606328
  var valid_606329 = query.getOrDefault("Version")
  valid_606329 = validateParameter(valid_606329, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606329 != nil:
    section.add "Version", valid_606329
  var valid_606330 = query.getOrDefault("MaxRecords")
  valid_606330 = validateParameter(valid_606330, JInt, required = false, default = nil)
  if valid_606330 != nil:
    section.add "MaxRecords", valid_606330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606331 = header.getOrDefault("X-Amz-Signature")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Signature", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Content-Sha256", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-Date")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Date", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Credential")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Credential", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Security-Token")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Security-Token", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Algorithm")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Algorithm", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-SignedHeaders", valid_606337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606338: Call_GetDescribeAlarmHistory_606320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_606338.validator(path, query, header, formData, body)
  let scheme = call_606338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606338.url(scheme.get, call_606338.host, call_606338.base,
                         call_606338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606338, url, valid)

proc call*(call_606339: Call_GetDescribeAlarmHistory_606320; EndDate: string = "";
          NextToken: string = ""; HistoryItemType: string = "ConfigurationUpdate";
          Action: string = "DescribeAlarmHistory"; AlarmName: string = "";
          StartDate: string = ""; Version: string = "2010-08-01"; MaxRecords: int = 0): Recallable =
  ## getDescribeAlarmHistory
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ##   EndDate: string
  ##          : The ending date to retrieve alarm history.
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   HistoryItemType: string
  ##                  : The type of alarm histories to retrieve.
  ##   Action: string (required)
  ##   AlarmName: string
  ##            : The name of the alarm.
  ##   StartDate: string
  ##            : The starting date to retrieve alarm history.
  ##   Version: string (required)
  ##   MaxRecords: int
  ##             : The maximum number of alarm history records to retrieve.
  var query_606340 = newJObject()
  add(query_606340, "EndDate", newJString(EndDate))
  add(query_606340, "NextToken", newJString(NextToken))
  add(query_606340, "HistoryItemType", newJString(HistoryItemType))
  add(query_606340, "Action", newJString(Action))
  add(query_606340, "AlarmName", newJString(AlarmName))
  add(query_606340, "StartDate", newJString(StartDate))
  add(query_606340, "Version", newJString(Version))
  add(query_606340, "MaxRecords", newJInt(MaxRecords))
  result = call_606339.call(nil, query_606340, nil, nil, nil)

var getDescribeAlarmHistory* = Call_GetDescribeAlarmHistory_606320(
    name: "getDescribeAlarmHistory", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_GetDescribeAlarmHistory_606321, base: "/",
    url: url_GetDescribeAlarmHistory_606322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarms_606384 = ref object of OpenApiRestCall_605589
proc url_PostDescribeAlarms_606386(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeAlarms_606385(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606387 = query.getOrDefault("Action")
  valid_606387 = validateParameter(valid_606387, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_606387 != nil:
    section.add "Action", valid_606387
  var valid_606388 = query.getOrDefault("Version")
  valid_606388 = validateParameter(valid_606388, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606388 != nil:
    section.add "Version", valid_606388
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606389 = header.getOrDefault("X-Amz-Signature")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Signature", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Content-Sha256", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Date")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Date", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Credential")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Credential", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Security-Token")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Security-Token", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Algorithm")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Algorithm", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-SignedHeaders", valid_606395
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNamePrefix: JString
  ##                  : The alarm name prefix. If this parameter is specified, you cannot specify <code>AlarmNames</code>.
  ##   StateValue: JString
  ##             : The state value to be used in matching alarms.
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   MaxRecords: JInt
  ##             : The maximum number of alarm descriptions to retrieve.
  ##   ActionPrefix: JString
  ##               : The action name prefix.
  ##   AlarmNames: JArray
  ##             : The names of the alarms.
  section = newJObject()
  var valid_606396 = formData.getOrDefault("AlarmNamePrefix")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "AlarmNamePrefix", valid_606396
  var valid_606397 = formData.getOrDefault("StateValue")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = newJString("OK"))
  if valid_606397 != nil:
    section.add "StateValue", valid_606397
  var valid_606398 = formData.getOrDefault("NextToken")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "NextToken", valid_606398
  var valid_606399 = formData.getOrDefault("MaxRecords")
  valid_606399 = validateParameter(valid_606399, JInt, required = false, default = nil)
  if valid_606399 != nil:
    section.add "MaxRecords", valid_606399
  var valid_606400 = formData.getOrDefault("ActionPrefix")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "ActionPrefix", valid_606400
  var valid_606401 = formData.getOrDefault("AlarmNames")
  valid_606401 = validateParameter(valid_606401, JArray, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "AlarmNames", valid_606401
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606402: Call_PostDescribeAlarms_606384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_606402.validator(path, query, header, formData, body)
  let scheme = call_606402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606402.url(scheme.get, call_606402.host, call_606402.base,
                         call_606402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606402, url, valid)

proc call*(call_606403: Call_PostDescribeAlarms_606384;
          AlarmNamePrefix: string = ""; StateValue: string = "OK";
          NextToken: string = ""; MaxRecords: int = 0;
          Action: string = "DescribeAlarms"; ActionPrefix: string = "";
          Version: string = "2010-08-01"; AlarmNames: JsonNode = nil): Recallable =
  ## postDescribeAlarms
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ##   AlarmNamePrefix: string
  ##                  : The alarm name prefix. If this parameter is specified, you cannot specify <code>AlarmNames</code>.
  ##   StateValue: string
  ##             : The state value to be used in matching alarms.
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   MaxRecords: int
  ##             : The maximum number of alarm descriptions to retrieve.
  ##   Action: string (required)
  ##   ActionPrefix: string
  ##               : The action name prefix.
  ##   Version: string (required)
  ##   AlarmNames: JArray
  ##             : The names of the alarms.
  var query_606404 = newJObject()
  var formData_606405 = newJObject()
  add(formData_606405, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(formData_606405, "StateValue", newJString(StateValue))
  add(formData_606405, "NextToken", newJString(NextToken))
  add(formData_606405, "MaxRecords", newJInt(MaxRecords))
  add(query_606404, "Action", newJString(Action))
  add(formData_606405, "ActionPrefix", newJString(ActionPrefix))
  add(query_606404, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_606405.add "AlarmNames", AlarmNames
  result = call_606403.call(nil, query_606404, nil, formData_606405, nil)

var postDescribeAlarms* = Call_PostDescribeAlarms_606384(
    name: "postDescribeAlarms", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarms",
    validator: validate_PostDescribeAlarms_606385, base: "/",
    url: url_PostDescribeAlarms_606386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarms_606363 = ref object of OpenApiRestCall_605589
proc url_GetDescribeAlarms_606365(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeAlarms_606364(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   StateValue: JString
  ##             : The state value to be used in matching alarms.
  ##   ActionPrefix: JString
  ##               : The action name prefix.
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   AlarmNamePrefix: JString
  ##                  : The alarm name prefix. If this parameter is specified, you cannot specify <code>AlarmNames</code>.
  ##   AlarmNames: JArray
  ##             : The names of the alarms.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  ##             : The maximum number of alarm descriptions to retrieve.
  section = newJObject()
  var valid_606366 = query.getOrDefault("StateValue")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = newJString("OK"))
  if valid_606366 != nil:
    section.add "StateValue", valid_606366
  var valid_606367 = query.getOrDefault("ActionPrefix")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "ActionPrefix", valid_606367
  var valid_606368 = query.getOrDefault("NextToken")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "NextToken", valid_606368
  var valid_606369 = query.getOrDefault("AlarmNamePrefix")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "AlarmNamePrefix", valid_606369
  var valid_606370 = query.getOrDefault("AlarmNames")
  valid_606370 = validateParameter(valid_606370, JArray, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "AlarmNames", valid_606370
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606371 = query.getOrDefault("Action")
  valid_606371 = validateParameter(valid_606371, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_606371 != nil:
    section.add "Action", valid_606371
  var valid_606372 = query.getOrDefault("Version")
  valid_606372 = validateParameter(valid_606372, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606372 != nil:
    section.add "Version", valid_606372
  var valid_606373 = query.getOrDefault("MaxRecords")
  valid_606373 = validateParameter(valid_606373, JInt, required = false, default = nil)
  if valid_606373 != nil:
    section.add "MaxRecords", valid_606373
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606374 = header.getOrDefault("X-Amz-Signature")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Signature", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Content-Sha256", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Date")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Date", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Credential")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Credential", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Security-Token")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Security-Token", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Algorithm")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Algorithm", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-SignedHeaders", valid_606380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606381: Call_GetDescribeAlarms_606363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_606381.validator(path, query, header, formData, body)
  let scheme = call_606381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606381.url(scheme.get, call_606381.host, call_606381.base,
                         call_606381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606381, url, valid)

proc call*(call_606382: Call_GetDescribeAlarms_606363; StateValue: string = "OK";
          ActionPrefix: string = ""; NextToken: string = "";
          AlarmNamePrefix: string = ""; AlarmNames: JsonNode = nil;
          Action: string = "DescribeAlarms"; Version: string = "2010-08-01";
          MaxRecords: int = 0): Recallable =
  ## getDescribeAlarms
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ##   StateValue: string
  ##             : The state value to be used in matching alarms.
  ##   ActionPrefix: string
  ##               : The action name prefix.
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   AlarmNamePrefix: string
  ##                  : The alarm name prefix. If this parameter is specified, you cannot specify <code>AlarmNames</code>.
  ##   AlarmNames: JArray
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##             : The maximum number of alarm descriptions to retrieve.
  var query_606383 = newJObject()
  add(query_606383, "StateValue", newJString(StateValue))
  add(query_606383, "ActionPrefix", newJString(ActionPrefix))
  add(query_606383, "NextToken", newJString(NextToken))
  add(query_606383, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  if AlarmNames != nil:
    query_606383.add "AlarmNames", AlarmNames
  add(query_606383, "Action", newJString(Action))
  add(query_606383, "Version", newJString(Version))
  add(query_606383, "MaxRecords", newJInt(MaxRecords))
  result = call_606382.call(nil, query_606383, nil, nil, nil)

var getDescribeAlarms* = Call_GetDescribeAlarms_606363(name: "getDescribeAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DescribeAlarms", validator: validate_GetDescribeAlarms_606364,
    base: "/", url: url_GetDescribeAlarms_606365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmsForMetric_606428 = ref object of OpenApiRestCall_605589
proc url_PostDescribeAlarmsForMetric_606430(protocol: Scheme; host: string;
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

proc validate_PostDescribeAlarmsForMetric_606429(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606431 = query.getOrDefault("Action")
  valid_606431 = validateParameter(valid_606431, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_606431 != nil:
    section.add "Action", valid_606431
  var valid_606432 = query.getOrDefault("Version")
  valid_606432 = validateParameter(valid_606432, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606432 != nil:
    section.add "Version", valid_606432
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606433 = header.getOrDefault("X-Amz-Signature")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Signature", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Content-Sha256", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Date")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Date", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Credential")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Credential", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Security-Token")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Security-Token", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Algorithm")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Algorithm", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-SignedHeaders", valid_606439
  result.add "header", section
  ## parameters in `formData` object:
  ##   Unit: JString
  ##       : The unit for the metric.
  ##   Period: JInt
  ##         : The period, in seconds, over which the statistic is applied.
  ##   Statistic: JString
  ##            : The statistic for the metric, other than percentiles. For percentile statistics, use <code>ExtendedStatistics</code>.
  ##   MetricName: JString (required)
  ##             : The name of the metric.
  ##   Dimensions: JArray
  ##             : The dimensions associated with the metric. If the metric has any associated dimensions, you must specify them in order for the call to succeed.
  ##   Namespace: JString (required)
  ##            : The namespace of the metric.
  ##   ExtendedStatistic: JString
  ##                    : The percentile statistic for the metric. Specify a value between p0.0 and p100.
  section = newJObject()
  var valid_606440 = formData.getOrDefault("Unit")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_606440 != nil:
    section.add "Unit", valid_606440
  var valid_606441 = formData.getOrDefault("Period")
  valid_606441 = validateParameter(valid_606441, JInt, required = false, default = nil)
  if valid_606441 != nil:
    section.add "Period", valid_606441
  var valid_606442 = formData.getOrDefault("Statistic")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_606442 != nil:
    section.add "Statistic", valid_606442
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_606443 = formData.getOrDefault("MetricName")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = nil)
  if valid_606443 != nil:
    section.add "MetricName", valid_606443
  var valid_606444 = formData.getOrDefault("Dimensions")
  valid_606444 = validateParameter(valid_606444, JArray, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "Dimensions", valid_606444
  var valid_606445 = formData.getOrDefault("Namespace")
  valid_606445 = validateParameter(valid_606445, JString, required = true,
                                 default = nil)
  if valid_606445 != nil:
    section.add "Namespace", valid_606445
  var valid_606446 = formData.getOrDefault("ExtendedStatistic")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "ExtendedStatistic", valid_606446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606447: Call_PostDescribeAlarmsForMetric_606428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_606447.validator(path, query, header, formData, body)
  let scheme = call_606447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606447.url(scheme.get, call_606447.host, call_606447.base,
                         call_606447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606447, url, valid)

proc call*(call_606448: Call_PostDescribeAlarmsForMetric_606428;
          MetricName: string; Namespace: string; Unit: string = "Seconds";
          Period: int = 0; Statistic: string = "SampleCount";
          Action: string = "DescribeAlarmsForMetric"; Dimensions: JsonNode = nil;
          ExtendedStatistic: string = ""; Version: string = "2010-08-01"): Recallable =
  ## postDescribeAlarmsForMetric
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ##   Unit: string
  ##       : The unit for the metric.
  ##   Period: int
  ##         : The period, in seconds, over which the statistic is applied.
  ##   Statistic: string
  ##            : The statistic for the metric, other than percentiles. For percentile statistics, use <code>ExtendedStatistics</code>.
  ##   MetricName: string (required)
  ##             : The name of the metric.
  ##   Action: string (required)
  ##   Dimensions: JArray
  ##             : The dimensions associated with the metric. If the metric has any associated dimensions, you must specify them in order for the call to succeed.
  ##   Namespace: string (required)
  ##            : The namespace of the metric.
  ##   ExtendedStatistic: string
  ##                    : The percentile statistic for the metric. Specify a value between p0.0 and p100.
  ##   Version: string (required)
  var query_606449 = newJObject()
  var formData_606450 = newJObject()
  add(formData_606450, "Unit", newJString(Unit))
  add(formData_606450, "Period", newJInt(Period))
  add(formData_606450, "Statistic", newJString(Statistic))
  add(formData_606450, "MetricName", newJString(MetricName))
  add(query_606449, "Action", newJString(Action))
  if Dimensions != nil:
    formData_606450.add "Dimensions", Dimensions
  add(formData_606450, "Namespace", newJString(Namespace))
  add(formData_606450, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_606449, "Version", newJString(Version))
  result = call_606448.call(nil, query_606449, nil, formData_606450, nil)

var postDescribeAlarmsForMetric* = Call_PostDescribeAlarmsForMetric_606428(
    name: "postDescribeAlarmsForMetric", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_PostDescribeAlarmsForMetric_606429, base: "/",
    url: url_PostDescribeAlarmsForMetric_606430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmsForMetric_606406 = ref object of OpenApiRestCall_605589
proc url_GetDescribeAlarmsForMetric_606408(protocol: Scheme; host: string;
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

proc validate_GetDescribeAlarmsForMetric_606407(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Statistic: JString
  ##            : The statistic for the metric, other than percentiles. For percentile statistics, use <code>ExtendedStatistics</code>.
  ##   Unit: JString
  ##       : The unit for the metric.
  ##   Namespace: JString (required)
  ##            : The namespace of the metric.
  ##   ExtendedStatistic: JString
  ##                    : The percentile statistic for the metric. Specify a value between p0.0 and p100.
  ##   Period: JInt
  ##         : The period, in seconds, over which the statistic is applied.
  ##   Dimensions: JArray
  ##             : The dimensions associated with the metric. If the metric has any associated dimensions, you must specify them in order for the call to succeed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MetricName: JString (required)
  ##             : The name of the metric.
  section = newJObject()
  var valid_606409 = query.getOrDefault("Statistic")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_606409 != nil:
    section.add "Statistic", valid_606409
  var valid_606410 = query.getOrDefault("Unit")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_606410 != nil:
    section.add "Unit", valid_606410
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_606411 = query.getOrDefault("Namespace")
  valid_606411 = validateParameter(valid_606411, JString, required = true,
                                 default = nil)
  if valid_606411 != nil:
    section.add "Namespace", valid_606411
  var valid_606412 = query.getOrDefault("ExtendedStatistic")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "ExtendedStatistic", valid_606412
  var valid_606413 = query.getOrDefault("Period")
  valid_606413 = validateParameter(valid_606413, JInt, required = false, default = nil)
  if valid_606413 != nil:
    section.add "Period", valid_606413
  var valid_606414 = query.getOrDefault("Dimensions")
  valid_606414 = validateParameter(valid_606414, JArray, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "Dimensions", valid_606414
  var valid_606415 = query.getOrDefault("Action")
  valid_606415 = validateParameter(valid_606415, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_606415 != nil:
    section.add "Action", valid_606415
  var valid_606416 = query.getOrDefault("Version")
  valid_606416 = validateParameter(valid_606416, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606416 != nil:
    section.add "Version", valid_606416
  var valid_606417 = query.getOrDefault("MetricName")
  valid_606417 = validateParameter(valid_606417, JString, required = true,
                                 default = nil)
  if valid_606417 != nil:
    section.add "MetricName", valid_606417
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606418 = header.getOrDefault("X-Amz-Signature")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Signature", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Content-Sha256", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Date")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Date", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Credential")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Credential", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Security-Token")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Security-Token", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Algorithm")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Algorithm", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-SignedHeaders", valid_606424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606425: Call_GetDescribeAlarmsForMetric_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_606425.validator(path, query, header, formData, body)
  let scheme = call_606425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606425.url(scheme.get, call_606425.host, call_606425.base,
                         call_606425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606425, url, valid)

proc call*(call_606426: Call_GetDescribeAlarmsForMetric_606406; Namespace: string;
          MetricName: string; Statistic: string = "SampleCount";
          Unit: string = "Seconds"; ExtendedStatistic: string = ""; Period: int = 0;
          Dimensions: JsonNode = nil; Action: string = "DescribeAlarmsForMetric";
          Version: string = "2010-08-01"): Recallable =
  ## getDescribeAlarmsForMetric
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ##   Statistic: string
  ##            : The statistic for the metric, other than percentiles. For percentile statistics, use <code>ExtendedStatistics</code>.
  ##   Unit: string
  ##       : The unit for the metric.
  ##   Namespace: string (required)
  ##            : The namespace of the metric.
  ##   ExtendedStatistic: string
  ##                    : The percentile statistic for the metric. Specify a value between p0.0 and p100.
  ##   Period: int
  ##         : The period, in seconds, over which the statistic is applied.
  ##   Dimensions: JArray
  ##             : The dimensions associated with the metric. If the metric has any associated dimensions, you must specify them in order for the call to succeed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricName: string (required)
  ##             : The name of the metric.
  var query_606427 = newJObject()
  add(query_606427, "Statistic", newJString(Statistic))
  add(query_606427, "Unit", newJString(Unit))
  add(query_606427, "Namespace", newJString(Namespace))
  add(query_606427, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_606427, "Period", newJInt(Period))
  if Dimensions != nil:
    query_606427.add "Dimensions", Dimensions
  add(query_606427, "Action", newJString(Action))
  add(query_606427, "Version", newJString(Version))
  add(query_606427, "MetricName", newJString(MetricName))
  result = call_606426.call(nil, query_606427, nil, nil, nil)

var getDescribeAlarmsForMetric* = Call_GetDescribeAlarmsForMetric_606406(
    name: "getDescribeAlarmsForMetric", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_GetDescribeAlarmsForMetric_606407, base: "/",
    url: url_GetDescribeAlarmsForMetric_606408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnomalyDetectors_606471 = ref object of OpenApiRestCall_605589
proc url_PostDescribeAnomalyDetectors_606473(protocol: Scheme; host: string;
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

proc validate_PostDescribeAnomalyDetectors_606472(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606474 = query.getOrDefault("Action")
  valid_606474 = validateParameter(valid_606474, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_606474 != nil:
    section.add "Action", valid_606474
  var valid_606475 = query.getOrDefault("Version")
  valid_606475 = validateParameter(valid_606475, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606475 != nil:
    section.add "Version", valid_606475
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606476 = header.getOrDefault("X-Amz-Signature")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Signature", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Content-Sha256", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Date")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Date", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Credential")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Credential", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Security-Token")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Security-Token", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Algorithm")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Algorithm", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-SignedHeaders", valid_606482
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Use the token returned by the previous operation to request the next page of results.
  ##   MetricName: JString
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric name. If there are multiple metrics with this name in different namespaces that have anomaly detection models, they're all returned.
  ##   Dimensions: JArray
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric dimensions. If there are multiple metrics that have these dimensions and have anomaly detection models associated, they're all returned.
  ##   Namespace: JString
  ##            : Limits the results to only the anomaly detection models that are associated with the specified namespace.
  ##   MaxResults: JInt
  ##             : <p>The maximum number of results to return in one operation. The maximum value you can specify is 10.</p> <p>To retrieve the remaining results, make another call with the returned <code>NextToken</code> value. </p>
  section = newJObject()
  var valid_606483 = formData.getOrDefault("NextToken")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "NextToken", valid_606483
  var valid_606484 = formData.getOrDefault("MetricName")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "MetricName", valid_606484
  var valid_606485 = formData.getOrDefault("Dimensions")
  valid_606485 = validateParameter(valid_606485, JArray, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "Dimensions", valid_606485
  var valid_606486 = formData.getOrDefault("Namespace")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "Namespace", valid_606486
  var valid_606487 = formData.getOrDefault("MaxResults")
  valid_606487 = validateParameter(valid_606487, JInt, required = false, default = nil)
  if valid_606487 != nil:
    section.add "MaxResults", valid_606487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606488: Call_PostDescribeAnomalyDetectors_606471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_606488.validator(path, query, header, formData, body)
  let scheme = call_606488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606488.url(scheme.get, call_606488.host, call_606488.base,
                         call_606488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606488, url, valid)

proc call*(call_606489: Call_PostDescribeAnomalyDetectors_606471;
          NextToken: string = ""; MetricName: string = "";
          Action: string = "DescribeAnomalyDetectors"; Dimensions: JsonNode = nil;
          Namespace: string = ""; Version: string = "2010-08-01"; MaxResults: int = 0): Recallable =
  ## postDescribeAnomalyDetectors
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ##   NextToken: string
  ##            : Use the token returned by the previous operation to request the next page of results.
  ##   MetricName: string
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric name. If there are multiple metrics with this name in different namespaces that have anomaly detection models, they're all returned.
  ##   Action: string (required)
  ##   Dimensions: JArray
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric dimensions. If there are multiple metrics that have these dimensions and have anomaly detection models associated, they're all returned.
  ##   Namespace: string
  ##            : Limits the results to only the anomaly detection models that are associated with the specified namespace.
  ##   Version: string (required)
  ##   MaxResults: int
  ##             : <p>The maximum number of results to return in one operation. The maximum value you can specify is 10.</p> <p>To retrieve the remaining results, make another call with the returned <code>NextToken</code> value. </p>
  var query_606490 = newJObject()
  var formData_606491 = newJObject()
  add(formData_606491, "NextToken", newJString(NextToken))
  add(formData_606491, "MetricName", newJString(MetricName))
  add(query_606490, "Action", newJString(Action))
  if Dimensions != nil:
    formData_606491.add "Dimensions", Dimensions
  add(formData_606491, "Namespace", newJString(Namespace))
  add(query_606490, "Version", newJString(Version))
  add(formData_606491, "MaxResults", newJInt(MaxResults))
  result = call_606489.call(nil, query_606490, nil, formData_606491, nil)

var postDescribeAnomalyDetectors* = Call_PostDescribeAnomalyDetectors_606471(
    name: "postDescribeAnomalyDetectors", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_PostDescribeAnomalyDetectors_606472, base: "/",
    url: url_PostDescribeAnomalyDetectors_606473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnomalyDetectors_606451 = ref object of OpenApiRestCall_605589
proc url_GetDescribeAnomalyDetectors_606453(protocol: Scheme; host: string;
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

proc validate_GetDescribeAnomalyDetectors_606452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : <p>The maximum number of results to return in one operation. The maximum value you can specify is 10.</p> <p>To retrieve the remaining results, make another call with the returned <code>NextToken</code> value. </p>
  ##   NextToken: JString
  ##            : Use the token returned by the previous operation to request the next page of results.
  ##   Namespace: JString
  ##            : Limits the results to only the anomaly detection models that are associated with the specified namespace.
  ##   Dimensions: JArray
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric dimensions. If there are multiple metrics that have these dimensions and have anomaly detection models associated, they're all returned.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MetricName: JString
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric name. If there are multiple metrics with this name in different namespaces that have anomaly detection models, they're all returned.
  section = newJObject()
  var valid_606454 = query.getOrDefault("MaxResults")
  valid_606454 = validateParameter(valid_606454, JInt, required = false, default = nil)
  if valid_606454 != nil:
    section.add "MaxResults", valid_606454
  var valid_606455 = query.getOrDefault("NextToken")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "NextToken", valid_606455
  var valid_606456 = query.getOrDefault("Namespace")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "Namespace", valid_606456
  var valid_606457 = query.getOrDefault("Dimensions")
  valid_606457 = validateParameter(valid_606457, JArray, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "Dimensions", valid_606457
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606458 = query.getOrDefault("Action")
  valid_606458 = validateParameter(valid_606458, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_606458 != nil:
    section.add "Action", valid_606458
  var valid_606459 = query.getOrDefault("Version")
  valid_606459 = validateParameter(valid_606459, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606459 != nil:
    section.add "Version", valid_606459
  var valid_606460 = query.getOrDefault("MetricName")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "MetricName", valid_606460
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606461 = header.getOrDefault("X-Amz-Signature")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Signature", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Content-Sha256", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Date")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Date", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Credential")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Credential", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Security-Token")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Security-Token", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Algorithm")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Algorithm", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-SignedHeaders", valid_606467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606468: Call_GetDescribeAnomalyDetectors_606451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_606468.validator(path, query, header, formData, body)
  let scheme = call_606468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606468.url(scheme.get, call_606468.host, call_606468.base,
                         call_606468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606468, url, valid)

proc call*(call_606469: Call_GetDescribeAnomalyDetectors_606451;
          MaxResults: int = 0; NextToken: string = ""; Namespace: string = "";
          Dimensions: JsonNode = nil; Action: string = "DescribeAnomalyDetectors";
          Version: string = "2010-08-01"; MetricName: string = ""): Recallable =
  ## getDescribeAnomalyDetectors
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ##   MaxResults: int
  ##             : <p>The maximum number of results to return in one operation. The maximum value you can specify is 10.</p> <p>To retrieve the remaining results, make another call with the returned <code>NextToken</code> value. </p>
  ##   NextToken: string
  ##            : Use the token returned by the previous operation to request the next page of results.
  ##   Namespace: string
  ##            : Limits the results to only the anomaly detection models that are associated with the specified namespace.
  ##   Dimensions: JArray
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric dimensions. If there are multiple metrics that have these dimensions and have anomaly detection models associated, they're all returned.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricName: string
  ##             : Limits the results to only the anomaly detection models that are associated with the specified metric name. If there are multiple metrics with this name in different namespaces that have anomaly detection models, they're all returned.
  var query_606470 = newJObject()
  add(query_606470, "MaxResults", newJInt(MaxResults))
  add(query_606470, "NextToken", newJString(NextToken))
  add(query_606470, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_606470.add "Dimensions", Dimensions
  add(query_606470, "Action", newJString(Action))
  add(query_606470, "Version", newJString(Version))
  add(query_606470, "MetricName", newJString(MetricName))
  result = call_606469.call(nil, query_606470, nil, nil, nil)

var getDescribeAnomalyDetectors* = Call_GetDescribeAnomalyDetectors_606451(
    name: "getDescribeAnomalyDetectors", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_GetDescribeAnomalyDetectors_606452, base: "/",
    url: url_GetDescribeAnomalyDetectors_606453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInsightRules_606509 = ref object of OpenApiRestCall_605589
proc url_PostDescribeInsightRules_606511(protocol: Scheme; host: string;
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

proc validate_PostDescribeInsightRules_606510(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606512 = query.getOrDefault("Action")
  valid_606512 = validateParameter(valid_606512, JString, required = true,
                                 default = newJString("DescribeInsightRules"))
  if valid_606512 != nil:
    section.add "Action", valid_606512
  var valid_606513 = query.getOrDefault("Version")
  valid_606513 = validateParameter(valid_606513, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606513 != nil:
    section.add "Version", valid_606513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606514 = header.getOrDefault("X-Amz-Signature")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Signature", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Content-Sha256", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Date")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Date", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Credential")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Credential", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Security-Token")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Security-Token", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Algorithm")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Algorithm", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-SignedHeaders", valid_606520
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Reserved for future use.
  ##   MaxResults: JInt
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  section = newJObject()
  var valid_606521 = formData.getOrDefault("NextToken")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "NextToken", valid_606521
  var valid_606522 = formData.getOrDefault("MaxResults")
  valid_606522 = validateParameter(valid_606522, JInt, required = false, default = nil)
  if valid_606522 != nil:
    section.add "MaxResults", valid_606522
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606523: Call_PostDescribeInsightRules_606509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_606523.validator(path, query, header, formData, body)
  let scheme = call_606523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606523.url(scheme.get, call_606523.host, call_606523.base,
                         call_606523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606523, url, valid)

proc call*(call_606524: Call_PostDescribeInsightRules_606509;
          NextToken: string = ""; Action: string = "DescribeInsightRules";
          Version: string = "2010-08-01"; MaxResults: int = 0): Recallable =
  ## postDescribeInsightRules
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ##   NextToken: string
  ##            : Reserved for future use.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxResults: int
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  var query_606525 = newJObject()
  var formData_606526 = newJObject()
  add(formData_606526, "NextToken", newJString(NextToken))
  add(query_606525, "Action", newJString(Action))
  add(query_606525, "Version", newJString(Version))
  add(formData_606526, "MaxResults", newJInt(MaxResults))
  result = call_606524.call(nil, query_606525, nil, formData_606526, nil)

var postDescribeInsightRules* = Call_PostDescribeInsightRules_606509(
    name: "postDescribeInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_PostDescribeInsightRules_606510, base: "/",
    url: url_PostDescribeInsightRules_606511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInsightRules_606492 = ref object of OpenApiRestCall_605589
proc url_GetDescribeInsightRules_606494(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetDescribeInsightRules_606493(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  ##   NextToken: JString
  ##            : Reserved for future use.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606495 = query.getOrDefault("MaxResults")
  valid_606495 = validateParameter(valid_606495, JInt, required = false, default = nil)
  if valid_606495 != nil:
    section.add "MaxResults", valid_606495
  var valid_606496 = query.getOrDefault("NextToken")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "NextToken", valid_606496
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606497 = query.getOrDefault("Action")
  valid_606497 = validateParameter(valid_606497, JString, required = true,
                                 default = newJString("DescribeInsightRules"))
  if valid_606497 != nil:
    section.add "Action", valid_606497
  var valid_606498 = query.getOrDefault("Version")
  valid_606498 = validateParameter(valid_606498, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606498 != nil:
    section.add "Version", valid_606498
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606499 = header.getOrDefault("X-Amz-Signature")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Signature", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Content-Sha256", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Date")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Date", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Credential")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Credential", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Security-Token")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Security-Token", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Algorithm")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Algorithm", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-SignedHeaders", valid_606505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606506: Call_GetDescribeInsightRules_606492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_606506.validator(path, query, header, formData, body)
  let scheme = call_606506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606506.url(scheme.get, call_606506.host, call_606506.base,
                         call_606506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606506, url, valid)

proc call*(call_606507: Call_GetDescribeInsightRules_606492; MaxResults: int = 0;
          NextToken: string = ""; Action: string = "DescribeInsightRules";
          Version: string = "2010-08-01"): Recallable =
  ## getDescribeInsightRules
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ##   MaxResults: int
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  ##   NextToken: string
  ##            : Reserved for future use.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606508 = newJObject()
  add(query_606508, "MaxResults", newJInt(MaxResults))
  add(query_606508, "NextToken", newJString(NextToken))
  add(query_606508, "Action", newJString(Action))
  add(query_606508, "Version", newJString(Version))
  result = call_606507.call(nil, query_606508, nil, nil, nil)

var getDescribeInsightRules* = Call_GetDescribeInsightRules_606492(
    name: "getDescribeInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_GetDescribeInsightRules_606493, base: "/",
    url: url_GetDescribeInsightRules_606494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAlarmActions_606543 = ref object of OpenApiRestCall_605589
proc url_PostDisableAlarmActions_606545(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostDisableAlarmActions_606544(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606546 = query.getOrDefault("Action")
  valid_606546 = validateParameter(valid_606546, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_606546 != nil:
    section.add "Action", valid_606546
  var valid_606547 = query.getOrDefault("Version")
  valid_606547 = validateParameter(valid_606547, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606547 != nil:
    section.add "Version", valid_606547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606548 = header.getOrDefault("X-Amz-Signature")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Signature", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Content-Sha256", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Date")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Date", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Credential")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Credential", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Security-Token")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Security-Token", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-Algorithm")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Algorithm", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-SignedHeaders", valid_606554
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_606555 = formData.getOrDefault("AlarmNames")
  valid_606555 = validateParameter(valid_606555, JArray, required = true, default = nil)
  if valid_606555 != nil:
    section.add "AlarmNames", valid_606555
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606556: Call_PostDisableAlarmActions_606543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_606556.validator(path, query, header, formData, body)
  let scheme = call_606556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606556.url(scheme.get, call_606556.host, call_606556.base,
                         call_606556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606556, url, valid)

proc call*(call_606557: Call_PostDisableAlarmActions_606543; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_606558 = newJObject()
  var formData_606559 = newJObject()
  add(query_606558, "Action", newJString(Action))
  add(query_606558, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_606559.add "AlarmNames", AlarmNames
  result = call_606557.call(nil, query_606558, nil, formData_606559, nil)

var postDisableAlarmActions* = Call_PostDisableAlarmActions_606543(
    name: "postDisableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_PostDisableAlarmActions_606544, base: "/",
    url: url_PostDisableAlarmActions_606545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAlarmActions_606527 = ref object of OpenApiRestCall_605589
proc url_GetDisableAlarmActions_606529(protocol: Scheme; host: string; base: string;
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

proc validate_GetDisableAlarmActions_606528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606530 = query.getOrDefault("AlarmNames")
  valid_606530 = validateParameter(valid_606530, JArray, required = true, default = nil)
  if valid_606530 != nil:
    section.add "AlarmNames", valid_606530
  var valid_606531 = query.getOrDefault("Action")
  valid_606531 = validateParameter(valid_606531, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_606531 != nil:
    section.add "Action", valid_606531
  var valid_606532 = query.getOrDefault("Version")
  valid_606532 = validateParameter(valid_606532, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606532 != nil:
    section.add "Version", valid_606532
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606533 = header.getOrDefault("X-Amz-Signature")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Signature", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Content-Sha256", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Date")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Date", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Credential")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Credential", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Security-Token")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Security-Token", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Algorithm")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Algorithm", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-SignedHeaders", valid_606539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606540: Call_GetDisableAlarmActions_606527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_606540.validator(path, query, header, formData, body)
  let scheme = call_606540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606540.url(scheme.get, call_606540.host, call_606540.base,
                         call_606540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606540, url, valid)

proc call*(call_606541: Call_GetDisableAlarmActions_606527; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606542 = newJObject()
  if AlarmNames != nil:
    query_606542.add "AlarmNames", AlarmNames
  add(query_606542, "Action", newJString(Action))
  add(query_606542, "Version", newJString(Version))
  result = call_606541.call(nil, query_606542, nil, nil, nil)

var getDisableAlarmActions* = Call_GetDisableAlarmActions_606527(
    name: "getDisableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_GetDisableAlarmActions_606528, base: "/",
    url: url_GetDisableAlarmActions_606529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableInsightRules_606576 = ref object of OpenApiRestCall_605589
proc url_PostDisableInsightRules_606578(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostDisableInsightRules_606577(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606579 = query.getOrDefault("Action")
  valid_606579 = validateParameter(valid_606579, JString, required = true,
                                 default = newJString("DisableInsightRules"))
  if valid_606579 != nil:
    section.add "Action", valid_606579
  var valid_606580 = query.getOrDefault("Version")
  valid_606580 = validateParameter(valid_606580, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606580 != nil:
    section.add "Version", valid_606580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606581 = header.getOrDefault("X-Amz-Signature")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Signature", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Content-Sha256", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Date")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Date", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Credential")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Credential", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Security-Token")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Security-Token", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Algorithm")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Algorithm", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-SignedHeaders", valid_606587
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_606588 = formData.getOrDefault("RuleNames")
  valid_606588 = validateParameter(valid_606588, JArray, required = true, default = nil)
  if valid_606588 != nil:
    section.add "RuleNames", valid_606588
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606589: Call_PostDisableInsightRules_606576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_606589.validator(path, query, header, formData, body)
  let scheme = call_606589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606589.url(scheme.get, call_606589.host, call_606589.base,
                         call_606589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606589, url, valid)

proc call*(call_606590: Call_PostDisableInsightRules_606576; RuleNames: JsonNode;
          Action: string = "DisableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606591 = newJObject()
  var formData_606592 = newJObject()
  if RuleNames != nil:
    formData_606592.add "RuleNames", RuleNames
  add(query_606591, "Action", newJString(Action))
  add(query_606591, "Version", newJString(Version))
  result = call_606590.call(nil, query_606591, nil, formData_606592, nil)

var postDisableInsightRules* = Call_PostDisableInsightRules_606576(
    name: "postDisableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_PostDisableInsightRules_606577, base: "/",
    url: url_PostDisableInsightRules_606578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableInsightRules_606560 = ref object of OpenApiRestCall_605589
proc url_GetDisableInsightRules_606562(protocol: Scheme; host: string; base: string;
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

proc validate_GetDisableInsightRules_606561(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606563 = query.getOrDefault("Action")
  valid_606563 = validateParameter(valid_606563, JString, required = true,
                                 default = newJString("DisableInsightRules"))
  if valid_606563 != nil:
    section.add "Action", valid_606563
  var valid_606564 = query.getOrDefault("RuleNames")
  valid_606564 = validateParameter(valid_606564, JArray, required = true, default = nil)
  if valid_606564 != nil:
    section.add "RuleNames", valid_606564
  var valid_606565 = query.getOrDefault("Version")
  valid_606565 = validateParameter(valid_606565, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606565 != nil:
    section.add "Version", valid_606565
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606566 = header.getOrDefault("X-Amz-Signature")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Signature", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Content-Sha256", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Date")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Date", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Credential")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Credential", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Security-Token")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Security-Token", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Algorithm")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Algorithm", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-SignedHeaders", valid_606572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606573: Call_GetDisableInsightRules_606560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_606573.validator(path, query, header, formData, body)
  let scheme = call_606573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606573.url(scheme.get, call_606573.host, call_606573.base,
                         call_606573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606573, url, valid)

proc call*(call_606574: Call_GetDisableInsightRules_606560; RuleNames: JsonNode;
          Action: string = "DisableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_606575 = newJObject()
  add(query_606575, "Action", newJString(Action))
  if RuleNames != nil:
    query_606575.add "RuleNames", RuleNames
  add(query_606575, "Version", newJString(Version))
  result = call_606574.call(nil, query_606575, nil, nil, nil)

var getDisableInsightRules* = Call_GetDisableInsightRules_606560(
    name: "getDisableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_GetDisableInsightRules_606561, base: "/",
    url: url_GetDisableInsightRules_606562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAlarmActions_606609 = ref object of OpenApiRestCall_605589
proc url_PostEnableAlarmActions_606611(protocol: Scheme; host: string; base: string;
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

proc validate_PostEnableAlarmActions_606610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606612 = query.getOrDefault("Action")
  valid_606612 = validateParameter(valid_606612, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_606612 != nil:
    section.add "Action", valid_606612
  var valid_606613 = query.getOrDefault("Version")
  valid_606613 = validateParameter(valid_606613, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606613 != nil:
    section.add "Version", valid_606613
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606614 = header.getOrDefault("X-Amz-Signature")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Signature", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Content-Sha256", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Date")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Date", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Credential")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Credential", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Security-Token")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Security-Token", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Algorithm")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Algorithm", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-SignedHeaders", valid_606620
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_606621 = formData.getOrDefault("AlarmNames")
  valid_606621 = validateParameter(valid_606621, JArray, required = true, default = nil)
  if valid_606621 != nil:
    section.add "AlarmNames", valid_606621
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606622: Call_PostEnableAlarmActions_606609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_606622.validator(path, query, header, formData, body)
  let scheme = call_606622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606622.url(scheme.get, call_606622.host, call_606622.base,
                         call_606622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606622, url, valid)

proc call*(call_606623: Call_PostEnableAlarmActions_606609; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_606624 = newJObject()
  var formData_606625 = newJObject()
  add(query_606624, "Action", newJString(Action))
  add(query_606624, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_606625.add "AlarmNames", AlarmNames
  result = call_606623.call(nil, query_606624, nil, formData_606625, nil)

var postEnableAlarmActions* = Call_PostEnableAlarmActions_606609(
    name: "postEnableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_PostEnableAlarmActions_606610, base: "/",
    url: url_PostEnableAlarmActions_606611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAlarmActions_606593 = ref object of OpenApiRestCall_605589
proc url_GetEnableAlarmActions_606595(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnableAlarmActions_606594(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606596 = query.getOrDefault("AlarmNames")
  valid_606596 = validateParameter(valid_606596, JArray, required = true, default = nil)
  if valid_606596 != nil:
    section.add "AlarmNames", valid_606596
  var valid_606597 = query.getOrDefault("Action")
  valid_606597 = validateParameter(valid_606597, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_606597 != nil:
    section.add "Action", valid_606597
  var valid_606598 = query.getOrDefault("Version")
  valid_606598 = validateParameter(valid_606598, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606598 != nil:
    section.add "Version", valid_606598
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606599 = header.getOrDefault("X-Amz-Signature")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Signature", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Content-Sha256", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Date")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Date", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Credential")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Credential", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Security-Token")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Security-Token", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Algorithm")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Algorithm", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-SignedHeaders", valid_606605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606606: Call_GetEnableAlarmActions_606593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_606606.validator(path, query, header, formData, body)
  let scheme = call_606606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606606.url(scheme.get, call_606606.host, call_606606.base,
                         call_606606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606606, url, valid)

proc call*(call_606607: Call_GetEnableAlarmActions_606593; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606608 = newJObject()
  if AlarmNames != nil:
    query_606608.add "AlarmNames", AlarmNames
  add(query_606608, "Action", newJString(Action))
  add(query_606608, "Version", newJString(Version))
  result = call_606607.call(nil, query_606608, nil, nil, nil)

var getEnableAlarmActions* = Call_GetEnableAlarmActions_606593(
    name: "getEnableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_GetEnableAlarmActions_606594, base: "/",
    url: url_GetEnableAlarmActions_606595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableInsightRules_606642 = ref object of OpenApiRestCall_605589
proc url_PostEnableInsightRules_606644(protocol: Scheme; host: string; base: string;
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

proc validate_PostEnableInsightRules_606643(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606645 = query.getOrDefault("Action")
  valid_606645 = validateParameter(valid_606645, JString, required = true,
                                 default = newJString("EnableInsightRules"))
  if valid_606645 != nil:
    section.add "Action", valid_606645
  var valid_606646 = query.getOrDefault("Version")
  valid_606646 = validateParameter(valid_606646, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606646 != nil:
    section.add "Version", valid_606646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606647 = header.getOrDefault("X-Amz-Signature")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Signature", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Content-Sha256", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Date")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Date", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Credential")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Credential", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Security-Token")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Security-Token", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Algorithm")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Algorithm", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-SignedHeaders", valid_606653
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_606654 = formData.getOrDefault("RuleNames")
  valid_606654 = validateParameter(valid_606654, JArray, required = true, default = nil)
  if valid_606654 != nil:
    section.add "RuleNames", valid_606654
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606655: Call_PostEnableInsightRules_606642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_606655.validator(path, query, header, formData, body)
  let scheme = call_606655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606655.url(scheme.get, call_606655.host, call_606655.base,
                         call_606655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606655, url, valid)

proc call*(call_606656: Call_PostEnableInsightRules_606642; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606657 = newJObject()
  var formData_606658 = newJObject()
  if RuleNames != nil:
    formData_606658.add "RuleNames", RuleNames
  add(query_606657, "Action", newJString(Action))
  add(query_606657, "Version", newJString(Version))
  result = call_606656.call(nil, query_606657, nil, formData_606658, nil)

var postEnableInsightRules* = Call_PostEnableInsightRules_606642(
    name: "postEnableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_PostEnableInsightRules_606643, base: "/",
    url: url_PostEnableInsightRules_606644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableInsightRules_606626 = ref object of OpenApiRestCall_605589
proc url_GetEnableInsightRules_606628(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnableInsightRules_606627(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606629 = query.getOrDefault("Action")
  valid_606629 = validateParameter(valid_606629, JString, required = true,
                                 default = newJString("EnableInsightRules"))
  if valid_606629 != nil:
    section.add "Action", valid_606629
  var valid_606630 = query.getOrDefault("RuleNames")
  valid_606630 = validateParameter(valid_606630, JArray, required = true, default = nil)
  if valid_606630 != nil:
    section.add "RuleNames", valid_606630
  var valid_606631 = query.getOrDefault("Version")
  valid_606631 = validateParameter(valid_606631, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606631 != nil:
    section.add "Version", valid_606631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606632 = header.getOrDefault("X-Amz-Signature")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Signature", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Content-Sha256", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-Date")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Date", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Credential")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Credential", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Security-Token")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Security-Token", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Algorithm")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Algorithm", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-SignedHeaders", valid_606638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606639: Call_GetEnableInsightRules_606626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_606639.validator(path, query, header, formData, body)
  let scheme = call_606639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606639.url(scheme.get, call_606639.host, call_606639.base,
                         call_606639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606639, url, valid)

proc call*(call_606640: Call_GetEnableInsightRules_606626; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_606641 = newJObject()
  add(query_606641, "Action", newJString(Action))
  if RuleNames != nil:
    query_606641.add "RuleNames", RuleNames
  add(query_606641, "Version", newJString(Version))
  result = call_606640.call(nil, query_606641, nil, nil, nil)

var getEnableInsightRules* = Call_GetEnableInsightRules_606626(
    name: "getEnableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_GetEnableInsightRules_606627, base: "/",
    url: url_GetEnableInsightRules_606628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetDashboard_606675 = ref object of OpenApiRestCall_605589
proc url_PostGetDashboard_606677(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetDashboard_606676(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606678 = query.getOrDefault("Action")
  valid_606678 = validateParameter(valid_606678, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_606678 != nil:
    section.add "Action", valid_606678
  var valid_606679 = query.getOrDefault("Version")
  valid_606679 = validateParameter(valid_606679, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606679 != nil:
    section.add "Version", valid_606679
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606680 = header.getOrDefault("X-Amz-Signature")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Signature", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Content-Sha256", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Date")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Date", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Credential")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Credential", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Security-Token")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Security-Token", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Algorithm")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Algorithm", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-SignedHeaders", valid_606686
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_606687 = formData.getOrDefault("DashboardName")
  valid_606687 = validateParameter(valid_606687, JString, required = true,
                                 default = nil)
  if valid_606687 != nil:
    section.add "DashboardName", valid_606687
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606688: Call_PostGetDashboard_606675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_606688.validator(path, query, header, formData, body)
  let scheme = call_606688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606688.url(scheme.get, call_606688.host, call_606688.base,
                         call_606688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606688, url, valid)

proc call*(call_606689: Call_PostGetDashboard_606675; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## postGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606690 = newJObject()
  var formData_606691 = newJObject()
  add(formData_606691, "DashboardName", newJString(DashboardName))
  add(query_606690, "Action", newJString(Action))
  add(query_606690, "Version", newJString(Version))
  result = call_606689.call(nil, query_606690, nil, formData_606691, nil)

var postGetDashboard* = Call_PostGetDashboard_606675(name: "postGetDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_PostGetDashboard_606676,
    base: "/", url: url_PostGetDashboard_606677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetDashboard_606659 = ref object of OpenApiRestCall_605589
proc url_GetGetDashboard_606661(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetDashboard_606660(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606662 = query.getOrDefault("Action")
  valid_606662 = validateParameter(valid_606662, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_606662 != nil:
    section.add "Action", valid_606662
  var valid_606663 = query.getOrDefault("DashboardName")
  valid_606663 = validateParameter(valid_606663, JString, required = true,
                                 default = nil)
  if valid_606663 != nil:
    section.add "DashboardName", valid_606663
  var valid_606664 = query.getOrDefault("Version")
  valid_606664 = validateParameter(valid_606664, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606664 != nil:
    section.add "Version", valid_606664
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606665 = header.getOrDefault("X-Amz-Signature")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Signature", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Content-Sha256", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Date")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Date", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Credential")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Credential", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Security-Token")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Security-Token", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Algorithm")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Algorithm", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-SignedHeaders", valid_606671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606672: Call_GetGetDashboard_606659; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_606672.validator(path, query, header, formData, body)
  let scheme = call_606672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606672.url(scheme.get, call_606672.host, call_606672.base,
                         call_606672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606672, url, valid)

proc call*(call_606673: Call_GetGetDashboard_606659; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## getGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Version: string (required)
  var query_606674 = newJObject()
  add(query_606674, "Action", newJString(Action))
  add(query_606674, "DashboardName", newJString(DashboardName))
  add(query_606674, "Version", newJString(Version))
  result = call_606673.call(nil, query_606674, nil, nil, nil)

var getGetDashboard* = Call_GetGetDashboard_606659(name: "getGetDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_GetGetDashboard_606660,
    base: "/", url: url_GetGetDashboard_606661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetInsightRuleReport_606714 = ref object of OpenApiRestCall_605589
proc url_PostGetInsightRuleReport_606716(protocol: Scheme; host: string;
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

proc validate_PostGetInsightRuleReport_606715(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606717 = query.getOrDefault("Action")
  valid_606717 = validateParameter(valid_606717, JString, required = true,
                                 default = newJString("GetInsightRuleReport"))
  if valid_606717 != nil:
    section.add "Action", valid_606717
  var valid_606718 = query.getOrDefault("Version")
  valid_606718 = validateParameter(valid_606718, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606718 != nil:
    section.add "Version", valid_606718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606719 = header.getOrDefault("X-Amz-Signature")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Signature", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Content-Sha256", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Date")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Date", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Credential")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Credential", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Security-Token")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Security-Token", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Algorithm")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Algorithm", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-SignedHeaders", valid_606725
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleName: JString (required)
  ##           : The name of the rule that you want to see data from.
  ##   Period: JInt (required)
  ##         : The period, in seconds, to use for the statistics in the <code>InsightRuleMetricDatapoint</code> results.
  ##   OrderBy: JString
  ##          : Determines what statistic to use to rank the contributors. Valid values are SUM and MAXIMUM.
  ##   EndTime: JString (required)
  ##          : The end time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   StartTime: JString (required)
  ##            : The start time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   MaxContributorCount: JInt
  ##                      : The maximum number of contributors to include in the report. The range is 1 to 100. If you omit this, the default of 10 is used.
  ##   Metrics: JArray
  ##          : <p>Specifies which metrics to use for aggregation of contributor values for the report. You can specify one or more of the following metrics:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleName` field"
  var valid_606726 = formData.getOrDefault("RuleName")
  valid_606726 = validateParameter(valid_606726, JString, required = true,
                                 default = nil)
  if valid_606726 != nil:
    section.add "RuleName", valid_606726
  var valid_606727 = formData.getOrDefault("Period")
  valid_606727 = validateParameter(valid_606727, JInt, required = true, default = nil)
  if valid_606727 != nil:
    section.add "Period", valid_606727
  var valid_606728 = formData.getOrDefault("OrderBy")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "OrderBy", valid_606728
  var valid_606729 = formData.getOrDefault("EndTime")
  valid_606729 = validateParameter(valid_606729, JString, required = true,
                                 default = nil)
  if valid_606729 != nil:
    section.add "EndTime", valid_606729
  var valid_606730 = formData.getOrDefault("StartTime")
  valid_606730 = validateParameter(valid_606730, JString, required = true,
                                 default = nil)
  if valid_606730 != nil:
    section.add "StartTime", valid_606730
  var valid_606731 = formData.getOrDefault("MaxContributorCount")
  valid_606731 = validateParameter(valid_606731, JInt, required = false, default = nil)
  if valid_606731 != nil:
    section.add "MaxContributorCount", valid_606731
  var valid_606732 = formData.getOrDefault("Metrics")
  valid_606732 = validateParameter(valid_606732, JArray, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "Metrics", valid_606732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606733: Call_PostGetInsightRuleReport_606714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_606733.validator(path, query, header, formData, body)
  let scheme = call_606733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606733.url(scheme.get, call_606733.host, call_606733.base,
                         call_606733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606733, url, valid)

proc call*(call_606734: Call_PostGetInsightRuleReport_606714; RuleName: string;
          Period: int; EndTime: string; StartTime: string; OrderBy: string = "";
          Action: string = "GetInsightRuleReport"; Version: string = "2010-08-01";
          MaxContributorCount: int = 0; Metrics: JsonNode = nil): Recallable =
  ## postGetInsightRuleReport
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ##   RuleName: string (required)
  ##           : The name of the rule that you want to see data from.
  ##   Period: int (required)
  ##         : The period, in seconds, to use for the statistics in the <code>InsightRuleMetricDatapoint</code> results.
  ##   OrderBy: string
  ##          : Determines what statistic to use to rank the contributors. Valid values are SUM and MAXIMUM.
  ##   EndTime: string (required)
  ##          : The end time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   StartTime: string (required)
  ##            : The start time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxContributorCount: int
  ##                      : The maximum number of contributors to include in the report. The range is 1 to 100. If you omit this, the default of 10 is used.
  ##   Metrics: JArray
  ##          : <p>Specifies which metrics to use for aggregation of contributor values for the report. You can specify one or more of the following metrics:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  var query_606735 = newJObject()
  var formData_606736 = newJObject()
  add(formData_606736, "RuleName", newJString(RuleName))
  add(formData_606736, "Period", newJInt(Period))
  add(formData_606736, "OrderBy", newJString(OrderBy))
  add(formData_606736, "EndTime", newJString(EndTime))
  add(formData_606736, "StartTime", newJString(StartTime))
  add(query_606735, "Action", newJString(Action))
  add(query_606735, "Version", newJString(Version))
  add(formData_606736, "MaxContributorCount", newJInt(MaxContributorCount))
  if Metrics != nil:
    formData_606736.add "Metrics", Metrics
  result = call_606734.call(nil, query_606735, nil, formData_606736, nil)

var postGetInsightRuleReport* = Call_PostGetInsightRuleReport_606714(
    name: "postGetInsightRuleReport", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_PostGetInsightRuleReport_606715, base: "/",
    url: url_PostGetInsightRuleReport_606716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetInsightRuleReport_606692 = ref object of OpenApiRestCall_605589
proc url_GetGetInsightRuleReport_606694(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetGetInsightRuleReport_606693(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RuleName: JString (required)
  ##           : The name of the rule that you want to see data from.
  ##   MaxContributorCount: JInt
  ##                      : The maximum number of contributors to include in the report. The range is 1 to 100. If you omit this, the default of 10 is used.
  ##   OrderBy: JString
  ##          : Determines what statistic to use to rank the contributors. Valid values are SUM and MAXIMUM.
  ##   Period: JInt (required)
  ##         : The period, in seconds, to use for the statistics in the <code>InsightRuleMetricDatapoint</code> results.
  ##   Action: JString (required)
  ##   StartTime: JString (required)
  ##            : The start time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   EndTime: JString (required)
  ##          : The end time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   Metrics: JArray
  ##          : <p>Specifies which metrics to use for aggregation of contributor values for the report. You can specify one or more of the following metrics:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `RuleName` field"
  var valid_606695 = query.getOrDefault("RuleName")
  valid_606695 = validateParameter(valid_606695, JString, required = true,
                                 default = nil)
  if valid_606695 != nil:
    section.add "RuleName", valid_606695
  var valid_606696 = query.getOrDefault("MaxContributorCount")
  valid_606696 = validateParameter(valid_606696, JInt, required = false, default = nil)
  if valid_606696 != nil:
    section.add "MaxContributorCount", valid_606696
  var valid_606697 = query.getOrDefault("OrderBy")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "OrderBy", valid_606697
  var valid_606698 = query.getOrDefault("Period")
  valid_606698 = validateParameter(valid_606698, JInt, required = true, default = nil)
  if valid_606698 != nil:
    section.add "Period", valid_606698
  var valid_606699 = query.getOrDefault("Action")
  valid_606699 = validateParameter(valid_606699, JString, required = true,
                                 default = newJString("GetInsightRuleReport"))
  if valid_606699 != nil:
    section.add "Action", valid_606699
  var valid_606700 = query.getOrDefault("StartTime")
  valid_606700 = validateParameter(valid_606700, JString, required = true,
                                 default = nil)
  if valid_606700 != nil:
    section.add "StartTime", valid_606700
  var valid_606701 = query.getOrDefault("EndTime")
  valid_606701 = validateParameter(valid_606701, JString, required = true,
                                 default = nil)
  if valid_606701 != nil:
    section.add "EndTime", valid_606701
  var valid_606702 = query.getOrDefault("Metrics")
  valid_606702 = validateParameter(valid_606702, JArray, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "Metrics", valid_606702
  var valid_606703 = query.getOrDefault("Version")
  valid_606703 = validateParameter(valid_606703, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606703 != nil:
    section.add "Version", valid_606703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606704 = header.getOrDefault("X-Amz-Signature")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Signature", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Content-Sha256", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Date")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Date", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Credential")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Credential", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Security-Token")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Security-Token", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Algorithm")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Algorithm", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-SignedHeaders", valid_606710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606711: Call_GetGetInsightRuleReport_606692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_606711.validator(path, query, header, formData, body)
  let scheme = call_606711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606711.url(scheme.get, call_606711.host, call_606711.base,
                         call_606711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606711, url, valid)

proc call*(call_606712: Call_GetGetInsightRuleReport_606692; RuleName: string;
          Period: int; StartTime: string; EndTime: string;
          MaxContributorCount: int = 0; OrderBy: string = "";
          Action: string = "GetInsightRuleReport"; Metrics: JsonNode = nil;
          Version: string = "2010-08-01"): Recallable =
  ## getGetInsightRuleReport
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ##   RuleName: string (required)
  ##           : The name of the rule that you want to see data from.
  ##   MaxContributorCount: int
  ##                      : The maximum number of contributors to include in the report. The range is 1 to 100. If you omit this, the default of 10 is used.
  ##   OrderBy: string
  ##          : Determines what statistic to use to rank the contributors. Valid values are SUM and MAXIMUM.
  ##   Period: int (required)
  ##         : The period, in seconds, to use for the statistics in the <code>InsightRuleMetricDatapoint</code> results.
  ##   Action: string (required)
  ##   StartTime: string (required)
  ##            : The start time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   EndTime: string (required)
  ##          : The end time of the data to use in the report. When used in a raw HTTP Query API, it is formatted as <code>yyyy-MM-dd'T'HH:mm:ss</code>. For example, <code>2019-07-01T23:59:59</code>.
  ##   Metrics: JArray
  ##          : <p>Specifies which metrics to use for aggregation of contributor values for the report. You can specify one or more of the following metrics:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ##   Version: string (required)
  var query_606713 = newJObject()
  add(query_606713, "RuleName", newJString(RuleName))
  add(query_606713, "MaxContributorCount", newJInt(MaxContributorCount))
  add(query_606713, "OrderBy", newJString(OrderBy))
  add(query_606713, "Period", newJInt(Period))
  add(query_606713, "Action", newJString(Action))
  add(query_606713, "StartTime", newJString(StartTime))
  add(query_606713, "EndTime", newJString(EndTime))
  if Metrics != nil:
    query_606713.add "Metrics", Metrics
  add(query_606713, "Version", newJString(Version))
  result = call_606712.call(nil, query_606713, nil, nil, nil)

var getGetInsightRuleReport* = Call_GetGetInsightRuleReport_606692(
    name: "getGetInsightRuleReport", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_GetGetInsightRuleReport_606693, base: "/",
    url: url_GetGetInsightRuleReport_606694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricData_606758 = ref object of OpenApiRestCall_605589
proc url_PostGetMetricData_606760(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetMetricData_606759(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606761 = query.getOrDefault("Action")
  valid_606761 = validateParameter(valid_606761, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_606761 != nil:
    section.add "Action", valid_606761
  var valid_606762 = query.getOrDefault("Version")
  valid_606762 = validateParameter(valid_606762, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606762 != nil:
    section.add "Version", valid_606762
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606763 = header.getOrDefault("X-Amz-Signature")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Signature", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Content-Sha256", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Date")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Date", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Credential")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Credential", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Security-Token")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Security-Token", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Algorithm")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Algorithm", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-SignedHeaders", valid_606769
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Include this value, if it was returned by the previous call, to get the next set of data points.
  ##   ScanBy: JString
  ##         : The order in which data points should be returned. <code>TimestampDescending</code> returns the newest data first and paginates when the <code>MaxDatapoints</code> limit is reached. <code>TimestampAscending</code> returns the oldest data first and paginates when the <code>MaxDatapoints</code> limit is reached.
  ##   EndTime: JString (required)
  ##          : <p>The time stamp indicating the latest data to be returned.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp.</p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>EndTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>EndTime</code>.</p>
  ##   StartTime: JString (required)
  ##            : <p>The time stamp indicating the earliest data to be returned.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. </p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>StartTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>StartTime</code>.</p>
  ##   MetricDataQueries: JArray (required)
  ##                    : The metric queries to be returned. A single <code>GetMetricData</code> call can include as many as 100 <code>MetricDataQuery</code> structures. Each of these structures can specify either a metric to retrieve, or a math expression to perform on retrieved data. 
  ##   MaxDatapoints: JInt
  ##                : The maximum number of data points the request should return before paginating. If you omit this, the default of 100,800 is used.
  section = newJObject()
  var valid_606770 = formData.getOrDefault("NextToken")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "NextToken", valid_606770
  var valid_606771 = formData.getOrDefault("ScanBy")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_606771 != nil:
    section.add "ScanBy", valid_606771
  assert formData != nil,
        "formData argument is necessary due to required `EndTime` field"
  var valid_606772 = formData.getOrDefault("EndTime")
  valid_606772 = validateParameter(valid_606772, JString, required = true,
                                 default = nil)
  if valid_606772 != nil:
    section.add "EndTime", valid_606772
  var valid_606773 = formData.getOrDefault("StartTime")
  valid_606773 = validateParameter(valid_606773, JString, required = true,
                                 default = nil)
  if valid_606773 != nil:
    section.add "StartTime", valid_606773
  var valid_606774 = formData.getOrDefault("MetricDataQueries")
  valid_606774 = validateParameter(valid_606774, JArray, required = true, default = nil)
  if valid_606774 != nil:
    section.add "MetricDataQueries", valid_606774
  var valid_606775 = formData.getOrDefault("MaxDatapoints")
  valid_606775 = validateParameter(valid_606775, JInt, required = false, default = nil)
  if valid_606775 != nil:
    section.add "MaxDatapoints", valid_606775
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606776: Call_PostGetMetricData_606758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_606776.validator(path, query, header, formData, body)
  let scheme = call_606776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606776.url(scheme.get, call_606776.host, call_606776.base,
                         call_606776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606776, url, valid)

proc call*(call_606777: Call_PostGetMetricData_606758; EndTime: string;
          StartTime: string; MetricDataQueries: JsonNode; NextToken: string = "";
          ScanBy: string = "TimestampDescending"; Action: string = "GetMetricData";
          Version: string = "2010-08-01"; MaxDatapoints: int = 0): Recallable =
  ## postGetMetricData
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ##   NextToken: string
  ##            : Include this value, if it was returned by the previous call, to get the next set of data points.
  ##   ScanBy: string
  ##         : The order in which data points should be returned. <code>TimestampDescending</code> returns the newest data first and paginates when the <code>MaxDatapoints</code> limit is reached. <code>TimestampAscending</code> returns the oldest data first and paginates when the <code>MaxDatapoints</code> limit is reached.
  ##   EndTime: string (required)
  ##          : <p>The time stamp indicating the latest data to be returned.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp.</p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>EndTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>EndTime</code>.</p>
  ##   StartTime: string (required)
  ##            : <p>The time stamp indicating the earliest data to be returned.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. </p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>StartTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>StartTime</code>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricDataQueries: JArray (required)
  ##                    : The metric queries to be returned. A single <code>GetMetricData</code> call can include as many as 100 <code>MetricDataQuery</code> structures. Each of these structures can specify either a metric to retrieve, or a math expression to perform on retrieved data. 
  ##   MaxDatapoints: int
  ##                : The maximum number of data points the request should return before paginating. If you omit this, the default of 100,800 is used.
  var query_606778 = newJObject()
  var formData_606779 = newJObject()
  add(formData_606779, "NextToken", newJString(NextToken))
  add(formData_606779, "ScanBy", newJString(ScanBy))
  add(formData_606779, "EndTime", newJString(EndTime))
  add(formData_606779, "StartTime", newJString(StartTime))
  add(query_606778, "Action", newJString(Action))
  add(query_606778, "Version", newJString(Version))
  if MetricDataQueries != nil:
    formData_606779.add "MetricDataQueries", MetricDataQueries
  add(formData_606779, "MaxDatapoints", newJInt(MaxDatapoints))
  result = call_606777.call(nil, query_606778, nil, formData_606779, nil)

var postGetMetricData* = Call_PostGetMetricData_606758(name: "postGetMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_PostGetMetricData_606759,
    base: "/", url: url_PostGetMetricData_606760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricData_606737 = ref object of OpenApiRestCall_605589
proc url_GetGetMetricData_606739(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricData_606738(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Include this value, if it was returned by the previous call, to get the next set of data points.
  ##   MaxDatapoints: JInt
  ##                : The maximum number of data points the request should return before paginating. If you omit this, the default of 100,800 is used.
  ##   Action: JString (required)
  ##   StartTime: JString (required)
  ##            : <p>The time stamp indicating the earliest data to be returned.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. </p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>StartTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>StartTime</code>.</p>
  ##   EndTime: JString (required)
  ##          : <p>The time stamp indicating the latest data to be returned.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp.</p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>EndTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>EndTime</code>.</p>
  ##   Version: JString (required)
  ##   MetricDataQueries: JArray (required)
  ##                    : The metric queries to be returned. A single <code>GetMetricData</code> call can include as many as 100 <code>MetricDataQuery</code> structures. Each of these structures can specify either a metric to retrieve, or a math expression to perform on retrieved data. 
  ##   ScanBy: JString
  ##         : The order in which data points should be returned. <code>TimestampDescending</code> returns the newest data first and paginates when the <code>MaxDatapoints</code> limit is reached. <code>TimestampAscending</code> returns the oldest data first and paginates when the <code>MaxDatapoints</code> limit is reached.
  section = newJObject()
  var valid_606740 = query.getOrDefault("NextToken")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "NextToken", valid_606740
  var valid_606741 = query.getOrDefault("MaxDatapoints")
  valid_606741 = validateParameter(valid_606741, JInt, required = false, default = nil)
  if valid_606741 != nil:
    section.add "MaxDatapoints", valid_606741
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606742 = query.getOrDefault("Action")
  valid_606742 = validateParameter(valid_606742, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_606742 != nil:
    section.add "Action", valid_606742
  var valid_606743 = query.getOrDefault("StartTime")
  valid_606743 = validateParameter(valid_606743, JString, required = true,
                                 default = nil)
  if valid_606743 != nil:
    section.add "StartTime", valid_606743
  var valid_606744 = query.getOrDefault("EndTime")
  valid_606744 = validateParameter(valid_606744, JString, required = true,
                                 default = nil)
  if valid_606744 != nil:
    section.add "EndTime", valid_606744
  var valid_606745 = query.getOrDefault("Version")
  valid_606745 = validateParameter(valid_606745, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606745 != nil:
    section.add "Version", valid_606745
  var valid_606746 = query.getOrDefault("MetricDataQueries")
  valid_606746 = validateParameter(valid_606746, JArray, required = true, default = nil)
  if valid_606746 != nil:
    section.add "MetricDataQueries", valid_606746
  var valid_606747 = query.getOrDefault("ScanBy")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_606747 != nil:
    section.add "ScanBy", valid_606747
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606748 = header.getOrDefault("X-Amz-Signature")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Signature", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Content-Sha256", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Date")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Date", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Credential")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Credential", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Security-Token")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Security-Token", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Algorithm")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Algorithm", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-SignedHeaders", valid_606754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606755: Call_GetGetMetricData_606737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_606755.validator(path, query, header, formData, body)
  let scheme = call_606755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606755.url(scheme.get, call_606755.host, call_606755.base,
                         call_606755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606755, url, valid)

proc call*(call_606756: Call_GetGetMetricData_606737; StartTime: string;
          EndTime: string; MetricDataQueries: JsonNode; NextToken: string = "";
          MaxDatapoints: int = 0; Action: string = "GetMetricData";
          Version: string = "2010-08-01"; ScanBy: string = "TimestampDescending"): Recallable =
  ## getGetMetricData
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ##   NextToken: string
  ##            : Include this value, if it was returned by the previous call, to get the next set of data points.
  ##   MaxDatapoints: int
  ##                : The maximum number of data points the request should return before paginating. If you omit this, the default of 100,800 is used.
  ##   Action: string (required)
  ##   StartTime: string (required)
  ##            : <p>The time stamp indicating the earliest data to be returned.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. </p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>StartTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>StartTime</code>.</p>
  ##   EndTime: string (required)
  ##          : <p>The time stamp indicating the latest data to be returned.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp.</p> <p>For better performance, specify <code>StartTime</code> and <code>EndTime</code> values that align with the value of the metric's <code>Period</code> and sync up with the beginning and end of an hour. For example, if the <code>Period</code> of a metric is 5 minutes, specifying 12:05 or 12:30 as <code>EndTime</code> can get a faster response from CloudWatch than setting 12:07 or 12:29 as the <code>EndTime</code>.</p>
  ##   Version: string (required)
  ##   MetricDataQueries: JArray (required)
  ##                    : The metric queries to be returned. A single <code>GetMetricData</code> call can include as many as 100 <code>MetricDataQuery</code> structures. Each of these structures can specify either a metric to retrieve, or a math expression to perform on retrieved data. 
  ##   ScanBy: string
  ##         : The order in which data points should be returned. <code>TimestampDescending</code> returns the newest data first and paginates when the <code>MaxDatapoints</code> limit is reached. <code>TimestampAscending</code> returns the oldest data first and paginates when the <code>MaxDatapoints</code> limit is reached.
  var query_606757 = newJObject()
  add(query_606757, "NextToken", newJString(NextToken))
  add(query_606757, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_606757, "Action", newJString(Action))
  add(query_606757, "StartTime", newJString(StartTime))
  add(query_606757, "EndTime", newJString(EndTime))
  add(query_606757, "Version", newJString(Version))
  if MetricDataQueries != nil:
    query_606757.add "MetricDataQueries", MetricDataQueries
  add(query_606757, "ScanBy", newJString(ScanBy))
  result = call_606756.call(nil, query_606757, nil, nil, nil)

var getGetMetricData* = Call_GetGetMetricData_606737(name: "getGetMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_GetGetMetricData_606738,
    base: "/", url: url_GetGetMetricData_606739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricStatistics_606804 = ref object of OpenApiRestCall_605589
proc url_PostGetMetricStatistics_606806(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostGetMetricStatistics_606805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606807 = query.getOrDefault("Action")
  valid_606807 = validateParameter(valid_606807, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_606807 != nil:
    section.add "Action", valid_606807
  var valid_606808 = query.getOrDefault("Version")
  valid_606808 = validateParameter(valid_606808, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606808 != nil:
    section.add "Version", valid_606808
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606809 = header.getOrDefault("X-Amz-Signature")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Signature", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Content-Sha256", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Date")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Date", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Credential")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Credential", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Security-Token")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Security-Token", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Algorithm")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Algorithm", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-SignedHeaders", valid_606815
  result.add "header", section
  ## parameters in `formData` object:
  ##   Unit: JString
  ##       : The unit for a given metric. If you omit <code>Unit</code>, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.
  ##   Period: JInt (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  ##   Statistics: JArray
  ##             : The metric statistics, other than percentile. For percentile statistics, use <code>ExtendedStatistics</code>. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both.
  ##   ExtendedStatistics: JArray
  ##                     : The percentile statistics. Specify values between p0.0 and p100. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both. Percentile statistics are not available for metrics when any of the metric values are negative numbers.
  ##   EndTime: JString (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   StartTime: JString (required)
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   MetricName: JString (required)
  ##             : The name of the metric, with or without spaces.
  ##   Dimensions: JArray
  ##             : The dimensions. If the metric contains multiple dimensions, you must include a value for each dimension. CloudWatch treats each unique combination of dimensions as a separate metric. If a specific combination of dimensions was not published, you can't retrieve statistics for it. You must specify the same dimensions that were used when the metrics were created. For an example, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#dimension-combinations">Dimension Combinations</a> in the <i>Amazon CloudWatch User Guide</i>. For more information about specifying dimensions, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   Namespace: JString (required)
  ##            : The namespace of the metric, with or without spaces.
  section = newJObject()
  var valid_606816 = formData.getOrDefault("Unit")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_606816 != nil:
    section.add "Unit", valid_606816
  assert formData != nil,
        "formData argument is necessary due to required `Period` field"
  var valid_606817 = formData.getOrDefault("Period")
  valid_606817 = validateParameter(valid_606817, JInt, required = true, default = nil)
  if valid_606817 != nil:
    section.add "Period", valid_606817
  var valid_606818 = formData.getOrDefault("Statistics")
  valid_606818 = validateParameter(valid_606818, JArray, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "Statistics", valid_606818
  var valid_606819 = formData.getOrDefault("ExtendedStatistics")
  valid_606819 = validateParameter(valid_606819, JArray, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "ExtendedStatistics", valid_606819
  var valid_606820 = formData.getOrDefault("EndTime")
  valid_606820 = validateParameter(valid_606820, JString, required = true,
                                 default = nil)
  if valid_606820 != nil:
    section.add "EndTime", valid_606820
  var valid_606821 = formData.getOrDefault("StartTime")
  valid_606821 = validateParameter(valid_606821, JString, required = true,
                                 default = nil)
  if valid_606821 != nil:
    section.add "StartTime", valid_606821
  var valid_606822 = formData.getOrDefault("MetricName")
  valid_606822 = validateParameter(valid_606822, JString, required = true,
                                 default = nil)
  if valid_606822 != nil:
    section.add "MetricName", valid_606822
  var valid_606823 = formData.getOrDefault("Dimensions")
  valid_606823 = validateParameter(valid_606823, JArray, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "Dimensions", valid_606823
  var valid_606824 = formData.getOrDefault("Namespace")
  valid_606824 = validateParameter(valid_606824, JString, required = true,
                                 default = nil)
  if valid_606824 != nil:
    section.add "Namespace", valid_606824
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606825: Call_PostGetMetricStatistics_606804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_606825.validator(path, query, header, formData, body)
  let scheme = call_606825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606825.url(scheme.get, call_606825.host, call_606825.base,
                         call_606825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606825, url, valid)

proc call*(call_606826: Call_PostGetMetricStatistics_606804; Period: int;
          EndTime: string; StartTime: string; MetricName: string; Namespace: string;
          Unit: string = "Seconds"; Statistics: JsonNode = nil;
          ExtendedStatistics: JsonNode = nil;
          Action: string = "GetMetricStatistics"; Dimensions: JsonNode = nil;
          Version: string = "2010-08-01"): Recallable =
  ## postGetMetricStatistics
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ##   Unit: string
  ##       : The unit for a given metric. If you omit <code>Unit</code>, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.
  ##   Period: int (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  ##   Statistics: JArray
  ##             : The metric statistics, other than percentile. For percentile statistics, use <code>ExtendedStatistics</code>. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both.
  ##   ExtendedStatistics: JArray
  ##                     : The percentile statistics. Specify values between p0.0 and p100. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both. Percentile statistics are not available for metrics when any of the metric values are negative numbers.
  ##   EndTime: string (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   StartTime: string (required)
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   MetricName: string (required)
  ##             : The name of the metric, with or without spaces.
  ##   Action: string (required)
  ##   Dimensions: JArray
  ##             : The dimensions. If the metric contains multiple dimensions, you must include a value for each dimension. CloudWatch treats each unique combination of dimensions as a separate metric. If a specific combination of dimensions was not published, you can't retrieve statistics for it. You must specify the same dimensions that were used when the metrics were created. For an example, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#dimension-combinations">Dimension Combinations</a> in the <i>Amazon CloudWatch User Guide</i>. For more information about specifying dimensions, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   Namespace: string (required)
  ##            : The namespace of the metric, with or without spaces.
  ##   Version: string (required)
  var query_606827 = newJObject()
  var formData_606828 = newJObject()
  add(formData_606828, "Unit", newJString(Unit))
  add(formData_606828, "Period", newJInt(Period))
  if Statistics != nil:
    formData_606828.add "Statistics", Statistics
  if ExtendedStatistics != nil:
    formData_606828.add "ExtendedStatistics", ExtendedStatistics
  add(formData_606828, "EndTime", newJString(EndTime))
  add(formData_606828, "StartTime", newJString(StartTime))
  add(formData_606828, "MetricName", newJString(MetricName))
  add(query_606827, "Action", newJString(Action))
  if Dimensions != nil:
    formData_606828.add "Dimensions", Dimensions
  add(formData_606828, "Namespace", newJString(Namespace))
  add(query_606827, "Version", newJString(Version))
  result = call_606826.call(nil, query_606827, nil, formData_606828, nil)

var postGetMetricStatistics* = Call_PostGetMetricStatistics_606804(
    name: "postGetMetricStatistics", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_PostGetMetricStatistics_606805, base: "/",
    url: url_PostGetMetricStatistics_606806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricStatistics_606780 = ref object of OpenApiRestCall_605589
proc url_GetGetMetricStatistics_606782(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricStatistics_606781(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Unit: JString
  ##       : The unit for a given metric. If you omit <code>Unit</code>, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.
  ##   ExtendedStatistics: JArray
  ##                     : The percentile statistics. Specify values between p0.0 and p100. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both. Percentile statistics are not available for metrics when any of the metric values are negative numbers.
  ##   Namespace: JString (required)
  ##            : The namespace of the metric, with or without spaces.
  ##   Statistics: JArray
  ##             : The metric statistics, other than percentile. For percentile statistics, use <code>ExtendedStatistics</code>. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both.
  ##   Period: JInt (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  ##   Dimensions: JArray
  ##             : The dimensions. If the metric contains multiple dimensions, you must include a value for each dimension. CloudWatch treats each unique combination of dimensions as a separate metric. If a specific combination of dimensions was not published, you can't retrieve statistics for it. You must specify the same dimensions that were used when the metrics were created. For an example, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#dimension-combinations">Dimension Combinations</a> in the <i>Amazon CloudWatch User Guide</i>. For more information about specifying dimensions, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   Action: JString (required)
  ##   StartTime: JString (required)
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   EndTime: JString (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Version: JString (required)
  ##   MetricName: JString (required)
  ##             : The name of the metric, with or without spaces.
  section = newJObject()
  var valid_606783 = query.getOrDefault("Unit")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_606783 != nil:
    section.add "Unit", valid_606783
  var valid_606784 = query.getOrDefault("ExtendedStatistics")
  valid_606784 = validateParameter(valid_606784, JArray, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "ExtendedStatistics", valid_606784
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_606785 = query.getOrDefault("Namespace")
  valid_606785 = validateParameter(valid_606785, JString, required = true,
                                 default = nil)
  if valid_606785 != nil:
    section.add "Namespace", valid_606785
  var valid_606786 = query.getOrDefault("Statistics")
  valid_606786 = validateParameter(valid_606786, JArray, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "Statistics", valid_606786
  var valid_606787 = query.getOrDefault("Period")
  valid_606787 = validateParameter(valid_606787, JInt, required = true, default = nil)
  if valid_606787 != nil:
    section.add "Period", valid_606787
  var valid_606788 = query.getOrDefault("Dimensions")
  valid_606788 = validateParameter(valid_606788, JArray, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "Dimensions", valid_606788
  var valid_606789 = query.getOrDefault("Action")
  valid_606789 = validateParameter(valid_606789, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_606789 != nil:
    section.add "Action", valid_606789
  var valid_606790 = query.getOrDefault("StartTime")
  valid_606790 = validateParameter(valid_606790, JString, required = true,
                                 default = nil)
  if valid_606790 != nil:
    section.add "StartTime", valid_606790
  var valid_606791 = query.getOrDefault("EndTime")
  valid_606791 = validateParameter(valid_606791, JString, required = true,
                                 default = nil)
  if valid_606791 != nil:
    section.add "EndTime", valid_606791
  var valid_606792 = query.getOrDefault("Version")
  valid_606792 = validateParameter(valid_606792, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606792 != nil:
    section.add "Version", valid_606792
  var valid_606793 = query.getOrDefault("MetricName")
  valid_606793 = validateParameter(valid_606793, JString, required = true,
                                 default = nil)
  if valid_606793 != nil:
    section.add "MetricName", valid_606793
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606794 = header.getOrDefault("X-Amz-Signature")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Signature", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Content-Sha256", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Date")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Date", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Credential")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Credential", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Security-Token")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Security-Token", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Algorithm")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Algorithm", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-SignedHeaders", valid_606800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606801: Call_GetGetMetricStatistics_606780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_606801.validator(path, query, header, formData, body)
  let scheme = call_606801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606801.url(scheme.get, call_606801.host, call_606801.base,
                         call_606801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606801, url, valid)

proc call*(call_606802: Call_GetGetMetricStatistics_606780; Namespace: string;
          Period: int; StartTime: string; EndTime: string; MetricName: string;
          Unit: string = "Seconds"; ExtendedStatistics: JsonNode = nil;
          Statistics: JsonNode = nil; Dimensions: JsonNode = nil;
          Action: string = "GetMetricStatistics"; Version: string = "2010-08-01"): Recallable =
  ## getGetMetricStatistics
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ##   Unit: string
  ##       : The unit for a given metric. If you omit <code>Unit</code>, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.
  ##   ExtendedStatistics: JArray
  ##                     : The percentile statistics. Specify values between p0.0 and p100. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both. Percentile statistics are not available for metrics when any of the metric values are negative numbers.
  ##   Namespace: string (required)
  ##            : The namespace of the metric, with or without spaces.
  ##   Statistics: JArray
  ##             : The metric statistics, other than percentile. For percentile statistics, use <code>ExtendedStatistics</code>. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both.
  ##   Period: int (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  ##   Dimensions: JArray
  ##             : The dimensions. If the metric contains multiple dimensions, you must include a value for each dimension. CloudWatch treats each unique combination of dimensions as a separate metric. If a specific combination of dimensions was not published, you can't retrieve statistics for it. You must specify the same dimensions that were used when the metrics were created. For an example, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#dimension-combinations">Dimension Combinations</a> in the <i>Amazon CloudWatch User Guide</i>. For more information about specifying dimensions, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   Action: string (required)
  ##   StartTime: string (required)
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   EndTime: string (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. In a raw HTTP query, the time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Version: string (required)
  ##   MetricName: string (required)
  ##             : The name of the metric, with or without spaces.
  var query_606803 = newJObject()
  add(query_606803, "Unit", newJString(Unit))
  if ExtendedStatistics != nil:
    query_606803.add "ExtendedStatistics", ExtendedStatistics
  add(query_606803, "Namespace", newJString(Namespace))
  if Statistics != nil:
    query_606803.add "Statistics", Statistics
  add(query_606803, "Period", newJInt(Period))
  if Dimensions != nil:
    query_606803.add "Dimensions", Dimensions
  add(query_606803, "Action", newJString(Action))
  add(query_606803, "StartTime", newJString(StartTime))
  add(query_606803, "EndTime", newJString(EndTime))
  add(query_606803, "Version", newJString(Version))
  add(query_606803, "MetricName", newJString(MetricName))
  result = call_606802.call(nil, query_606803, nil, nil, nil)

var getGetMetricStatistics* = Call_GetGetMetricStatistics_606780(
    name: "getGetMetricStatistics", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_GetGetMetricStatistics_606781, base: "/",
    url: url_GetGetMetricStatistics_606782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricWidgetImage_606846 = ref object of OpenApiRestCall_605589
proc url_PostGetMetricWidgetImage_606848(protocol: Scheme; host: string;
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

proc validate_PostGetMetricWidgetImage_606847(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606849 = query.getOrDefault("Action")
  valid_606849 = validateParameter(valid_606849, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_606849 != nil:
    section.add "Action", valid_606849
  var valid_606850 = query.getOrDefault("Version")
  valid_606850 = validateParameter(valid_606850, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606850 != nil:
    section.add "Version", valid_606850
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606851 = header.getOrDefault("X-Amz-Signature")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-Signature", valid_606851
  var valid_606852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "X-Amz-Content-Sha256", valid_606852
  var valid_606853 = header.getOrDefault("X-Amz-Date")
  valid_606853 = validateParameter(valid_606853, JString, required = false,
                                 default = nil)
  if valid_606853 != nil:
    section.add "X-Amz-Date", valid_606853
  var valid_606854 = header.getOrDefault("X-Amz-Credential")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-Credential", valid_606854
  var valid_606855 = header.getOrDefault("X-Amz-Security-Token")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Security-Token", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Algorithm")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Algorithm", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-SignedHeaders", valid_606857
  result.add "header", section
  ## parameters in `formData` object:
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MetricWidget` field"
  var valid_606858 = formData.getOrDefault("MetricWidget")
  valid_606858 = validateParameter(valid_606858, JString, required = true,
                                 default = nil)
  if valid_606858 != nil:
    section.add "MetricWidget", valid_606858
  var valid_606859 = formData.getOrDefault("OutputFormat")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "OutputFormat", valid_606859
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606860: Call_PostGetMetricWidgetImage_606846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_606860.validator(path, query, header, formData, body)
  let scheme = call_606860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606860.url(scheme.get, call_606860.host, call_606860.base,
                         call_606860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606860, url, valid)

proc call*(call_606861: Call_PostGetMetricWidgetImage_606846; MetricWidget: string;
          OutputFormat: string = ""; Action: string = "GetMetricWidgetImage";
          Version: string = "2010-08-01"): Recallable =
  ## postGetMetricWidgetImage
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ##   MetricWidget: string (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   OutputFormat: string
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606862 = newJObject()
  var formData_606863 = newJObject()
  add(formData_606863, "MetricWidget", newJString(MetricWidget))
  add(formData_606863, "OutputFormat", newJString(OutputFormat))
  add(query_606862, "Action", newJString(Action))
  add(query_606862, "Version", newJString(Version))
  result = call_606861.call(nil, query_606862, nil, formData_606863, nil)

var postGetMetricWidgetImage* = Call_PostGetMetricWidgetImage_606846(
    name: "postGetMetricWidgetImage", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_PostGetMetricWidgetImage_606847, base: "/",
    url: url_PostGetMetricWidgetImage_606848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricWidgetImage_606829 = ref object of OpenApiRestCall_605589
proc url_GetGetMetricWidgetImage_606831(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetGetMetricWidgetImage_606830(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606832 = query.getOrDefault("OutputFormat")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "OutputFormat", valid_606832
  assert query != nil,
        "query argument is necessary due to required `MetricWidget` field"
  var valid_606833 = query.getOrDefault("MetricWidget")
  valid_606833 = validateParameter(valid_606833, JString, required = true,
                                 default = nil)
  if valid_606833 != nil:
    section.add "MetricWidget", valid_606833
  var valid_606834 = query.getOrDefault("Action")
  valid_606834 = validateParameter(valid_606834, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_606834 != nil:
    section.add "Action", valid_606834
  var valid_606835 = query.getOrDefault("Version")
  valid_606835 = validateParameter(valid_606835, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606835 != nil:
    section.add "Version", valid_606835
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606836 = header.getOrDefault("X-Amz-Signature")
  valid_606836 = validateParameter(valid_606836, JString, required = false,
                                 default = nil)
  if valid_606836 != nil:
    section.add "X-Amz-Signature", valid_606836
  var valid_606837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606837 = validateParameter(valid_606837, JString, required = false,
                                 default = nil)
  if valid_606837 != nil:
    section.add "X-Amz-Content-Sha256", valid_606837
  var valid_606838 = header.getOrDefault("X-Amz-Date")
  valid_606838 = validateParameter(valid_606838, JString, required = false,
                                 default = nil)
  if valid_606838 != nil:
    section.add "X-Amz-Date", valid_606838
  var valid_606839 = header.getOrDefault("X-Amz-Credential")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "X-Amz-Credential", valid_606839
  var valid_606840 = header.getOrDefault("X-Amz-Security-Token")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Security-Token", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Algorithm")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Algorithm", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-SignedHeaders", valid_606842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606843: Call_GetGetMetricWidgetImage_606829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_606843.validator(path, query, header, formData, body)
  let scheme = call_606843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606843.url(scheme.get, call_606843.host, call_606843.base,
                         call_606843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606843, url, valid)

proc call*(call_606844: Call_GetGetMetricWidgetImage_606829; MetricWidget: string;
          OutputFormat: string = ""; Action: string = "GetMetricWidgetImage";
          Version: string = "2010-08-01"): Recallable =
  ## getGetMetricWidgetImage
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ##   OutputFormat: string
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   MetricWidget: string (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606845 = newJObject()
  add(query_606845, "OutputFormat", newJString(OutputFormat))
  add(query_606845, "MetricWidget", newJString(MetricWidget))
  add(query_606845, "Action", newJString(Action))
  add(query_606845, "Version", newJString(Version))
  result = call_606844.call(nil, query_606845, nil, nil, nil)

var getGetMetricWidgetImage* = Call_GetGetMetricWidgetImage_606829(
    name: "getGetMetricWidgetImage", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_GetGetMetricWidgetImage_606830, base: "/",
    url: url_GetGetMetricWidgetImage_606831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDashboards_606881 = ref object of OpenApiRestCall_605589
proc url_PostListDashboards_606883(protocol: Scheme; host: string; base: string;
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

proc validate_PostListDashboards_606882(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606884 = query.getOrDefault("Action")
  valid_606884 = validateParameter(valid_606884, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_606884 != nil:
    section.add "Action", valid_606884
  var valid_606885 = query.getOrDefault("Version")
  valid_606885 = validateParameter(valid_606885, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606885 != nil:
    section.add "Version", valid_606885
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606886 = header.getOrDefault("X-Amz-Signature")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Signature", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Content-Sha256", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-Date")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Date", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-Credential")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Credential", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Security-Token")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Security-Token", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Algorithm")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Algorithm", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-SignedHeaders", valid_606892
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   DashboardNamePrefix: JString
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  section = newJObject()
  var valid_606893 = formData.getOrDefault("NextToken")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "NextToken", valid_606893
  var valid_606894 = formData.getOrDefault("DashboardNamePrefix")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "DashboardNamePrefix", valid_606894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606895: Call_PostListDashboards_606881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_606895.validator(path, query, header, formData, body)
  let scheme = call_606895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606895.url(scheme.get, call_606895.host, call_606895.base,
                         call_606895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606895, url, valid)

proc call*(call_606896: Call_PostListDashboards_606881; NextToken: string = "";
          DashboardNamePrefix: string = ""; Action: string = "ListDashboards";
          Version: string = "2010-08-01"): Recallable =
  ## postListDashboards
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   DashboardNamePrefix: string
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606897 = newJObject()
  var formData_606898 = newJObject()
  add(formData_606898, "NextToken", newJString(NextToken))
  add(formData_606898, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_606897, "Action", newJString(Action))
  add(query_606897, "Version", newJString(Version))
  result = call_606896.call(nil, query_606897, nil, formData_606898, nil)

var postListDashboards* = Call_PostListDashboards_606881(
    name: "postListDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListDashboards",
    validator: validate_PostListDashboards_606882, base: "/",
    url: url_PostListDashboards_606883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDashboards_606864 = ref object of OpenApiRestCall_605589
proc url_GetListDashboards_606866(protocol: Scheme; host: string; base: string;
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

proc validate_GetListDashboards_606865(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_606867 = query.getOrDefault("DashboardNamePrefix")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "DashboardNamePrefix", valid_606867
  var valid_606868 = query.getOrDefault("NextToken")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "NextToken", valid_606868
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606869 = query.getOrDefault("Action")
  valid_606869 = validateParameter(valid_606869, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_606869 != nil:
    section.add "Action", valid_606869
  var valid_606870 = query.getOrDefault("Version")
  valid_606870 = validateParameter(valid_606870, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606870 != nil:
    section.add "Version", valid_606870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606871 = header.getOrDefault("X-Amz-Signature")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Signature", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Content-Sha256", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-Date")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Date", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Credential")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Credential", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Security-Token")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Security-Token", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Algorithm")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Algorithm", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-SignedHeaders", valid_606877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606878: Call_GetListDashboards_606864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_606878.validator(path, query, header, formData, body)
  let scheme = call_606878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606878.url(scheme.get, call_606878.host, call_606878.base,
                         call_606878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606878, url, valid)

proc call*(call_606879: Call_GetListDashboards_606864;
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
  var query_606880 = newJObject()
  add(query_606880, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_606880, "NextToken", newJString(NextToken))
  add(query_606880, "Action", newJString(Action))
  add(query_606880, "Version", newJString(Version))
  result = call_606879.call(nil, query_606880, nil, nil, nil)

var getListDashboards* = Call_GetListDashboards_606864(name: "getListDashboards",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListDashboards", validator: validate_GetListDashboards_606865,
    base: "/", url: url_GetListDashboards_606866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListMetrics_606918 = ref object of OpenApiRestCall_605589
proc url_PostListMetrics_606920(protocol: Scheme; host: string; base: string;
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

proc validate_PostListMetrics_606919(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606921 = query.getOrDefault("Action")
  valid_606921 = validateParameter(valid_606921, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_606921 != nil:
    section.add "Action", valid_606921
  var valid_606922 = query.getOrDefault("Version")
  valid_606922 = validateParameter(valid_606922, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606922 != nil:
    section.add "Version", valid_606922
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606923 = header.getOrDefault("X-Amz-Signature")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Signature", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Content-Sha256", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Date")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Date", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-Credential")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-Credential", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-Security-Token")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-Security-Token", valid_606927
  var valid_606928 = header.getOrDefault("X-Amz-Algorithm")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "X-Amz-Algorithm", valid_606928
  var valid_606929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-SignedHeaders", valid_606929
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
  var valid_606930 = formData.getOrDefault("NextToken")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "NextToken", valid_606930
  var valid_606931 = formData.getOrDefault("MetricName")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "MetricName", valid_606931
  var valid_606932 = formData.getOrDefault("Dimensions")
  valid_606932 = validateParameter(valid_606932, JArray, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "Dimensions", valid_606932
  var valid_606933 = formData.getOrDefault("Namespace")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "Namespace", valid_606933
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606934: Call_PostListMetrics_606918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_606934.validator(path, query, header, formData, body)
  let scheme = call_606934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606934.url(scheme.get, call_606934.host, call_606934.base,
                         call_606934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606934, url, valid)

proc call*(call_606935: Call_PostListMetrics_606918; NextToken: string = "";
          MetricName: string = ""; Action: string = "ListMetrics";
          Dimensions: JsonNode = nil; Namespace: string = "";
          Version: string = "2010-08-01"): Recallable =
  ## postListMetrics
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   MetricName: string
  ##             : The name of the metric to filter against.
  ##   Action: string (required)
  ##   Dimensions: JArray
  ##             : The dimensions to filter against.
  ##   Namespace: string
  ##            : The namespace to filter against.
  ##   Version: string (required)
  var query_606936 = newJObject()
  var formData_606937 = newJObject()
  add(formData_606937, "NextToken", newJString(NextToken))
  add(formData_606937, "MetricName", newJString(MetricName))
  add(query_606936, "Action", newJString(Action))
  if Dimensions != nil:
    formData_606937.add "Dimensions", Dimensions
  add(formData_606937, "Namespace", newJString(Namespace))
  add(query_606936, "Version", newJString(Version))
  result = call_606935.call(nil, query_606936, nil, formData_606937, nil)

var postListMetrics* = Call_PostListMetrics_606918(name: "postListMetrics",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_PostListMetrics_606919,
    base: "/", url: url_PostListMetrics_606920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListMetrics_606899 = ref object of OpenApiRestCall_605589
proc url_GetListMetrics_606901(protocol: Scheme; host: string; base: string;
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

proc validate_GetListMetrics_606900(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Namespace: JString
  ##            : The namespace to filter against.
  ##   Dimensions: JArray
  ##             : The dimensions to filter against.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MetricName: JString
  ##             : The name of the metric to filter against.
  section = newJObject()
  var valid_606902 = query.getOrDefault("NextToken")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "NextToken", valid_606902
  var valid_606903 = query.getOrDefault("Namespace")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "Namespace", valid_606903
  var valid_606904 = query.getOrDefault("Dimensions")
  valid_606904 = validateParameter(valid_606904, JArray, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "Dimensions", valid_606904
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606905 = query.getOrDefault("Action")
  valid_606905 = validateParameter(valid_606905, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_606905 != nil:
    section.add "Action", valid_606905
  var valid_606906 = query.getOrDefault("Version")
  valid_606906 = validateParameter(valid_606906, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606906 != nil:
    section.add "Version", valid_606906
  var valid_606907 = query.getOrDefault("MetricName")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "MetricName", valid_606907
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606908 = header.getOrDefault("X-Amz-Signature")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Signature", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Content-Sha256", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-Date")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-Date", valid_606910
  var valid_606911 = header.getOrDefault("X-Amz-Credential")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-Credential", valid_606911
  var valid_606912 = header.getOrDefault("X-Amz-Security-Token")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-Security-Token", valid_606912
  var valid_606913 = header.getOrDefault("X-Amz-Algorithm")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "X-Amz-Algorithm", valid_606913
  var valid_606914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-SignedHeaders", valid_606914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606915: Call_GetListMetrics_606899; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_606915.validator(path, query, header, formData, body)
  let scheme = call_606915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606915.url(scheme.get, call_606915.host, call_606915.base,
                         call_606915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606915, url, valid)

proc call*(call_606916: Call_GetListMetrics_606899; NextToken: string = "";
          Namespace: string = ""; Dimensions: JsonNode = nil;
          Action: string = "ListMetrics"; Version: string = "2010-08-01";
          MetricName: string = ""): Recallable =
  ## getListMetrics
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ##   NextToken: string
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   Namespace: string
  ##            : The namespace to filter against.
  ##   Dimensions: JArray
  ##             : The dimensions to filter against.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricName: string
  ##             : The name of the metric to filter against.
  var query_606917 = newJObject()
  add(query_606917, "NextToken", newJString(NextToken))
  add(query_606917, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_606917.add "Dimensions", Dimensions
  add(query_606917, "Action", newJString(Action))
  add(query_606917, "Version", newJString(Version))
  add(query_606917, "MetricName", newJString(MetricName))
  result = call_606916.call(nil, query_606917, nil, nil, nil)

var getListMetrics* = Call_GetListMetrics_606899(name: "getListMetrics",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_GetListMetrics_606900,
    base: "/", url: url_GetListMetrics_606901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_606954 = ref object of OpenApiRestCall_605589
proc url_PostListTagsForResource_606956(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostListTagsForResource_606955(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606957 = query.getOrDefault("Action")
  valid_606957 = validateParameter(valid_606957, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_606957 != nil:
    section.add "Action", valid_606957
  var valid_606958 = query.getOrDefault("Version")
  valid_606958 = validateParameter(valid_606958, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606958 != nil:
    section.add "Version", valid_606958
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606959 = header.getOrDefault("X-Amz-Signature")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Signature", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Content-Sha256", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Date")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Date", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Credential")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Credential", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Security-Token")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Security-Token", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-Algorithm")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-Algorithm", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-SignedHeaders", valid_606965
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceARN` field"
  var valid_606966 = formData.getOrDefault("ResourceARN")
  valid_606966 = validateParameter(valid_606966, JString, required = true,
                                 default = nil)
  if valid_606966 != nil:
    section.add "ResourceARN", valid_606966
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606967: Call_PostListTagsForResource_606954; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_606967.validator(path, query, header, formData, body)
  let scheme = call_606967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606967.url(scheme.get, call_606967.host, call_606967.base,
                         call_606967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606967, url, valid)

proc call*(call_606968: Call_PostListTagsForResource_606954; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## postListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  var query_606969 = newJObject()
  var formData_606970 = newJObject()
  add(query_606969, "Action", newJString(Action))
  add(query_606969, "Version", newJString(Version))
  add(formData_606970, "ResourceARN", newJString(ResourceARN))
  result = call_606968.call(nil, query_606969, nil, formData_606970, nil)

var postListTagsForResource* = Call_PostListTagsForResource_606954(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_606955, base: "/",
    url: url_PostListTagsForResource_606956, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_606938 = ref object of OpenApiRestCall_605589
proc url_GetListTagsForResource_606940(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_606939(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606941 = query.getOrDefault("Action")
  valid_606941 = validateParameter(valid_606941, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_606941 != nil:
    section.add "Action", valid_606941
  var valid_606942 = query.getOrDefault("ResourceARN")
  valid_606942 = validateParameter(valid_606942, JString, required = true,
                                 default = nil)
  if valid_606942 != nil:
    section.add "ResourceARN", valid_606942
  var valid_606943 = query.getOrDefault("Version")
  valid_606943 = validateParameter(valid_606943, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606943 != nil:
    section.add "Version", valid_606943
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606944 = header.getOrDefault("X-Amz-Signature")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Signature", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Content-Sha256", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Date")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Date", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Credential")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Credential", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Security-Token")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Security-Token", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-Algorithm")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Algorithm", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-SignedHeaders", valid_606950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606951: Call_GetListTagsForResource_606938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_606951.validator(path, query, header, formData, body)
  let scheme = call_606951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606951.url(scheme.get, call_606951.host, call_606951.base,
                         call_606951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606951, url, valid)

proc call*(call_606952: Call_GetListTagsForResource_606938; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## getListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_606953 = newJObject()
  add(query_606953, "Action", newJString(Action))
  add(query_606953, "ResourceARN", newJString(ResourceARN))
  add(query_606953, "Version", newJString(Version))
  result = call_606952.call(nil, query_606953, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_606938(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_606939, base: "/",
    url: url_GetListTagsForResource_606940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAnomalyDetector_606992 = ref object of OpenApiRestCall_605589
proc url_PostPutAnomalyDetector_606994(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutAnomalyDetector_606993(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606995 = query.getOrDefault("Action")
  valid_606995 = validateParameter(valid_606995, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_606995 != nil:
    section.add "Action", valid_606995
  var valid_606996 = query.getOrDefault("Version")
  valid_606996 = validateParameter(valid_606996, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606996 != nil:
    section.add "Version", valid_606996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606997 = header.getOrDefault("X-Amz-Signature")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Signature", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Content-Sha256", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Date")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Date", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-Credential")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-Credential", valid_607000
  var valid_607001 = header.getOrDefault("X-Amz-Security-Token")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "X-Amz-Security-Token", valid_607001
  var valid_607002 = header.getOrDefault("X-Amz-Algorithm")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "X-Amz-Algorithm", valid_607002
  var valid_607003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607003 = validateParameter(valid_607003, JString, required = false,
                                 default = nil)
  if valid_607003 != nil:
    section.add "X-Amz-SignedHeaders", valid_607003
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stat: JString (required)
  ##       : The statistic to use for the metric and the anomaly detection model.
  ##   Configuration.MetricTimezone: JString
  ##                               : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## <p>The time zone to use for the metric. This is useful to enable the model to automatically account for daylight savings time changes if the metric is sensitive to such time changes.</p> <p>To specify a time zone, use the name of the time zone as specified in the standard tz database. For more information, see <a href="https://en.wikipedia.org/wiki/Tz_database">tz database</a>.</p>
  ##   MetricName: JString (required)
  ##             : The name of the metric to create the anomaly detection model for.
  ##   Dimensions: JArray
  ##             : The metric dimensions to create the anomaly detection model for.
  ##   Namespace: JString (required)
  ##            : The namespace of the metric to create the anomaly detection model for.
  ##   Configuration.ExcludedTimeRanges: JArray
  ##                                   : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## An array of time ranges to exclude from use when the anomaly detection model is trained. Use this to make sure that events that could cause unusual values for the metric, such as deployments, aren't used when CloudWatch creates the model.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stat` field"
  var valid_607004 = formData.getOrDefault("Stat")
  valid_607004 = validateParameter(valid_607004, JString, required = true,
                                 default = nil)
  if valid_607004 != nil:
    section.add "Stat", valid_607004
  var valid_607005 = formData.getOrDefault("Configuration.MetricTimezone")
  valid_607005 = validateParameter(valid_607005, JString, required = false,
                                 default = nil)
  if valid_607005 != nil:
    section.add "Configuration.MetricTimezone", valid_607005
  var valid_607006 = formData.getOrDefault("MetricName")
  valid_607006 = validateParameter(valid_607006, JString, required = true,
                                 default = nil)
  if valid_607006 != nil:
    section.add "MetricName", valid_607006
  var valid_607007 = formData.getOrDefault("Dimensions")
  valid_607007 = validateParameter(valid_607007, JArray, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "Dimensions", valid_607007
  var valid_607008 = formData.getOrDefault("Namespace")
  valid_607008 = validateParameter(valid_607008, JString, required = true,
                                 default = nil)
  if valid_607008 != nil:
    section.add "Namespace", valid_607008
  var valid_607009 = formData.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_607009 = validateParameter(valid_607009, JArray, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_607009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607010: Call_PostPutAnomalyDetector_606992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_607010.validator(path, query, header, formData, body)
  let scheme = call_607010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607010.url(scheme.get, call_607010.host, call_607010.base,
                         call_607010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607010, url, valid)

proc call*(call_607011: Call_PostPutAnomalyDetector_606992; Stat: string;
          MetricName: string; Namespace: string;
          ConfigurationMetricTimezone: string = "";
          Action: string = "PutAnomalyDetector"; Dimensions: JsonNode = nil;
          ConfigurationExcludedTimeRanges: JsonNode = nil;
          Version: string = "2010-08-01"): Recallable =
  ## postPutAnomalyDetector
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ##   Stat: string (required)
  ##       : The statistic to use for the metric and the anomaly detection model.
  ##   ConfigurationMetricTimezone: string
  ##                              : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## <p>The time zone to use for the metric. This is useful to enable the model to automatically account for daylight savings time changes if the metric is sensitive to such time changes.</p> <p>To specify a time zone, use the name of the time zone as specified in the standard tz database. For more information, see <a href="https://en.wikipedia.org/wiki/Tz_database">tz database</a>.</p>
  ##   MetricName: string (required)
  ##             : The name of the metric to create the anomaly detection model for.
  ##   Action: string (required)
  ##   Dimensions: JArray
  ##             : The metric dimensions to create the anomaly detection model for.
  ##   Namespace: string (required)
  ##            : The namespace of the metric to create the anomaly detection model for.
  ##   ConfigurationExcludedTimeRanges: JArray
  ##                                  : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## An array of time ranges to exclude from use when the anomaly detection model is trained. Use this to make sure that events that could cause unusual values for the metric, such as deployments, aren't used when CloudWatch creates the model.
  ##   Version: string (required)
  var query_607012 = newJObject()
  var formData_607013 = newJObject()
  add(formData_607013, "Stat", newJString(Stat))
  add(formData_607013, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  add(formData_607013, "MetricName", newJString(MetricName))
  add(query_607012, "Action", newJString(Action))
  if Dimensions != nil:
    formData_607013.add "Dimensions", Dimensions
  add(formData_607013, "Namespace", newJString(Namespace))
  if ConfigurationExcludedTimeRanges != nil:
    formData_607013.add "Configuration.ExcludedTimeRanges",
                       ConfigurationExcludedTimeRanges
  add(query_607012, "Version", newJString(Version))
  result = call_607011.call(nil, query_607012, nil, formData_607013, nil)

var postPutAnomalyDetector* = Call_PostPutAnomalyDetector_606992(
    name: "postPutAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_PostPutAnomalyDetector_606993, base: "/",
    url: url_PostPutAnomalyDetector_606994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAnomalyDetector_606971 = ref object of OpenApiRestCall_605589
proc url_GetPutAnomalyDetector_606973(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutAnomalyDetector_606972(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString (required)
  ##            : The namespace of the metric to create the anomaly detection model for.
  ##   Configuration.MetricTimezone: JString
  ##                               : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## <p>The time zone to use for the metric. This is useful to enable the model to automatically account for daylight savings time changes if the metric is sensitive to such time changes.</p> <p>To specify a time zone, use the name of the time zone as specified in the standard tz database. For more information, see <a href="https://en.wikipedia.org/wiki/Tz_database">tz database</a>.</p>
  ##   Configuration.ExcludedTimeRanges: JArray
  ##                                   : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## An array of time ranges to exclude from use when the anomaly detection model is trained. Use this to make sure that events that could cause unusual values for the metric, such as deployments, aren't used when CloudWatch creates the model.
  ##   Dimensions: JArray
  ##             : The metric dimensions to create the anomaly detection model for.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MetricName: JString (required)
  ##             : The name of the metric to create the anomaly detection model for.
  ##   Stat: JString (required)
  ##       : The statistic to use for the metric and the anomaly detection model.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_606974 = query.getOrDefault("Namespace")
  valid_606974 = validateParameter(valid_606974, JString, required = true,
                                 default = nil)
  if valid_606974 != nil:
    section.add "Namespace", valid_606974
  var valid_606975 = query.getOrDefault("Configuration.MetricTimezone")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "Configuration.MetricTimezone", valid_606975
  var valid_606976 = query.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_606976 = validateParameter(valid_606976, JArray, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_606976
  var valid_606977 = query.getOrDefault("Dimensions")
  valid_606977 = validateParameter(valid_606977, JArray, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "Dimensions", valid_606977
  var valid_606978 = query.getOrDefault("Action")
  valid_606978 = validateParameter(valid_606978, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_606978 != nil:
    section.add "Action", valid_606978
  var valid_606979 = query.getOrDefault("Version")
  valid_606979 = validateParameter(valid_606979, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_606979 != nil:
    section.add "Version", valid_606979
  var valid_606980 = query.getOrDefault("MetricName")
  valid_606980 = validateParameter(valid_606980, JString, required = true,
                                 default = nil)
  if valid_606980 != nil:
    section.add "MetricName", valid_606980
  var valid_606981 = query.getOrDefault("Stat")
  valid_606981 = validateParameter(valid_606981, JString, required = true,
                                 default = nil)
  if valid_606981 != nil:
    section.add "Stat", valid_606981
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606982 = header.getOrDefault("X-Amz-Signature")
  valid_606982 = validateParameter(valid_606982, JString, required = false,
                                 default = nil)
  if valid_606982 != nil:
    section.add "X-Amz-Signature", valid_606982
  var valid_606983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-Content-Sha256", valid_606983
  var valid_606984 = header.getOrDefault("X-Amz-Date")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "X-Amz-Date", valid_606984
  var valid_606985 = header.getOrDefault("X-Amz-Credential")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-Credential", valid_606985
  var valid_606986 = header.getOrDefault("X-Amz-Security-Token")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-Security-Token", valid_606986
  var valid_606987 = header.getOrDefault("X-Amz-Algorithm")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-Algorithm", valid_606987
  var valid_606988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606988 = validateParameter(valid_606988, JString, required = false,
                                 default = nil)
  if valid_606988 != nil:
    section.add "X-Amz-SignedHeaders", valid_606988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606989: Call_GetPutAnomalyDetector_606971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_606989.validator(path, query, header, formData, body)
  let scheme = call_606989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606989.url(scheme.get, call_606989.host, call_606989.base,
                         call_606989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606989, url, valid)

proc call*(call_606990: Call_GetPutAnomalyDetector_606971; Namespace: string;
          MetricName: string; Stat: string;
          ConfigurationMetricTimezone: string = "";
          ConfigurationExcludedTimeRanges: JsonNode = nil;
          Dimensions: JsonNode = nil; Action: string = "PutAnomalyDetector";
          Version: string = "2010-08-01"): Recallable =
  ## getPutAnomalyDetector
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ##   Namespace: string (required)
  ##            : The namespace of the metric to create the anomaly detection model for.
  ##   ConfigurationMetricTimezone: string
  ##                              : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## <p>The time zone to use for the metric. This is useful to enable the model to automatically account for daylight savings time changes if the metric is sensitive to such time changes.</p> <p>To specify a time zone, use the name of the time zone as specified in the standard tz database. For more information, see <a href="https://en.wikipedia.org/wiki/Tz_database">tz database</a>.</p>
  ##   ConfigurationExcludedTimeRanges: JArray
  ##                                  : The configuration specifies details about how the anomaly detection model is to be trained, including time ranges to exclude from use for training the model and the time zone to use for the metric.
  ## An array of time ranges to exclude from use when the anomaly detection model is trained. Use this to make sure that events that could cause unusual values for the metric, such as deployments, aren't used when CloudWatch creates the model.
  ##   Dimensions: JArray
  ##             : The metric dimensions to create the anomaly detection model for.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricName: string (required)
  ##             : The name of the metric to create the anomaly detection model for.
  ##   Stat: string (required)
  ##       : The statistic to use for the metric and the anomaly detection model.
  var query_606991 = newJObject()
  add(query_606991, "Namespace", newJString(Namespace))
  add(query_606991, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  if ConfigurationExcludedTimeRanges != nil:
    query_606991.add "Configuration.ExcludedTimeRanges",
                    ConfigurationExcludedTimeRanges
  if Dimensions != nil:
    query_606991.add "Dimensions", Dimensions
  add(query_606991, "Action", newJString(Action))
  add(query_606991, "Version", newJString(Version))
  add(query_606991, "MetricName", newJString(MetricName))
  add(query_606991, "Stat", newJString(Stat))
  result = call_606990.call(nil, query_606991, nil, nil, nil)

var getPutAnomalyDetector* = Call_GetPutAnomalyDetector_606971(
    name: "getPutAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_GetPutAnomalyDetector_606972, base: "/",
    url: url_GetPutAnomalyDetector_606973, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutDashboard_607031 = ref object of OpenApiRestCall_605589
proc url_PostPutDashboard_607033(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutDashboard_607032(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607034 = query.getOrDefault("Action")
  valid_607034 = validateParameter(valid_607034, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_607034 != nil:
    section.add "Action", valid_607034
  var valid_607035 = query.getOrDefault("Version")
  valid_607035 = validateParameter(valid_607035, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607035 != nil:
    section.add "Version", valid_607035
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607036 = header.getOrDefault("X-Amz-Signature")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Signature", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Content-Sha256", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Date")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Date", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-Credential")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-Credential", valid_607039
  var valid_607040 = header.getOrDefault("X-Amz-Security-Token")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "X-Amz-Security-Token", valid_607040
  var valid_607041 = header.getOrDefault("X-Amz-Algorithm")
  valid_607041 = validateParameter(valid_607041, JString, required = false,
                                 default = nil)
  if valid_607041 != nil:
    section.add "X-Amz-Algorithm", valid_607041
  var valid_607042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "X-Amz-SignedHeaders", valid_607042
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_607043 = formData.getOrDefault("DashboardName")
  valid_607043 = validateParameter(valid_607043, JString, required = true,
                                 default = nil)
  if valid_607043 != nil:
    section.add "DashboardName", valid_607043
  var valid_607044 = formData.getOrDefault("DashboardBody")
  valid_607044 = validateParameter(valid_607044, JString, required = true,
                                 default = nil)
  if valid_607044 != nil:
    section.add "DashboardBody", valid_607044
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607045: Call_PostPutDashboard_607031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_607045.validator(path, query, header, formData, body)
  let scheme = call_607045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607045.url(scheme.get, call_607045.host, call_607045.base,
                         call_607045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607045, url, valid)

proc call*(call_607046: Call_PostPutDashboard_607031; DashboardName: string;
          DashboardBody: string; Action: string = "PutDashboard";
          Version: string = "2010-08-01"): Recallable =
  ## postPutDashboard
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   Action: string (required)
  ##   DashboardBody: string (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  ##   Version: string (required)
  var query_607047 = newJObject()
  var formData_607048 = newJObject()
  add(formData_607048, "DashboardName", newJString(DashboardName))
  add(query_607047, "Action", newJString(Action))
  add(formData_607048, "DashboardBody", newJString(DashboardBody))
  add(query_607047, "Version", newJString(Version))
  result = call_607046.call(nil, query_607047, nil, formData_607048, nil)

var postPutDashboard* = Call_PostPutDashboard_607031(name: "postPutDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_PostPutDashboard_607032,
    base: "/", url: url_PostPutDashboard_607033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutDashboard_607014 = ref object of OpenApiRestCall_605589
proc url_GetPutDashboard_607016(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutDashboard_607015(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  ##   Action: JString (required)
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DashboardBody` field"
  var valid_607017 = query.getOrDefault("DashboardBody")
  valid_607017 = validateParameter(valid_607017, JString, required = true,
                                 default = nil)
  if valid_607017 != nil:
    section.add "DashboardBody", valid_607017
  var valid_607018 = query.getOrDefault("Action")
  valid_607018 = validateParameter(valid_607018, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_607018 != nil:
    section.add "Action", valid_607018
  var valid_607019 = query.getOrDefault("DashboardName")
  valid_607019 = validateParameter(valid_607019, JString, required = true,
                                 default = nil)
  if valid_607019 != nil:
    section.add "DashboardName", valid_607019
  var valid_607020 = query.getOrDefault("Version")
  valid_607020 = validateParameter(valid_607020, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607020 != nil:
    section.add "Version", valid_607020
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607021 = header.getOrDefault("X-Amz-Signature")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Signature", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Content-Sha256", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Date")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Date", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-Credential")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Credential", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-Security-Token")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-Security-Token", valid_607025
  var valid_607026 = header.getOrDefault("X-Amz-Algorithm")
  valid_607026 = validateParameter(valid_607026, JString, required = false,
                                 default = nil)
  if valid_607026 != nil:
    section.add "X-Amz-Algorithm", valid_607026
  var valid_607027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607027 = validateParameter(valid_607027, JString, required = false,
                                 default = nil)
  if valid_607027 != nil:
    section.add "X-Amz-SignedHeaders", valid_607027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607028: Call_GetPutDashboard_607014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_607028.validator(path, query, header, formData, body)
  let scheme = call_607028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607028.url(scheme.get, call_607028.host, call_607028.base,
                         call_607028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607028, url, valid)

proc call*(call_607029: Call_GetPutDashboard_607014; DashboardBody: string;
          DashboardName: string; Action: string = "PutDashboard";
          Version: string = "2010-08-01"): Recallable =
  ## getPutDashboard
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ##   DashboardBody: string (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   Version: string (required)
  var query_607030 = newJObject()
  add(query_607030, "DashboardBody", newJString(DashboardBody))
  add(query_607030, "Action", newJString(Action))
  add(query_607030, "DashboardName", newJString(DashboardName))
  add(query_607030, "Version", newJString(Version))
  result = call_607029.call(nil, query_607030, nil, nil, nil)

var getPutDashboard* = Call_GetPutDashboard_607014(name: "getPutDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_GetPutDashboard_607015,
    base: "/", url: url_GetPutDashboard_607016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutInsightRule_607067 = ref object of OpenApiRestCall_605589
proc url_PostPutInsightRule_607069(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutInsightRule_607068(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607070 = query.getOrDefault("Action")
  valid_607070 = validateParameter(valid_607070, JString, required = true,
                                 default = newJString("PutInsightRule"))
  if valid_607070 != nil:
    section.add "Action", valid_607070
  var valid_607071 = query.getOrDefault("Version")
  valid_607071 = validateParameter(valid_607071, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607071 != nil:
    section.add "Version", valid_607071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607072 = header.getOrDefault("X-Amz-Signature")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Signature", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Content-Sha256", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-Date")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Date", valid_607074
  var valid_607075 = header.getOrDefault("X-Amz-Credential")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "X-Amz-Credential", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-Security-Token")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-Security-Token", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-Algorithm")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Algorithm", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-SignedHeaders", valid_607078
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
  var valid_607079 = formData.getOrDefault("RuleName")
  valid_607079 = validateParameter(valid_607079, JString, required = true,
                                 default = nil)
  if valid_607079 != nil:
    section.add "RuleName", valid_607079
  var valid_607080 = formData.getOrDefault("RuleState")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "RuleState", valid_607080
  var valid_607081 = formData.getOrDefault("RuleDefinition")
  valid_607081 = validateParameter(valid_607081, JString, required = true,
                                 default = nil)
  if valid_607081 != nil:
    section.add "RuleDefinition", valid_607081
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607082: Call_PostPutInsightRule_607067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_607082.validator(path, query, header, formData, body)
  let scheme = call_607082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607082.url(scheme.get, call_607082.host, call_607082.base,
                         call_607082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607082, url, valid)

proc call*(call_607083: Call_PostPutInsightRule_607067; RuleName: string;
          RuleDefinition: string; RuleState: string = "";
          Action: string = "PutInsightRule"; Version: string = "2010-08-01"): Recallable =
  ## postPutInsightRule
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   RuleName: string (required)
  ##           : A unique name for the rule.
  ##   RuleState: string
  ##            : The state of the rule. Valid values are ENABLED and DISABLED.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   RuleDefinition: string (required)
  ##                 : The definition of the rule, as a JSON object. For details on the valid syntax, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights-RuleSyntax.html">Contributor Insights Rule Syntax</a>.
  var query_607084 = newJObject()
  var formData_607085 = newJObject()
  add(formData_607085, "RuleName", newJString(RuleName))
  add(formData_607085, "RuleState", newJString(RuleState))
  add(query_607084, "Action", newJString(Action))
  add(query_607084, "Version", newJString(Version))
  add(formData_607085, "RuleDefinition", newJString(RuleDefinition))
  result = call_607083.call(nil, query_607084, nil, formData_607085, nil)

var postPutInsightRule* = Call_PostPutInsightRule_607067(
    name: "postPutInsightRule", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutInsightRule",
    validator: validate_PostPutInsightRule_607068, base: "/",
    url: url_PostPutInsightRule_607069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutInsightRule_607049 = ref object of OpenApiRestCall_605589
proc url_GetPutInsightRule_607051(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutInsightRule_607050(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RuleName: JString (required)
  ##           : A unique name for the rule.
  ##   RuleDefinition: JString (required)
  ##                 : The definition of the rule, as a JSON object. For details on the valid syntax, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights-RuleSyntax.html">Contributor Insights Rule Syntax</a>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   RuleState: JString
  ##            : The state of the rule. Valid values are ENABLED and DISABLED.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `RuleName` field"
  var valid_607052 = query.getOrDefault("RuleName")
  valid_607052 = validateParameter(valid_607052, JString, required = true,
                                 default = nil)
  if valid_607052 != nil:
    section.add "RuleName", valid_607052
  var valid_607053 = query.getOrDefault("RuleDefinition")
  valid_607053 = validateParameter(valid_607053, JString, required = true,
                                 default = nil)
  if valid_607053 != nil:
    section.add "RuleDefinition", valid_607053
  var valid_607054 = query.getOrDefault("Action")
  valid_607054 = validateParameter(valid_607054, JString, required = true,
                                 default = newJString("PutInsightRule"))
  if valid_607054 != nil:
    section.add "Action", valid_607054
  var valid_607055 = query.getOrDefault("Version")
  valid_607055 = validateParameter(valid_607055, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607055 != nil:
    section.add "Version", valid_607055
  var valid_607056 = query.getOrDefault("RuleState")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "RuleState", valid_607056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607057 = header.getOrDefault("X-Amz-Signature")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Signature", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Content-Sha256", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Date")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Date", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Credential")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Credential", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-Security-Token")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-Security-Token", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-Algorithm")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-Algorithm", valid_607062
  var valid_607063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-SignedHeaders", valid_607063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607064: Call_GetPutInsightRule_607049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_607064.validator(path, query, header, formData, body)
  let scheme = call_607064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607064.url(scheme.get, call_607064.host, call_607064.base,
                         call_607064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607064, url, valid)

proc call*(call_607065: Call_GetPutInsightRule_607049; RuleName: string;
          RuleDefinition: string; Action: string = "PutInsightRule";
          Version: string = "2010-08-01"; RuleState: string = ""): Recallable =
  ## getPutInsightRule
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   RuleName: string (required)
  ##           : A unique name for the rule.
  ##   RuleDefinition: string (required)
  ##                 : The definition of the rule, as a JSON object. For details on the valid syntax, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights-RuleSyntax.html">Contributor Insights Rule Syntax</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   RuleState: string
  ##            : The state of the rule. Valid values are ENABLED and DISABLED.
  var query_607066 = newJObject()
  add(query_607066, "RuleName", newJString(RuleName))
  add(query_607066, "RuleDefinition", newJString(RuleDefinition))
  add(query_607066, "Action", newJString(Action))
  add(query_607066, "Version", newJString(Version))
  add(query_607066, "RuleState", newJString(RuleState))
  result = call_607065.call(nil, query_607066, nil, nil, nil)

var getPutInsightRule* = Call_GetPutInsightRule_607049(name: "getPutInsightRule",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutInsightRule", validator: validate_GetPutInsightRule_607050,
    base: "/", url: url_GetPutInsightRule_607051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricAlarm_607123 = ref object of OpenApiRestCall_605589
proc url_PostPutMetricAlarm_607125(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutMetricAlarm_607124(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607126 = query.getOrDefault("Action")
  valid_607126 = validateParameter(valid_607126, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_607126 != nil:
    section.add "Action", valid_607126
  var valid_607127 = query.getOrDefault("Version")
  valid_607127 = validateParameter(valid_607127, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607127 != nil:
    section.add "Version", valid_607127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607128 = header.getOrDefault("X-Amz-Signature")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "X-Amz-Signature", valid_607128
  var valid_607129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "X-Amz-Content-Sha256", valid_607129
  var valid_607130 = header.getOrDefault("X-Amz-Date")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-Date", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-Credential")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-Credential", valid_607131
  var valid_607132 = header.getOrDefault("X-Amz-Security-Token")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "X-Amz-Security-Token", valid_607132
  var valid_607133 = header.getOrDefault("X-Amz-Algorithm")
  valid_607133 = validateParameter(valid_607133, JString, required = false,
                                 default = nil)
  if valid_607133 != nil:
    section.add "X-Amz-Algorithm", valid_607133
  var valid_607134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607134 = validateParameter(valid_607134, JString, required = false,
                                 default = nil)
  if valid_607134 != nil:
    section.add "X-Amz-SignedHeaders", valid_607134
  result.add "header", section
  ## parameters in `formData` object:
  ##   ActionsEnabled: JBool
  ##                 : Indicates whether actions should be executed during any changes to the alarm state. The default is <code>TRUE</code>.
  ##   AlarmDescription: JString
  ##                   : The description for the alarm.
  ##   AlarmName: JString (required)
  ##            : The name for the alarm. This name must be unique within your AWS account.
  ##   ThresholdMetricId: JString
  ##                    : <p>If this is an alarm based on an anomaly detection model, make this value match the ID of the <code>ANOMALY_DETECTION_BAND</code> function.</p> <p>For an example of how to use this parameter, see the <b>Anomaly Detection Model Alarm</b> example on this page.</p> <p>If your alarm uses this parameter, it cannot have Auto Scaling actions.</p>
  ##   Unit: JString
  ##       : <p>The unit of measure for the statistic. For example, the units for the Amazon EC2 NetworkIn metric are Bytes because NetworkIn tracks the number of bytes that an instance receives on all network interfaces. You can also specify a unit when you create a custom metric. Units help provide conceptual meaning to your data. Metric data points that specify a unit of measure, such as Percent, are aggregated separately.</p> <p>If you don't specify <code>Unit</code>, CloudWatch retrieves all unit types that have been published for the metric and attempts to evaluate the alarm. Usually metrics are published with only one unit, so the alarm will work as intended.</p> <p>However, if the metric is published with multiple types of units and you don't specify a unit, the alarm's behavior is not defined and will behave un-predictably.</p> <p>We recommend omitting <code>Unit</code> so that you don't inadvertently specify an incorrect unit that is not published for this metric. Doing so causes the alarm to be stuck in the <code>INSUFFICIENT DATA</code> state.</p>
  ##   Period: JInt
  ##         : <p>The length, in seconds, used each time the metric specified in <code>MetricName</code> is evaluated. Valid values are 10, 30, and any multiple of 60.</p> <p> <code>Period</code> is required for alarms based on static thresholds. If you are creating an alarm based on a metric math expression, you specify the period for each metric within the objects in the <code>Metrics</code> array.</p> <p>Be sure to specify 10 or 30 only for metrics that are stored by a <code>PutMetricData</code> call with a <code>StorageResolution</code> of 1. If you specify a period of 10 or 30 for a metric that does not have sub-minute resolution, the alarm still attempts to gather data at the period rate that you specify. In this case, it does not receive data for the attempts that do not correspond to a one-minute data resolution, and the alarm may often lapse into INSUFFICENT_DATA status. Specifying 10 or 30 also sets this alarm as a high-resolution alarm, which has a higher charge than other alarms. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>An alarm's total current evaluation period can be no longer than one day, so <code>Period</code> multiplied by <code>EvaluationPeriods</code> cannot be more than 86,400 seconds.</p>
  ##   AlarmActions: JArray
  ##               : <p>The actions to execute when this alarm transitions to the <code>ALARM</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   ComparisonOperator: JString (required)
  ##                     : <p> The arithmetic operation to use when comparing the specified statistic and threshold. The specified statistic value is used as the first operand.</p> <p>The values <code>LessThanLowerOrGreaterThanUpperThreshold</code>, <code>LessThanLowerThreshold</code>, and <code>GreaterThanUpperThreshold</code> are used only for alarms based on anomaly detection models.</p>
  ##   EvaluateLowSampleCountPercentile: JString
  ##                                   : <p> Used only for alarms based on percentiles. If you specify <code>ignore</code>, the alarm state does not change during periods with too few data points to be statistically significant. If you specify <code>evaluate</code> or omit this parameter, the alarm is always evaluated and possibly changes state no matter how many data points are available. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#percentiles-with-low-samples">Percentile-Based CloudWatch Alarms and Low Data Samples</a>.</p> <p>Valid Values: <code>evaluate | ignore</code> </p>
  ##   OKActions: JArray
  ##            : <p>The actions to execute when this alarm transitions to an <code>OK</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Statistic: JString
  ##            : The statistic for the metric specified in <code>MetricName</code>, other than percentile. For percentile statistics, use <code>ExtendedStatistic</code>. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   TreatMissingData: JString
  ##                   : <p> Sets how this alarm is to handle missing data points. If <code>TreatMissingData</code> is omitted, the default behavior of <code>missing</code> is used. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarms-and-missing-data">Configuring How CloudWatch Alarms Treats Missing Data</a>.</p> <p>Valid Values: <code>breaching | notBreaching | ignore | missing</code> </p>
  ##   InsufficientDataActions: JArray
  ##                          : <p>The actions to execute when this alarm transitions to the <code>INSUFFICIENT_DATA</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>&gt;arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   DatapointsToAlarm: JInt
  ##                    : The number of data points that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarm-evaluation">Evaluating an Alarm</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   MetricName: JString
  ##             : <p>The name for the metric associated with the alarm. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>If you are creating an alarm based on a math expression, you cannot specify this parameter, or any of the <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters. Instead, you specify all this information in the <code>Metrics</code> array.</p>
  ##   Dimensions: JArray
  ##             : The dimensions for the metric specified in <code>MetricName</code>.
  ##   Tags: JArray
  ##       : <p>A list of key-value pairs to associate with the alarm. You can associate as many as 50 tags with an alarm.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p>
  ##   Namespace: JString
  ##            : The namespace for the metric associated specified in <code>MetricName</code>.
  ##   ExtendedStatistic: JString
  ##                    : The percentile statistic for the metric specified in <code>MetricName</code>. Specify a value between p0.0 and p100. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   EvaluationPeriods: JInt (required)
  ##                    : <p>The number of periods over which data is compared to the specified threshold. If you are setting an alarm that requires that a number of consecutive data points be breaching to trigger the alarm, this value specifies that number. If you are setting an "M out of N" alarm, this value is the N.</p> <p>An alarm's total current evaluation period can be no longer than one day, so this number multiplied by <code>Period</code> cannot be more than 86,400 seconds.</p>
  ##   Threshold: JFloat
  ##            : <p>The value against which the specified statistic is compared.</p> <p>This parameter is required for alarms based on static thresholds, but should not be used for alarms based on anomaly detection models.</p>
  ##   Metrics: JArray
  ##          : <p>An array of <code>MetricDataQuery</code> structures that enable you to create an alarm based on the result of a metric math expression. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>Each item in the <code>Metrics</code> array either retrieves a metric or performs a math expression.</p> <p>One item in the <code>Metrics</code> array is the expression that the alarm watches. You designate this expression by setting <code>ReturnValue</code> to true for this object in the array. For more information, see <a>MetricDataQuery</a>.</p> <p>If you use the <code>Metrics</code> parameter, you cannot include the <code>MetricName</code>, <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters of <code>PutMetricAlarm</code> in the same operation. Instead, you retrieve the metrics you are using in your math expression as part of the <code>Metrics</code> array.</p>
  section = newJObject()
  var valid_607135 = formData.getOrDefault("ActionsEnabled")
  valid_607135 = validateParameter(valid_607135, JBool, required = false, default = nil)
  if valid_607135 != nil:
    section.add "ActionsEnabled", valid_607135
  var valid_607136 = formData.getOrDefault("AlarmDescription")
  valid_607136 = validateParameter(valid_607136, JString, required = false,
                                 default = nil)
  if valid_607136 != nil:
    section.add "AlarmDescription", valid_607136
  assert formData != nil,
        "formData argument is necessary due to required `AlarmName` field"
  var valid_607137 = formData.getOrDefault("AlarmName")
  valid_607137 = validateParameter(valid_607137, JString, required = true,
                                 default = nil)
  if valid_607137 != nil:
    section.add "AlarmName", valid_607137
  var valid_607138 = formData.getOrDefault("ThresholdMetricId")
  valid_607138 = validateParameter(valid_607138, JString, required = false,
                                 default = nil)
  if valid_607138 != nil:
    section.add "ThresholdMetricId", valid_607138
  var valid_607139 = formData.getOrDefault("Unit")
  valid_607139 = validateParameter(valid_607139, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_607139 != nil:
    section.add "Unit", valid_607139
  var valid_607140 = formData.getOrDefault("Period")
  valid_607140 = validateParameter(valid_607140, JInt, required = false, default = nil)
  if valid_607140 != nil:
    section.add "Period", valid_607140
  var valid_607141 = formData.getOrDefault("AlarmActions")
  valid_607141 = validateParameter(valid_607141, JArray, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "AlarmActions", valid_607141
  var valid_607142 = formData.getOrDefault("ComparisonOperator")
  valid_607142 = validateParameter(valid_607142, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_607142 != nil:
    section.add "ComparisonOperator", valid_607142
  var valid_607143 = formData.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_607143
  var valid_607144 = formData.getOrDefault("OKActions")
  valid_607144 = validateParameter(valid_607144, JArray, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "OKActions", valid_607144
  var valid_607145 = formData.getOrDefault("Statistic")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_607145 != nil:
    section.add "Statistic", valid_607145
  var valid_607146 = formData.getOrDefault("TreatMissingData")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "TreatMissingData", valid_607146
  var valid_607147 = formData.getOrDefault("InsufficientDataActions")
  valid_607147 = validateParameter(valid_607147, JArray, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "InsufficientDataActions", valid_607147
  var valid_607148 = formData.getOrDefault("DatapointsToAlarm")
  valid_607148 = validateParameter(valid_607148, JInt, required = false, default = nil)
  if valid_607148 != nil:
    section.add "DatapointsToAlarm", valid_607148
  var valid_607149 = formData.getOrDefault("MetricName")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "MetricName", valid_607149
  var valid_607150 = formData.getOrDefault("Dimensions")
  valid_607150 = validateParameter(valid_607150, JArray, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "Dimensions", valid_607150
  var valid_607151 = formData.getOrDefault("Tags")
  valid_607151 = validateParameter(valid_607151, JArray, required = false,
                                 default = nil)
  if valid_607151 != nil:
    section.add "Tags", valid_607151
  var valid_607152 = formData.getOrDefault("Namespace")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "Namespace", valid_607152
  var valid_607153 = formData.getOrDefault("ExtendedStatistic")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "ExtendedStatistic", valid_607153
  var valid_607154 = formData.getOrDefault("EvaluationPeriods")
  valid_607154 = validateParameter(valid_607154, JInt, required = true, default = nil)
  if valid_607154 != nil:
    section.add "EvaluationPeriods", valid_607154
  var valid_607155 = formData.getOrDefault("Threshold")
  valid_607155 = validateParameter(valid_607155, JFloat, required = false,
                                 default = nil)
  if valid_607155 != nil:
    section.add "Threshold", valid_607155
  var valid_607156 = formData.getOrDefault("Metrics")
  valid_607156 = validateParameter(valid_607156, JArray, required = false,
                                 default = nil)
  if valid_607156 != nil:
    section.add "Metrics", valid_607156
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607157: Call_PostPutMetricAlarm_607123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_607157.validator(path, query, header, formData, body)
  let scheme = call_607157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607157.url(scheme.get, call_607157.host, call_607157.base,
                         call_607157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607157, url, valid)

proc call*(call_607158: Call_PostPutMetricAlarm_607123; AlarmName: string;
          EvaluationPeriods: int; ActionsEnabled: bool = false;
          AlarmDescription: string = ""; ThresholdMetricId: string = "";
          Unit: string = "Seconds"; Period: int = 0; AlarmActions: JsonNode = nil;
          ComparisonOperator: string = "GreaterThanOrEqualToThreshold";
          EvaluateLowSampleCountPercentile: string = ""; OKActions: JsonNode = nil;
          Statistic: string = "SampleCount"; TreatMissingData: string = "";
          InsufficientDataActions: JsonNode = nil; DatapointsToAlarm: int = 0;
          MetricName: string = ""; Action: string = "PutMetricAlarm";
          Dimensions: JsonNode = nil; Tags: JsonNode = nil; Namespace: string = "";
          ExtendedStatistic: string = ""; Version: string = "2010-08-01";
          Threshold: float = 0.0; Metrics: JsonNode = nil): Recallable =
  ## postPutMetricAlarm
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ##   ActionsEnabled: bool
  ##                 : Indicates whether actions should be executed during any changes to the alarm state. The default is <code>TRUE</code>.
  ##   AlarmDescription: string
  ##                   : The description for the alarm.
  ##   AlarmName: string (required)
  ##            : The name for the alarm. This name must be unique within your AWS account.
  ##   ThresholdMetricId: string
  ##                    : <p>If this is an alarm based on an anomaly detection model, make this value match the ID of the <code>ANOMALY_DETECTION_BAND</code> function.</p> <p>For an example of how to use this parameter, see the <b>Anomaly Detection Model Alarm</b> example on this page.</p> <p>If your alarm uses this parameter, it cannot have Auto Scaling actions.</p>
  ##   Unit: string
  ##       : <p>The unit of measure for the statistic. For example, the units for the Amazon EC2 NetworkIn metric are Bytes because NetworkIn tracks the number of bytes that an instance receives on all network interfaces. You can also specify a unit when you create a custom metric. Units help provide conceptual meaning to your data. Metric data points that specify a unit of measure, such as Percent, are aggregated separately.</p> <p>If you don't specify <code>Unit</code>, CloudWatch retrieves all unit types that have been published for the metric and attempts to evaluate the alarm. Usually metrics are published with only one unit, so the alarm will work as intended.</p> <p>However, if the metric is published with multiple types of units and you don't specify a unit, the alarm's behavior is not defined and will behave un-predictably.</p> <p>We recommend omitting <code>Unit</code> so that you don't inadvertently specify an incorrect unit that is not published for this metric. Doing so causes the alarm to be stuck in the <code>INSUFFICIENT DATA</code> state.</p>
  ##   Period: int
  ##         : <p>The length, in seconds, used each time the metric specified in <code>MetricName</code> is evaluated. Valid values are 10, 30, and any multiple of 60.</p> <p> <code>Period</code> is required for alarms based on static thresholds. If you are creating an alarm based on a metric math expression, you specify the period for each metric within the objects in the <code>Metrics</code> array.</p> <p>Be sure to specify 10 or 30 only for metrics that are stored by a <code>PutMetricData</code> call with a <code>StorageResolution</code> of 1. If you specify a period of 10 or 30 for a metric that does not have sub-minute resolution, the alarm still attempts to gather data at the period rate that you specify. In this case, it does not receive data for the attempts that do not correspond to a one-minute data resolution, and the alarm may often lapse into INSUFFICENT_DATA status. Specifying 10 or 30 also sets this alarm as a high-resolution alarm, which has a higher charge than other alarms. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>An alarm's total current evaluation period can be no longer than one day, so <code>Period</code> multiplied by <code>EvaluationPeriods</code> cannot be more than 86,400 seconds.</p>
  ##   AlarmActions: JArray
  ##               : <p>The actions to execute when this alarm transitions to the <code>ALARM</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   ComparisonOperator: string (required)
  ##                     : <p> The arithmetic operation to use when comparing the specified statistic and threshold. The specified statistic value is used as the first operand.</p> <p>The values <code>LessThanLowerOrGreaterThanUpperThreshold</code>, <code>LessThanLowerThreshold</code>, and <code>GreaterThanUpperThreshold</code> are used only for alarms based on anomaly detection models.</p>
  ##   EvaluateLowSampleCountPercentile: string
  ##                                   : <p> Used only for alarms based on percentiles. If you specify <code>ignore</code>, the alarm state does not change during periods with too few data points to be statistically significant. If you specify <code>evaluate</code> or omit this parameter, the alarm is always evaluated and possibly changes state no matter how many data points are available. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#percentiles-with-low-samples">Percentile-Based CloudWatch Alarms and Low Data Samples</a>.</p> <p>Valid Values: <code>evaluate | ignore</code> </p>
  ##   OKActions: JArray
  ##            : <p>The actions to execute when this alarm transitions to an <code>OK</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Statistic: string
  ##            : The statistic for the metric specified in <code>MetricName</code>, other than percentile. For percentile statistics, use <code>ExtendedStatistic</code>. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   TreatMissingData: string
  ##                   : <p> Sets how this alarm is to handle missing data points. If <code>TreatMissingData</code> is omitted, the default behavior of <code>missing</code> is used. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarms-and-missing-data">Configuring How CloudWatch Alarms Treats Missing Data</a>.</p> <p>Valid Values: <code>breaching | notBreaching | ignore | missing</code> </p>
  ##   InsufficientDataActions: JArray
  ##                          : <p>The actions to execute when this alarm transitions to the <code>INSUFFICIENT_DATA</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>&gt;arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   DatapointsToAlarm: int
  ##                    : The number of data points that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarm-evaluation">Evaluating an Alarm</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   MetricName: string
  ##             : <p>The name for the metric associated with the alarm. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>If you are creating an alarm based on a math expression, you cannot specify this parameter, or any of the <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters. Instead, you specify all this information in the <code>Metrics</code> array.</p>
  ##   Action: string (required)
  ##   Dimensions: JArray
  ##             : The dimensions for the metric specified in <code>MetricName</code>.
  ##   Tags: JArray
  ##       : <p>A list of key-value pairs to associate with the alarm. You can associate as many as 50 tags with an alarm.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p>
  ##   Namespace: string
  ##            : The namespace for the metric associated specified in <code>MetricName</code>.
  ##   ExtendedStatistic: string
  ##                    : The percentile statistic for the metric specified in <code>MetricName</code>. Specify a value between p0.0 and p100. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   Version: string (required)
  ##   EvaluationPeriods: int (required)
  ##                    : <p>The number of periods over which data is compared to the specified threshold. If you are setting an alarm that requires that a number of consecutive data points be breaching to trigger the alarm, this value specifies that number. If you are setting an "M out of N" alarm, this value is the N.</p> <p>An alarm's total current evaluation period can be no longer than one day, so this number multiplied by <code>Period</code> cannot be more than 86,400 seconds.</p>
  ##   Threshold: float
  ##            : <p>The value against which the specified statistic is compared.</p> <p>This parameter is required for alarms based on static thresholds, but should not be used for alarms based on anomaly detection models.</p>
  ##   Metrics: JArray
  ##          : <p>An array of <code>MetricDataQuery</code> structures that enable you to create an alarm based on the result of a metric math expression. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>Each item in the <code>Metrics</code> array either retrieves a metric or performs a math expression.</p> <p>One item in the <code>Metrics</code> array is the expression that the alarm watches. You designate this expression by setting <code>ReturnValue</code> to true for this object in the array. For more information, see <a>MetricDataQuery</a>.</p> <p>If you use the <code>Metrics</code> parameter, you cannot include the <code>MetricName</code>, <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters of <code>PutMetricAlarm</code> in the same operation. Instead, you retrieve the metrics you are using in your math expression as part of the <code>Metrics</code> array.</p>
  var query_607159 = newJObject()
  var formData_607160 = newJObject()
  add(formData_607160, "ActionsEnabled", newJBool(ActionsEnabled))
  add(formData_607160, "AlarmDescription", newJString(AlarmDescription))
  add(formData_607160, "AlarmName", newJString(AlarmName))
  add(formData_607160, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(formData_607160, "Unit", newJString(Unit))
  add(formData_607160, "Period", newJInt(Period))
  if AlarmActions != nil:
    formData_607160.add "AlarmActions", AlarmActions
  add(formData_607160, "ComparisonOperator", newJString(ComparisonOperator))
  add(formData_607160, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  if OKActions != nil:
    formData_607160.add "OKActions", OKActions
  add(formData_607160, "Statistic", newJString(Statistic))
  add(formData_607160, "TreatMissingData", newJString(TreatMissingData))
  if InsufficientDataActions != nil:
    formData_607160.add "InsufficientDataActions", InsufficientDataActions
  add(formData_607160, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(formData_607160, "MetricName", newJString(MetricName))
  add(query_607159, "Action", newJString(Action))
  if Dimensions != nil:
    formData_607160.add "Dimensions", Dimensions
  if Tags != nil:
    formData_607160.add "Tags", Tags
  add(formData_607160, "Namespace", newJString(Namespace))
  add(formData_607160, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_607159, "Version", newJString(Version))
  add(formData_607160, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(formData_607160, "Threshold", newJFloat(Threshold))
  if Metrics != nil:
    formData_607160.add "Metrics", Metrics
  result = call_607158.call(nil, query_607159, nil, formData_607160, nil)

var postPutMetricAlarm* = Call_PostPutMetricAlarm_607123(
    name: "postPutMetricAlarm", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutMetricAlarm",
    validator: validate_PostPutMetricAlarm_607124, base: "/",
    url: url_PostPutMetricAlarm_607125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricAlarm_607086 = ref object of OpenApiRestCall_605589
proc url_GetPutMetricAlarm_607088(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutMetricAlarm_607087(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   InsufficientDataActions: JArray
  ##                          : <p>The actions to execute when this alarm transitions to the <code>INSUFFICIENT_DATA</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>&gt;arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Statistic: JString
  ##            : The statistic for the metric specified in <code>MetricName</code>, other than percentile. For percentile statistics, use <code>ExtendedStatistic</code>. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   AlarmDescription: JString
  ##                   : The description for the alarm.
  ##   Unit: JString
  ##       : <p>The unit of measure for the statistic. For example, the units for the Amazon EC2 NetworkIn metric are Bytes because NetworkIn tracks the number of bytes that an instance receives on all network interfaces. You can also specify a unit when you create a custom metric. Units help provide conceptual meaning to your data. Metric data points that specify a unit of measure, such as Percent, are aggregated separately.</p> <p>If you don't specify <code>Unit</code>, CloudWatch retrieves all unit types that have been published for the metric and attempts to evaluate the alarm. Usually metrics are published with only one unit, so the alarm will work as intended.</p> <p>However, if the metric is published with multiple types of units and you don't specify a unit, the alarm's behavior is not defined and will behave un-predictably.</p> <p>We recommend omitting <code>Unit</code> so that you don't inadvertently specify an incorrect unit that is not published for this metric. Doing so causes the alarm to be stuck in the <code>INSUFFICIENT DATA</code> state.</p>
  ##   DatapointsToAlarm: JInt
  ##                    : The number of data points that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarm-evaluation">Evaluating an Alarm</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   Threshold: JFloat
  ##            : <p>The value against which the specified statistic is compared.</p> <p>This parameter is required for alarms based on static thresholds, but should not be used for alarms based on anomaly detection models.</p>
  ##   Tags: JArray
  ##       : <p>A list of key-value pairs to associate with the alarm. You can associate as many as 50 tags with an alarm.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p>
  ##   ThresholdMetricId: JString
  ##                    : <p>If this is an alarm based on an anomaly detection model, make this value match the ID of the <code>ANOMALY_DETECTION_BAND</code> function.</p> <p>For an example of how to use this parameter, see the <b>Anomaly Detection Model Alarm</b> example on this page.</p> <p>If your alarm uses this parameter, it cannot have Auto Scaling actions.</p>
  ##   Namespace: JString
  ##            : The namespace for the metric associated specified in <code>MetricName</code>.
  ##   TreatMissingData: JString
  ##                   : <p> Sets how this alarm is to handle missing data points. If <code>TreatMissingData</code> is omitted, the default behavior of <code>missing</code> is used. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarms-and-missing-data">Configuring How CloudWatch Alarms Treats Missing Data</a>.</p> <p>Valid Values: <code>breaching | notBreaching | ignore | missing</code> </p>
  ##   ExtendedStatistic: JString
  ##                    : The percentile statistic for the metric specified in <code>MetricName</code>. Specify a value between p0.0 and p100. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   OKActions: JArray
  ##            : <p>The actions to execute when this alarm transitions to an <code>OK</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Dimensions: JArray
  ##             : The dimensions for the metric specified in <code>MetricName</code>.
  ##   Period: JInt
  ##         : <p>The length, in seconds, used each time the metric specified in <code>MetricName</code> is evaluated. Valid values are 10, 30, and any multiple of 60.</p> <p> <code>Period</code> is required for alarms based on static thresholds. If you are creating an alarm based on a metric math expression, you specify the period for each metric within the objects in the <code>Metrics</code> array.</p> <p>Be sure to specify 10 or 30 only for metrics that are stored by a <code>PutMetricData</code> call with a <code>StorageResolution</code> of 1. If you specify a period of 10 or 30 for a metric that does not have sub-minute resolution, the alarm still attempts to gather data at the period rate that you specify. In this case, it does not receive data for the attempts that do not correspond to a one-minute data resolution, and the alarm may often lapse into INSUFFICENT_DATA status. Specifying 10 or 30 also sets this alarm as a high-resolution alarm, which has a higher charge than other alarms. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>An alarm's total current evaluation period can be no longer than one day, so <code>Period</code> multiplied by <code>EvaluationPeriods</code> cannot be more than 86,400 seconds.</p>
  ##   AlarmName: JString (required)
  ##            : The name for the alarm. This name must be unique within your AWS account.
  ##   Action: JString (required)
  ##   EvaluationPeriods: JInt (required)
  ##                    : <p>The number of periods over which data is compared to the specified threshold. If you are setting an alarm that requires that a number of consecutive data points be breaching to trigger the alarm, this value specifies that number. If you are setting an "M out of N" alarm, this value is the N.</p> <p>An alarm's total current evaluation period can be no longer than one day, so this number multiplied by <code>Period</code> cannot be more than 86,400 seconds.</p>
  ##   ActionsEnabled: JBool
  ##                 : Indicates whether actions should be executed during any changes to the alarm state. The default is <code>TRUE</code>.
  ##   ComparisonOperator: JString (required)
  ##                     : <p> The arithmetic operation to use when comparing the specified statistic and threshold. The specified statistic value is used as the first operand.</p> <p>The values <code>LessThanLowerOrGreaterThanUpperThreshold</code>, <code>LessThanLowerThreshold</code>, and <code>GreaterThanUpperThreshold</code> are used only for alarms based on anomaly detection models.</p>
  ##   AlarmActions: JArray
  ##               : <p>The actions to execute when this alarm transitions to the <code>ALARM</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Metrics: JArray
  ##          : <p>An array of <code>MetricDataQuery</code> structures that enable you to create an alarm based on the result of a metric math expression. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>Each item in the <code>Metrics</code> array either retrieves a metric or performs a math expression.</p> <p>One item in the <code>Metrics</code> array is the expression that the alarm watches. You designate this expression by setting <code>ReturnValue</code> to true for this object in the array. For more information, see <a>MetricDataQuery</a>.</p> <p>If you use the <code>Metrics</code> parameter, you cannot include the <code>MetricName</code>, <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters of <code>PutMetricAlarm</code> in the same operation. Instead, you retrieve the metrics you are using in your math expression as part of the <code>Metrics</code> array.</p>
  ##   Version: JString (required)
  ##   EvaluateLowSampleCountPercentile: JString
  ##                                   : <p> Used only for alarms based on percentiles. If you specify <code>ignore</code>, the alarm state does not change during periods with too few data points to be statistically significant. If you specify <code>evaluate</code> or omit this parameter, the alarm is always evaluated and possibly changes state no matter how many data points are available. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#percentiles-with-low-samples">Percentile-Based CloudWatch Alarms and Low Data Samples</a>.</p> <p>Valid Values: <code>evaluate | ignore</code> </p>
  ##   MetricName: JString
  ##             : <p>The name for the metric associated with the alarm. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>If you are creating an alarm based on a math expression, you cannot specify this parameter, or any of the <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters. Instead, you specify all this information in the <code>Metrics</code> array.</p>
  section = newJObject()
  var valid_607089 = query.getOrDefault("InsufficientDataActions")
  valid_607089 = validateParameter(valid_607089, JArray, required = false,
                                 default = nil)
  if valid_607089 != nil:
    section.add "InsufficientDataActions", valid_607089
  var valid_607090 = query.getOrDefault("Statistic")
  valid_607090 = validateParameter(valid_607090, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_607090 != nil:
    section.add "Statistic", valid_607090
  var valid_607091 = query.getOrDefault("AlarmDescription")
  valid_607091 = validateParameter(valid_607091, JString, required = false,
                                 default = nil)
  if valid_607091 != nil:
    section.add "AlarmDescription", valid_607091
  var valid_607092 = query.getOrDefault("Unit")
  valid_607092 = validateParameter(valid_607092, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_607092 != nil:
    section.add "Unit", valid_607092
  var valid_607093 = query.getOrDefault("DatapointsToAlarm")
  valid_607093 = validateParameter(valid_607093, JInt, required = false, default = nil)
  if valid_607093 != nil:
    section.add "DatapointsToAlarm", valid_607093
  var valid_607094 = query.getOrDefault("Threshold")
  valid_607094 = validateParameter(valid_607094, JFloat, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "Threshold", valid_607094
  var valid_607095 = query.getOrDefault("Tags")
  valid_607095 = validateParameter(valid_607095, JArray, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "Tags", valid_607095
  var valid_607096 = query.getOrDefault("ThresholdMetricId")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "ThresholdMetricId", valid_607096
  var valid_607097 = query.getOrDefault("Namespace")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "Namespace", valid_607097
  var valid_607098 = query.getOrDefault("TreatMissingData")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "TreatMissingData", valid_607098
  var valid_607099 = query.getOrDefault("ExtendedStatistic")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "ExtendedStatistic", valid_607099
  var valid_607100 = query.getOrDefault("OKActions")
  valid_607100 = validateParameter(valid_607100, JArray, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "OKActions", valid_607100
  var valid_607101 = query.getOrDefault("Dimensions")
  valid_607101 = validateParameter(valid_607101, JArray, required = false,
                                 default = nil)
  if valid_607101 != nil:
    section.add "Dimensions", valid_607101
  var valid_607102 = query.getOrDefault("Period")
  valid_607102 = validateParameter(valid_607102, JInt, required = false, default = nil)
  if valid_607102 != nil:
    section.add "Period", valid_607102
  assert query != nil,
        "query argument is necessary due to required `AlarmName` field"
  var valid_607103 = query.getOrDefault("AlarmName")
  valid_607103 = validateParameter(valid_607103, JString, required = true,
                                 default = nil)
  if valid_607103 != nil:
    section.add "AlarmName", valid_607103
  var valid_607104 = query.getOrDefault("Action")
  valid_607104 = validateParameter(valid_607104, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_607104 != nil:
    section.add "Action", valid_607104
  var valid_607105 = query.getOrDefault("EvaluationPeriods")
  valid_607105 = validateParameter(valid_607105, JInt, required = true, default = nil)
  if valid_607105 != nil:
    section.add "EvaluationPeriods", valid_607105
  var valid_607106 = query.getOrDefault("ActionsEnabled")
  valid_607106 = validateParameter(valid_607106, JBool, required = false, default = nil)
  if valid_607106 != nil:
    section.add "ActionsEnabled", valid_607106
  var valid_607107 = query.getOrDefault("ComparisonOperator")
  valid_607107 = validateParameter(valid_607107, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_607107 != nil:
    section.add "ComparisonOperator", valid_607107
  var valid_607108 = query.getOrDefault("AlarmActions")
  valid_607108 = validateParameter(valid_607108, JArray, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "AlarmActions", valid_607108
  var valid_607109 = query.getOrDefault("Metrics")
  valid_607109 = validateParameter(valid_607109, JArray, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "Metrics", valid_607109
  var valid_607110 = query.getOrDefault("Version")
  valid_607110 = validateParameter(valid_607110, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607110 != nil:
    section.add "Version", valid_607110
  var valid_607111 = query.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_607111
  var valid_607112 = query.getOrDefault("MetricName")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "MetricName", valid_607112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607113 = header.getOrDefault("X-Amz-Signature")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Signature", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-Content-Sha256", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-Date")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-Date", valid_607115
  var valid_607116 = header.getOrDefault("X-Amz-Credential")
  valid_607116 = validateParameter(valid_607116, JString, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "X-Amz-Credential", valid_607116
  var valid_607117 = header.getOrDefault("X-Amz-Security-Token")
  valid_607117 = validateParameter(valid_607117, JString, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "X-Amz-Security-Token", valid_607117
  var valid_607118 = header.getOrDefault("X-Amz-Algorithm")
  valid_607118 = validateParameter(valid_607118, JString, required = false,
                                 default = nil)
  if valid_607118 != nil:
    section.add "X-Amz-Algorithm", valid_607118
  var valid_607119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607119 = validateParameter(valid_607119, JString, required = false,
                                 default = nil)
  if valid_607119 != nil:
    section.add "X-Amz-SignedHeaders", valid_607119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607120: Call_GetPutMetricAlarm_607086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_607120.validator(path, query, header, formData, body)
  let scheme = call_607120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607120.url(scheme.get, call_607120.host, call_607120.base,
                         call_607120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607120, url, valid)

proc call*(call_607121: Call_GetPutMetricAlarm_607086; AlarmName: string;
          EvaluationPeriods: int; InsufficientDataActions: JsonNode = nil;
          Statistic: string = "SampleCount"; AlarmDescription: string = "";
          Unit: string = "Seconds"; DatapointsToAlarm: int = 0; Threshold: float = 0.0;
          Tags: JsonNode = nil; ThresholdMetricId: string = ""; Namespace: string = "";
          TreatMissingData: string = ""; ExtendedStatistic: string = "";
          OKActions: JsonNode = nil; Dimensions: JsonNode = nil; Period: int = 0;
          Action: string = "PutMetricAlarm"; ActionsEnabled: bool = false;
          ComparisonOperator: string = "GreaterThanOrEqualToThreshold";
          AlarmActions: JsonNode = nil; Metrics: JsonNode = nil;
          Version: string = "2010-08-01";
          EvaluateLowSampleCountPercentile: string = ""; MetricName: string = ""): Recallable =
  ## getPutMetricAlarm
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ##   InsufficientDataActions: JArray
  ##                          : <p>The actions to execute when this alarm transitions to the <code>INSUFFICIENT_DATA</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>&gt;arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Statistic: string
  ##            : The statistic for the metric specified in <code>MetricName</code>, other than percentile. For percentile statistics, use <code>ExtendedStatistic</code>. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   AlarmDescription: string
  ##                   : The description for the alarm.
  ##   Unit: string
  ##       : <p>The unit of measure for the statistic. For example, the units for the Amazon EC2 NetworkIn metric are Bytes because NetworkIn tracks the number of bytes that an instance receives on all network interfaces. You can also specify a unit when you create a custom metric. Units help provide conceptual meaning to your data. Metric data points that specify a unit of measure, such as Percent, are aggregated separately.</p> <p>If you don't specify <code>Unit</code>, CloudWatch retrieves all unit types that have been published for the metric and attempts to evaluate the alarm. Usually metrics are published with only one unit, so the alarm will work as intended.</p> <p>However, if the metric is published with multiple types of units and you don't specify a unit, the alarm's behavior is not defined and will behave un-predictably.</p> <p>We recommend omitting <code>Unit</code> so that you don't inadvertently specify an incorrect unit that is not published for this metric. Doing so causes the alarm to be stuck in the <code>INSUFFICIENT DATA</code> state.</p>
  ##   DatapointsToAlarm: int
  ##                    : The number of data points that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarm-evaluation">Evaluating an Alarm</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   Threshold: float
  ##            : <p>The value against which the specified statistic is compared.</p> <p>This parameter is required for alarms based on static thresholds, but should not be used for alarms based on anomaly detection models.</p>
  ##   Tags: JArray
  ##       : <p>A list of key-value pairs to associate with the alarm. You can associate as many as 50 tags with an alarm.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p>
  ##   ThresholdMetricId: string
  ##                    : <p>If this is an alarm based on an anomaly detection model, make this value match the ID of the <code>ANOMALY_DETECTION_BAND</code> function.</p> <p>For an example of how to use this parameter, see the <b>Anomaly Detection Model Alarm</b> example on this page.</p> <p>If your alarm uses this parameter, it cannot have Auto Scaling actions.</p>
  ##   Namespace: string
  ##            : The namespace for the metric associated specified in <code>MetricName</code>.
  ##   TreatMissingData: string
  ##                   : <p> Sets how this alarm is to handle missing data points. If <code>TreatMissingData</code> is omitted, the default behavior of <code>missing</code> is used. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarms-and-missing-data">Configuring How CloudWatch Alarms Treats Missing Data</a>.</p> <p>Valid Values: <code>breaching | notBreaching | ignore | missing</code> </p>
  ##   ExtendedStatistic: string
  ##                    : The percentile statistic for the metric specified in <code>MetricName</code>. Specify a value between p0.0 and p100. When you call <code>PutMetricAlarm</code> and specify a <code>MetricName</code>, you must specify either <code>Statistic</code> or <code>ExtendedStatistic,</code> but not both.
  ##   OKActions: JArray
  ##            : <p>The actions to execute when this alarm transitions to an <code>OK</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Dimensions: JArray
  ##             : The dimensions for the metric specified in <code>MetricName</code>.
  ##   Period: int
  ##         : <p>The length, in seconds, used each time the metric specified in <code>MetricName</code> is evaluated. Valid values are 10, 30, and any multiple of 60.</p> <p> <code>Period</code> is required for alarms based on static thresholds. If you are creating an alarm based on a metric math expression, you specify the period for each metric within the objects in the <code>Metrics</code> array.</p> <p>Be sure to specify 10 or 30 only for metrics that are stored by a <code>PutMetricData</code> call with a <code>StorageResolution</code> of 1. If you specify a period of 10 or 30 for a metric that does not have sub-minute resolution, the alarm still attempts to gather data at the period rate that you specify. In this case, it does not receive data for the attempts that do not correspond to a one-minute data resolution, and the alarm may often lapse into INSUFFICENT_DATA status. Specifying 10 or 30 also sets this alarm as a high-resolution alarm, which has a higher charge than other alarms. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>An alarm's total current evaluation period can be no longer than one day, so <code>Period</code> multiplied by <code>EvaluationPeriods</code> cannot be more than 86,400 seconds.</p>
  ##   AlarmName: string (required)
  ##            : The name for the alarm. This name must be unique within your AWS account.
  ##   Action: string (required)
  ##   EvaluationPeriods: int (required)
  ##                    : <p>The number of periods over which data is compared to the specified threshold. If you are setting an alarm that requires that a number of consecutive data points be breaching to trigger the alarm, this value specifies that number. If you are setting an "M out of N" alarm, this value is the N.</p> <p>An alarm's total current evaluation period can be no longer than one day, so this number multiplied by <code>Period</code> cannot be more than 86,400 seconds.</p>
  ##   ActionsEnabled: bool
  ##                 : Indicates whether actions should be executed during any changes to the alarm state. The default is <code>TRUE</code>.
  ##   ComparisonOperator: string (required)
  ##                     : <p> The arithmetic operation to use when comparing the specified statistic and threshold. The specified statistic value is used as the first operand.</p> <p>The values <code>LessThanLowerOrGreaterThanUpperThreshold</code>, <code>LessThanLowerThreshold</code>, and <code>GreaterThanUpperThreshold</code> are used only for alarms based on anomaly detection models.</p>
  ##   AlarmActions: JArray
  ##               : <p>The actions to execute when this alarm transitions to the <code>ALARM</code> state from any other state. Each action is specified as an Amazon Resource Name (ARN).</p> <p>Valid Values: <code>arn:aws:automate:<i>region</i>:ec2:stop</code> | <code>arn:aws:automate:<i>region</i>:ec2:terminate</code> | <code>arn:aws:automate:<i>region</i>:ec2:recover</code> | <code>arn:aws:automate:<i>region</i>:ec2:reboot</code> | <code>arn:aws:sns:<i>region</i>:<i>account-id</i>:<i>sns-topic-name</i> </code> | 
  ## <code>arn:aws:autoscaling:<i>region</i>:<i>account-id</i>:scalingPolicy:<i>policy-id</i>autoScalingGroupName/<i>group-friendly-name</i>:policyName/<i>policy-friendly-name</i> </code> </p> <p>Valid Values (for use with IAM roles): 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Stop/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Terminate/1.0</code> | 
  ## <code>arn:aws:swf:<i>region</i>:<i>account-id</i>:action/actions/AWS_EC2.InstanceId.Reboot/1.0</code> </p>
  ##   Metrics: JArray
  ##          : <p>An array of <code>MetricDataQuery</code> structures that enable you to create an alarm based on the result of a metric math expression. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>Each item in the <code>Metrics</code> array either retrieves a metric or performs a math expression.</p> <p>One item in the <code>Metrics</code> array is the expression that the alarm watches. You designate this expression by setting <code>ReturnValue</code> to true for this object in the array. For more information, see <a>MetricDataQuery</a>.</p> <p>If you use the <code>Metrics</code> parameter, you cannot include the <code>MetricName</code>, <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters of <code>PutMetricAlarm</code> in the same operation. Instead, you retrieve the metrics you are using in your math expression as part of the <code>Metrics</code> array.</p>
  ##   Version: string (required)
  ##   EvaluateLowSampleCountPercentile: string
  ##                                   : <p> Used only for alarms based on percentiles. If you specify <code>ignore</code>, the alarm state does not change during periods with too few data points to be statistically significant. If you specify <code>evaluate</code> or omit this parameter, the alarm is always evaluated and possibly changes state no matter how many data points are available. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#percentiles-with-low-samples">Percentile-Based CloudWatch Alarms and Low Data Samples</a>.</p> <p>Valid Values: <code>evaluate | ignore</code> </p>
  ##   MetricName: string
  ##             : <p>The name for the metric associated with the alarm. For each <code>PutMetricAlarm</code> operation, you must specify either <code>MetricName</code> or a <code>Metrics</code> array.</p> <p>If you are creating an alarm based on a math expression, you cannot specify this parameter, or any of the <code>Dimensions</code>, <code>Period</code>, <code>Namespace</code>, <code>Statistic</code>, or <code>ExtendedStatistic</code> parameters. Instead, you specify all this information in the <code>Metrics</code> array.</p>
  var query_607122 = newJObject()
  if InsufficientDataActions != nil:
    query_607122.add "InsufficientDataActions", InsufficientDataActions
  add(query_607122, "Statistic", newJString(Statistic))
  add(query_607122, "AlarmDescription", newJString(AlarmDescription))
  add(query_607122, "Unit", newJString(Unit))
  add(query_607122, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(query_607122, "Threshold", newJFloat(Threshold))
  if Tags != nil:
    query_607122.add "Tags", Tags
  add(query_607122, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_607122, "Namespace", newJString(Namespace))
  add(query_607122, "TreatMissingData", newJString(TreatMissingData))
  add(query_607122, "ExtendedStatistic", newJString(ExtendedStatistic))
  if OKActions != nil:
    query_607122.add "OKActions", OKActions
  if Dimensions != nil:
    query_607122.add "Dimensions", Dimensions
  add(query_607122, "Period", newJInt(Period))
  add(query_607122, "AlarmName", newJString(AlarmName))
  add(query_607122, "Action", newJString(Action))
  add(query_607122, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(query_607122, "ActionsEnabled", newJBool(ActionsEnabled))
  add(query_607122, "ComparisonOperator", newJString(ComparisonOperator))
  if AlarmActions != nil:
    query_607122.add "AlarmActions", AlarmActions
  if Metrics != nil:
    query_607122.add "Metrics", Metrics
  add(query_607122, "Version", newJString(Version))
  add(query_607122, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  add(query_607122, "MetricName", newJString(MetricName))
  result = call_607121.call(nil, query_607122, nil, nil, nil)

var getPutMetricAlarm* = Call_GetPutMetricAlarm_607086(name: "getPutMetricAlarm",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricAlarm", validator: validate_GetPutMetricAlarm_607087,
    base: "/", url: url_GetPutMetricAlarm_607088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricData_607178 = ref object of OpenApiRestCall_605589
proc url_PostPutMetricData_607180(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutMetricData_607179(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607181 = query.getOrDefault("Action")
  valid_607181 = validateParameter(valid_607181, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_607181 != nil:
    section.add "Action", valid_607181
  var valid_607182 = query.getOrDefault("Version")
  valid_607182 = validateParameter(valid_607182, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607182 != nil:
    section.add "Version", valid_607182
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607183 = header.getOrDefault("X-Amz-Signature")
  valid_607183 = validateParameter(valid_607183, JString, required = false,
                                 default = nil)
  if valid_607183 != nil:
    section.add "X-Amz-Signature", valid_607183
  var valid_607184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "X-Amz-Content-Sha256", valid_607184
  var valid_607185 = header.getOrDefault("X-Amz-Date")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "X-Amz-Date", valid_607185
  var valid_607186 = header.getOrDefault("X-Amz-Credential")
  valid_607186 = validateParameter(valid_607186, JString, required = false,
                                 default = nil)
  if valid_607186 != nil:
    section.add "X-Amz-Credential", valid_607186
  var valid_607187 = header.getOrDefault("X-Amz-Security-Token")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Security-Token", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-Algorithm")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-Algorithm", valid_607188
  var valid_607189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607189 = validateParameter(valid_607189, JString, required = false,
                                 default = nil)
  if valid_607189 != nil:
    section.add "X-Amz-SignedHeaders", valid_607189
  result.add "header", section
  ## parameters in `formData` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Namespace` field"
  var valid_607190 = formData.getOrDefault("Namespace")
  valid_607190 = validateParameter(valid_607190, JString, required = true,
                                 default = nil)
  if valid_607190 != nil:
    section.add "Namespace", valid_607190
  var valid_607191 = formData.getOrDefault("MetricData")
  valid_607191 = validateParameter(valid_607191, JArray, required = true, default = nil)
  if valid_607191 != nil:
    section.add "MetricData", valid_607191
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607192: Call_PostPutMetricData_607178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_607192.validator(path, query, header, formData, body)
  let scheme = call_607192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607192.url(scheme.get, call_607192.host, call_607192.base,
                         call_607192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607192, url, valid)

proc call*(call_607193: Call_PostPutMetricData_607178; Namespace: string;
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
  var query_607194 = newJObject()
  var formData_607195 = newJObject()
  add(query_607194, "Action", newJString(Action))
  add(formData_607195, "Namespace", newJString(Namespace))
  if MetricData != nil:
    formData_607195.add "MetricData", MetricData
  add(query_607194, "Version", newJString(Version))
  result = call_607193.call(nil, query_607194, nil, formData_607195, nil)

var postPutMetricData* = Call_PostPutMetricData_607178(name: "postPutMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_PostPutMetricData_607179,
    base: "/", url: url_PostPutMetricData_607180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricData_607161 = ref object of OpenApiRestCall_605589
proc url_GetPutMetricData_607163(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutMetricData_607162(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_607164 = query.getOrDefault("Namespace")
  valid_607164 = validateParameter(valid_607164, JString, required = true,
                                 default = nil)
  if valid_607164 != nil:
    section.add "Namespace", valid_607164
  var valid_607165 = query.getOrDefault("Action")
  valid_607165 = validateParameter(valid_607165, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_607165 != nil:
    section.add "Action", valid_607165
  var valid_607166 = query.getOrDefault("Version")
  valid_607166 = validateParameter(valid_607166, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607166 != nil:
    section.add "Version", valid_607166
  var valid_607167 = query.getOrDefault("MetricData")
  valid_607167 = validateParameter(valid_607167, JArray, required = true, default = nil)
  if valid_607167 != nil:
    section.add "MetricData", valid_607167
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607168 = header.getOrDefault("X-Amz-Signature")
  valid_607168 = validateParameter(valid_607168, JString, required = false,
                                 default = nil)
  if valid_607168 != nil:
    section.add "X-Amz-Signature", valid_607168
  var valid_607169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607169 = validateParameter(valid_607169, JString, required = false,
                                 default = nil)
  if valid_607169 != nil:
    section.add "X-Amz-Content-Sha256", valid_607169
  var valid_607170 = header.getOrDefault("X-Amz-Date")
  valid_607170 = validateParameter(valid_607170, JString, required = false,
                                 default = nil)
  if valid_607170 != nil:
    section.add "X-Amz-Date", valid_607170
  var valid_607171 = header.getOrDefault("X-Amz-Credential")
  valid_607171 = validateParameter(valid_607171, JString, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "X-Amz-Credential", valid_607171
  var valid_607172 = header.getOrDefault("X-Amz-Security-Token")
  valid_607172 = validateParameter(valid_607172, JString, required = false,
                                 default = nil)
  if valid_607172 != nil:
    section.add "X-Amz-Security-Token", valid_607172
  var valid_607173 = header.getOrDefault("X-Amz-Algorithm")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "X-Amz-Algorithm", valid_607173
  var valid_607174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "X-Amz-SignedHeaders", valid_607174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607175: Call_GetPutMetricData_607161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_607175.validator(path, query, header, formData, body)
  let scheme = call_607175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607175.url(scheme.get, call_607175.host, call_607175.base,
                         call_607175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607175, url, valid)

proc call*(call_607176: Call_GetPutMetricData_607161; Namespace: string;
          MetricData: JsonNode; Action: string = "PutMetricData";
          Version: string = "2010-08-01"): Recallable =
  ## getPutMetricData
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ##   Namespace: string (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  var query_607177 = newJObject()
  add(query_607177, "Namespace", newJString(Namespace))
  add(query_607177, "Action", newJString(Action))
  add(query_607177, "Version", newJString(Version))
  if MetricData != nil:
    query_607177.add "MetricData", MetricData
  result = call_607176.call(nil, query_607177, nil, nil, nil)

var getPutMetricData* = Call_GetPutMetricData_607161(name: "getPutMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_GetPutMetricData_607162,
    base: "/", url: url_GetPutMetricData_607163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetAlarmState_607215 = ref object of OpenApiRestCall_605589
proc url_PostSetAlarmState_607217(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetAlarmState_607216(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607218 = query.getOrDefault("Action")
  valid_607218 = validateParameter(valid_607218, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_607218 != nil:
    section.add "Action", valid_607218
  var valid_607219 = query.getOrDefault("Version")
  valid_607219 = validateParameter(valid_607219, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607219 != nil:
    section.add "Version", valid_607219
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607220 = header.getOrDefault("X-Amz-Signature")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Signature", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-Content-Sha256", valid_607221
  var valid_607222 = header.getOrDefault("X-Amz-Date")
  valid_607222 = validateParameter(valid_607222, JString, required = false,
                                 default = nil)
  if valid_607222 != nil:
    section.add "X-Amz-Date", valid_607222
  var valid_607223 = header.getOrDefault("X-Amz-Credential")
  valid_607223 = validateParameter(valid_607223, JString, required = false,
                                 default = nil)
  if valid_607223 != nil:
    section.add "X-Amz-Credential", valid_607223
  var valid_607224 = header.getOrDefault("X-Amz-Security-Token")
  valid_607224 = validateParameter(valid_607224, JString, required = false,
                                 default = nil)
  if valid_607224 != nil:
    section.add "X-Amz-Security-Token", valid_607224
  var valid_607225 = header.getOrDefault("X-Amz-Algorithm")
  valid_607225 = validateParameter(valid_607225, JString, required = false,
                                 default = nil)
  if valid_607225 != nil:
    section.add "X-Amz-Algorithm", valid_607225
  var valid_607226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607226 = validateParameter(valid_607226, JString, required = false,
                                 default = nil)
  if valid_607226 != nil:
    section.add "X-Amz-SignedHeaders", valid_607226
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmName: JString (required)
  ##            : The name for the alarm. This name must be unique within the AWS account. The maximum length is 255 characters.
  ##   StateValue: JString (required)
  ##             : The value of the state.
  ##   StateReason: JString (required)
  ##              : The reason that this alarm is set to this specific state, in text format.
  ##   StateReasonData: JString
  ##                  : The reason that this alarm is set to this specific state, in JSON format.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmName` field"
  var valid_607227 = formData.getOrDefault("AlarmName")
  valid_607227 = validateParameter(valid_607227, JString, required = true,
                                 default = nil)
  if valid_607227 != nil:
    section.add "AlarmName", valid_607227
  var valid_607228 = formData.getOrDefault("StateValue")
  valid_607228 = validateParameter(valid_607228, JString, required = true,
                                 default = newJString("OK"))
  if valid_607228 != nil:
    section.add "StateValue", valid_607228
  var valid_607229 = formData.getOrDefault("StateReason")
  valid_607229 = validateParameter(valid_607229, JString, required = true,
                                 default = nil)
  if valid_607229 != nil:
    section.add "StateReason", valid_607229
  var valid_607230 = formData.getOrDefault("StateReasonData")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "StateReasonData", valid_607230
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607231: Call_PostSetAlarmState_607215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_607231.validator(path, query, header, formData, body)
  let scheme = call_607231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607231.url(scheme.get, call_607231.host, call_607231.base,
                         call_607231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607231, url, valid)

proc call*(call_607232: Call_PostSetAlarmState_607215; AlarmName: string;
          StateReason: string; StateValue: string = "OK";
          StateReasonData: string = ""; Action: string = "SetAlarmState";
          Version: string = "2010-08-01"): Recallable =
  ## postSetAlarmState
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ##   AlarmName: string (required)
  ##            : The name for the alarm. This name must be unique within the AWS account. The maximum length is 255 characters.
  ##   StateValue: string (required)
  ##             : The value of the state.
  ##   StateReason: string (required)
  ##              : The reason that this alarm is set to this specific state, in text format.
  ##   StateReasonData: string
  ##                  : The reason that this alarm is set to this specific state, in JSON format.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607233 = newJObject()
  var formData_607234 = newJObject()
  add(formData_607234, "AlarmName", newJString(AlarmName))
  add(formData_607234, "StateValue", newJString(StateValue))
  add(formData_607234, "StateReason", newJString(StateReason))
  add(formData_607234, "StateReasonData", newJString(StateReasonData))
  add(query_607233, "Action", newJString(Action))
  add(query_607233, "Version", newJString(Version))
  result = call_607232.call(nil, query_607233, nil, formData_607234, nil)

var postSetAlarmState* = Call_PostSetAlarmState_607215(name: "postSetAlarmState",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_PostSetAlarmState_607216,
    base: "/", url: url_PostSetAlarmState_607217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetAlarmState_607196 = ref object of OpenApiRestCall_605589
proc url_GetSetAlarmState_607198(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetAlarmState_607197(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   StateReason: JString (required)
  ##              : The reason that this alarm is set to this specific state, in text format.
  ##   StateValue: JString (required)
  ##             : The value of the state.
  ##   Action: JString (required)
  ##   AlarmName: JString (required)
  ##            : The name for the alarm. This name must be unique within the AWS account. The maximum length is 255 characters.
  ##   StateReasonData: JString
  ##                  : The reason that this alarm is set to this specific state, in JSON format.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `StateReason` field"
  var valid_607199 = query.getOrDefault("StateReason")
  valid_607199 = validateParameter(valid_607199, JString, required = true,
                                 default = nil)
  if valid_607199 != nil:
    section.add "StateReason", valid_607199
  var valid_607200 = query.getOrDefault("StateValue")
  valid_607200 = validateParameter(valid_607200, JString, required = true,
                                 default = newJString("OK"))
  if valid_607200 != nil:
    section.add "StateValue", valid_607200
  var valid_607201 = query.getOrDefault("Action")
  valid_607201 = validateParameter(valid_607201, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_607201 != nil:
    section.add "Action", valid_607201
  var valid_607202 = query.getOrDefault("AlarmName")
  valid_607202 = validateParameter(valid_607202, JString, required = true,
                                 default = nil)
  if valid_607202 != nil:
    section.add "AlarmName", valid_607202
  var valid_607203 = query.getOrDefault("StateReasonData")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "StateReasonData", valid_607203
  var valid_607204 = query.getOrDefault("Version")
  valid_607204 = validateParameter(valid_607204, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607204 != nil:
    section.add "Version", valid_607204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607205 = header.getOrDefault("X-Amz-Signature")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Signature", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-Content-Sha256", valid_607206
  var valid_607207 = header.getOrDefault("X-Amz-Date")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "X-Amz-Date", valid_607207
  var valid_607208 = header.getOrDefault("X-Amz-Credential")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "X-Amz-Credential", valid_607208
  var valid_607209 = header.getOrDefault("X-Amz-Security-Token")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "X-Amz-Security-Token", valid_607209
  var valid_607210 = header.getOrDefault("X-Amz-Algorithm")
  valid_607210 = validateParameter(valid_607210, JString, required = false,
                                 default = nil)
  if valid_607210 != nil:
    section.add "X-Amz-Algorithm", valid_607210
  var valid_607211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "X-Amz-SignedHeaders", valid_607211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607212: Call_GetSetAlarmState_607196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_607212.validator(path, query, header, formData, body)
  let scheme = call_607212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607212.url(scheme.get, call_607212.host, call_607212.base,
                         call_607212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607212, url, valid)

proc call*(call_607213: Call_GetSetAlarmState_607196; StateReason: string;
          AlarmName: string; StateValue: string = "OK";
          Action: string = "SetAlarmState"; StateReasonData: string = "";
          Version: string = "2010-08-01"): Recallable =
  ## getSetAlarmState
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ##   StateReason: string (required)
  ##              : The reason that this alarm is set to this specific state, in text format.
  ##   StateValue: string (required)
  ##             : The value of the state.
  ##   Action: string (required)
  ##   AlarmName: string (required)
  ##            : The name for the alarm. This name must be unique within the AWS account. The maximum length is 255 characters.
  ##   StateReasonData: string
  ##                  : The reason that this alarm is set to this specific state, in JSON format.
  ##   Version: string (required)
  var query_607214 = newJObject()
  add(query_607214, "StateReason", newJString(StateReason))
  add(query_607214, "StateValue", newJString(StateValue))
  add(query_607214, "Action", newJString(Action))
  add(query_607214, "AlarmName", newJString(AlarmName))
  add(query_607214, "StateReasonData", newJString(StateReasonData))
  add(query_607214, "Version", newJString(Version))
  result = call_607213.call(nil, query_607214, nil, nil, nil)

var getSetAlarmState* = Call_GetSetAlarmState_607196(name: "getSetAlarmState",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_GetSetAlarmState_607197,
    base: "/", url: url_GetSetAlarmState_607198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_607252 = ref object of OpenApiRestCall_605589
proc url_PostTagResource_607254(protocol: Scheme; host: string; base: string;
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

proc validate_PostTagResource_607253(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607255 = query.getOrDefault("Action")
  valid_607255 = validateParameter(valid_607255, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_607255 != nil:
    section.add "Action", valid_607255
  var valid_607256 = query.getOrDefault("Version")
  valid_607256 = validateParameter(valid_607256, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607256 != nil:
    section.add "Version", valid_607256
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607257 = header.getOrDefault("X-Amz-Signature")
  valid_607257 = validateParameter(valid_607257, JString, required = false,
                                 default = nil)
  if valid_607257 != nil:
    section.add "X-Amz-Signature", valid_607257
  var valid_607258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607258 = validateParameter(valid_607258, JString, required = false,
                                 default = nil)
  if valid_607258 != nil:
    section.add "X-Amz-Content-Sha256", valid_607258
  var valid_607259 = header.getOrDefault("X-Amz-Date")
  valid_607259 = validateParameter(valid_607259, JString, required = false,
                                 default = nil)
  if valid_607259 != nil:
    section.add "X-Amz-Date", valid_607259
  var valid_607260 = header.getOrDefault("X-Amz-Credential")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-Credential", valid_607260
  var valid_607261 = header.getOrDefault("X-Amz-Security-Token")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Security-Token", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Algorithm")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Algorithm", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-SignedHeaders", valid_607263
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
  var valid_607264 = formData.getOrDefault("Tags")
  valid_607264 = validateParameter(valid_607264, JArray, required = true, default = nil)
  if valid_607264 != nil:
    section.add "Tags", valid_607264
  var valid_607265 = formData.getOrDefault("ResourceARN")
  valid_607265 = validateParameter(valid_607265, JString, required = true,
                                 default = nil)
  if valid_607265 != nil:
    section.add "ResourceARN", valid_607265
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607266: Call_PostTagResource_607252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_607266.validator(path, query, header, formData, body)
  let scheme = call_607266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607266.url(scheme.get, call_607266.host, call_607266.base,
                         call_607266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607266, url, valid)

proc call*(call_607267: Call_PostTagResource_607252; Tags: JsonNode;
          ResourceARN: string; Action: string = "TagResource";
          Version: string = "2010-08-01"): Recallable =
  ## postTagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the alarm.
  ##   Version: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch alarm that you're adding tags to. The ARN format is 
  ## <code>arn:aws:cloudwatch:<i>Region</i>:<i>account-id</i>:alarm:<i>alarm-name</i> </code> 
  var query_607268 = newJObject()
  var formData_607269 = newJObject()
  add(query_607268, "Action", newJString(Action))
  if Tags != nil:
    formData_607269.add "Tags", Tags
  add(query_607268, "Version", newJString(Version))
  add(formData_607269, "ResourceARN", newJString(ResourceARN))
  result = call_607267.call(nil, query_607268, nil, formData_607269, nil)

var postTagResource* = Call_PostTagResource_607252(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_607253,
    base: "/", url: url_PostTagResource_607254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_607235 = ref object of OpenApiRestCall_605589
proc url_GetTagResource_607237(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagResource_607236(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the alarm.
  ##   Action: JString (required)
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch alarm that you're adding tags to. The ARN format is 
  ## <code>arn:aws:cloudwatch:<i>Region</i>:<i>account-id</i>:alarm:<i>alarm-name</i> </code> 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_607238 = query.getOrDefault("Tags")
  valid_607238 = validateParameter(valid_607238, JArray, required = true, default = nil)
  if valid_607238 != nil:
    section.add "Tags", valid_607238
  var valid_607239 = query.getOrDefault("Action")
  valid_607239 = validateParameter(valid_607239, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_607239 != nil:
    section.add "Action", valid_607239
  var valid_607240 = query.getOrDefault("ResourceARN")
  valid_607240 = validateParameter(valid_607240, JString, required = true,
                                 default = nil)
  if valid_607240 != nil:
    section.add "ResourceARN", valid_607240
  var valid_607241 = query.getOrDefault("Version")
  valid_607241 = validateParameter(valid_607241, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607241 != nil:
    section.add "Version", valid_607241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607242 = header.getOrDefault("X-Amz-Signature")
  valid_607242 = validateParameter(valid_607242, JString, required = false,
                                 default = nil)
  if valid_607242 != nil:
    section.add "X-Amz-Signature", valid_607242
  var valid_607243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607243 = validateParameter(valid_607243, JString, required = false,
                                 default = nil)
  if valid_607243 != nil:
    section.add "X-Amz-Content-Sha256", valid_607243
  var valid_607244 = header.getOrDefault("X-Amz-Date")
  valid_607244 = validateParameter(valid_607244, JString, required = false,
                                 default = nil)
  if valid_607244 != nil:
    section.add "X-Amz-Date", valid_607244
  var valid_607245 = header.getOrDefault("X-Amz-Credential")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-Credential", valid_607245
  var valid_607246 = header.getOrDefault("X-Amz-Security-Token")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-Security-Token", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-Algorithm")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Algorithm", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-SignedHeaders", valid_607248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607249: Call_GetTagResource_607235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_607249.validator(path, query, header, formData, body)
  let scheme = call_607249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607249.url(scheme.get, call_607249.host, call_607249.base,
                         call_607249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607249, url, valid)

proc call*(call_607250: Call_GetTagResource_607235; Tags: JsonNode;
          ResourceARN: string; Action: string = "TagResource";
          Version: string = "2010-08-01"): Recallable =
  ## getTagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the alarm.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch alarm that you're adding tags to. The ARN format is 
  ## <code>arn:aws:cloudwatch:<i>Region</i>:<i>account-id</i>:alarm:<i>alarm-name</i> </code> 
  ##   Version: string (required)
  var query_607251 = newJObject()
  if Tags != nil:
    query_607251.add "Tags", Tags
  add(query_607251, "Action", newJString(Action))
  add(query_607251, "ResourceARN", newJString(ResourceARN))
  add(query_607251, "Version", newJString(Version))
  result = call_607250.call(nil, query_607251, nil, nil, nil)

var getTagResource* = Call_GetTagResource_607235(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_607236,
    base: "/", url: url_GetTagResource_607237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_607287 = ref object of OpenApiRestCall_605589
proc url_PostUntagResource_607289(protocol: Scheme; host: string; base: string;
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

proc validate_PostUntagResource_607288(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607290 = query.getOrDefault("Action")
  valid_607290 = validateParameter(valid_607290, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_607290 != nil:
    section.add "Action", valid_607290
  var valid_607291 = query.getOrDefault("Version")
  valid_607291 = validateParameter(valid_607291, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607291 != nil:
    section.add "Version", valid_607291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607292 = header.getOrDefault("X-Amz-Signature")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-Signature", valid_607292
  var valid_607293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Content-Sha256", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Date")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Date", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Credential")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Credential", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-Security-Token")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-Security-Token", valid_607296
  var valid_607297 = header.getOrDefault("X-Amz-Algorithm")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "X-Amz-Algorithm", valid_607297
  var valid_607298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-SignedHeaders", valid_607298
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the resource.
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you're removing tags from. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_607299 = formData.getOrDefault("TagKeys")
  valid_607299 = validateParameter(valid_607299, JArray, required = true, default = nil)
  if valid_607299 != nil:
    section.add "TagKeys", valid_607299
  var valid_607300 = formData.getOrDefault("ResourceARN")
  valid_607300 = validateParameter(valid_607300, JString, required = true,
                                 default = nil)
  if valid_607300 != nil:
    section.add "ResourceARN", valid_607300
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607301: Call_PostUntagResource_607287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_607301.validator(path, query, header, formData, body)
  let scheme = call_607301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607301.url(scheme.get, call_607301.host, call_607301.base,
                         call_607301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607301, url, valid)

proc call*(call_607302: Call_PostUntagResource_607287; TagKeys: JsonNode;
          ResourceARN: string; Action: string = "UntagResource";
          Version: string = "2010-08-01"): Recallable =
  ## postUntagResource
  ## Removes one or more tags from the specified resource.
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the resource.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you're removing tags from. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  var query_607303 = newJObject()
  var formData_607304 = newJObject()
  if TagKeys != nil:
    formData_607304.add "TagKeys", TagKeys
  add(query_607303, "Action", newJString(Action))
  add(query_607303, "Version", newJString(Version))
  add(formData_607304, "ResourceARN", newJString(ResourceARN))
  result = call_607302.call(nil, query_607303, nil, formData_607304, nil)

var postUntagResource* = Call_PostUntagResource_607287(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_607288,
    base: "/", url: url_PostUntagResource_607289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_607270 = ref object of OpenApiRestCall_605589
proc url_GetUntagResource_607272(protocol: Scheme; host: string; base: string;
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

proc validate_GetUntagResource_607271(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Removes one or more tags from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the resource.
  ##   Action: JString (required)
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you're removing tags from. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TagKeys` field"
  var valid_607273 = query.getOrDefault("TagKeys")
  valid_607273 = validateParameter(valid_607273, JArray, required = true, default = nil)
  if valid_607273 != nil:
    section.add "TagKeys", valid_607273
  var valid_607274 = query.getOrDefault("Action")
  valid_607274 = validateParameter(valid_607274, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_607274 != nil:
    section.add "Action", valid_607274
  var valid_607275 = query.getOrDefault("ResourceARN")
  valid_607275 = validateParameter(valid_607275, JString, required = true,
                                 default = nil)
  if valid_607275 != nil:
    section.add "ResourceARN", valid_607275
  var valid_607276 = query.getOrDefault("Version")
  valid_607276 = validateParameter(valid_607276, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607276 != nil:
    section.add "Version", valid_607276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607277 = header.getOrDefault("X-Amz-Signature")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Signature", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Content-Sha256", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Date")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Date", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Credential")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Credential", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-Security-Token")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Security-Token", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Algorithm")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Algorithm", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-SignedHeaders", valid_607283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607284: Call_GetUntagResource_607270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_607284.validator(path, query, header, formData, body)
  let scheme = call_607284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607284.url(scheme.get, call_607284.host, call_607284.base,
                         call_607284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607284, url, valid)

proc call*(call_607285: Call_GetUntagResource_607270; TagKeys: JsonNode;
          ResourceARN: string; Action: string = "UntagResource";
          Version: string = "2010-08-01"): Recallable =
  ## getUntagResource
  ## Removes one or more tags from the specified resource.
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the resource.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you're removing tags from. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_607286 = newJObject()
  if TagKeys != nil:
    query_607286.add "TagKeys", TagKeys
  add(query_607286, "Action", newJString(Action))
  add(query_607286, "ResourceARN", newJString(ResourceARN))
  add(query_607286, "Version", newJString(Version))
  result = call_607285.call(nil, query_607286, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_607270(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_607271,
    base: "/", url: url_GetUntagResource_607272,
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
