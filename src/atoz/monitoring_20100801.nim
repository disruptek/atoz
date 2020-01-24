
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

  OpenApiRestCall_606589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_606589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_606589): Option[Scheme] {.used.} =
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
  Call_PostDeleteAlarms_607198 = ref object of OpenApiRestCall_606589
proc url_PostDeleteAlarms_607200(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteAlarms_607199(path: JsonNode; query: JsonNode;
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
  var valid_607201 = query.getOrDefault("Action")
  valid_607201 = validateParameter(valid_607201, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_607201 != nil:
    section.add "Action", valid_607201
  var valid_607202 = query.getOrDefault("Version")
  valid_607202 = validateParameter(valid_607202, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607202 != nil:
    section.add "Version", valid_607202
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
  var valid_607203 = header.getOrDefault("X-Amz-Signature")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Signature", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Content-Sha256", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Date")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Date", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-Credential")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-Credential", valid_607206
  var valid_607207 = header.getOrDefault("X-Amz-Security-Token")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "X-Amz-Security-Token", valid_607207
  var valid_607208 = header.getOrDefault("X-Amz-Algorithm")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "X-Amz-Algorithm", valid_607208
  var valid_607209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "X-Amz-SignedHeaders", valid_607209
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_607210 = formData.getOrDefault("AlarmNames")
  valid_607210 = validateParameter(valid_607210, JArray, required = true, default = nil)
  if valid_607210 != nil:
    section.add "AlarmNames", valid_607210
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607211: Call_PostDeleteAlarms_607198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_607211.validator(path, query, header, formData, body)
  let scheme = call_607211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607211.url(scheme.get, call_607211.host, call_607211.base,
                         call_607211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607211, url, valid)

proc call*(call_607212: Call_PostDeleteAlarms_607198; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  var query_607213 = newJObject()
  var formData_607214 = newJObject()
  add(query_607213, "Action", newJString(Action))
  add(query_607213, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_607214.add "AlarmNames", AlarmNames
  result = call_607212.call(nil, query_607213, nil, formData_607214, nil)

var postDeleteAlarms* = Call_PostDeleteAlarms_607198(name: "postDeleteAlarms",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_PostDeleteAlarms_607199,
    base: "/", url: url_PostDeleteAlarms_607200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAlarms_606927 = ref object of OpenApiRestCall_606589
proc url_GetDeleteAlarms_606929(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteAlarms_606928(path: JsonNode; query: JsonNode;
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
  var valid_607041 = query.getOrDefault("AlarmNames")
  valid_607041 = validateParameter(valid_607041, JArray, required = true, default = nil)
  if valid_607041 != nil:
    section.add "AlarmNames", valid_607041
  var valid_607055 = query.getOrDefault("Action")
  valid_607055 = validateParameter(valid_607055, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_607055 != nil:
    section.add "Action", valid_607055
  var valid_607056 = query.getOrDefault("Version")
  valid_607056 = validateParameter(valid_607056, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607056 != nil:
    section.add "Version", valid_607056
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

proc call*(call_607086: Call_GetDeleteAlarms_606927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_607086.validator(path, query, header, formData, body)
  let scheme = call_607086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607086.url(scheme.get, call_607086.host, call_607086.base,
                         call_607086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607086, url, valid)

proc call*(call_607157: Call_GetDeleteAlarms_606927; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607158 = newJObject()
  if AlarmNames != nil:
    query_607158.add "AlarmNames", AlarmNames
  add(query_607158, "Action", newJString(Action))
  add(query_607158, "Version", newJString(Version))
  result = call_607157.call(nil, query_607158, nil, nil, nil)

var getDeleteAlarms* = Call_GetDeleteAlarms_606927(name: "getDeleteAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_GetDeleteAlarms_606928,
    base: "/", url: url_GetDeleteAlarms_606929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnomalyDetector_607234 = ref object of OpenApiRestCall_606589
proc url_PostDeleteAnomalyDetector_607236(protocol: Scheme; host: string;
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

proc validate_PostDeleteAnomalyDetector_607235(path: JsonNode; query: JsonNode;
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
  var valid_607237 = query.getOrDefault("Action")
  valid_607237 = validateParameter(valid_607237, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_607237 != nil:
    section.add "Action", valid_607237
  var valid_607238 = query.getOrDefault("Version")
  valid_607238 = validateParameter(valid_607238, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607238 != nil:
    section.add "Version", valid_607238
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
  var valid_607239 = header.getOrDefault("X-Amz-Signature")
  valid_607239 = validateParameter(valid_607239, JString, required = false,
                                 default = nil)
  if valid_607239 != nil:
    section.add "X-Amz-Signature", valid_607239
  var valid_607240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607240 = validateParameter(valid_607240, JString, required = false,
                                 default = nil)
  if valid_607240 != nil:
    section.add "X-Amz-Content-Sha256", valid_607240
  var valid_607241 = header.getOrDefault("X-Amz-Date")
  valid_607241 = validateParameter(valid_607241, JString, required = false,
                                 default = nil)
  if valid_607241 != nil:
    section.add "X-Amz-Date", valid_607241
  var valid_607242 = header.getOrDefault("X-Amz-Credential")
  valid_607242 = validateParameter(valid_607242, JString, required = false,
                                 default = nil)
  if valid_607242 != nil:
    section.add "X-Amz-Credential", valid_607242
  var valid_607243 = header.getOrDefault("X-Amz-Security-Token")
  valid_607243 = validateParameter(valid_607243, JString, required = false,
                                 default = nil)
  if valid_607243 != nil:
    section.add "X-Amz-Security-Token", valid_607243
  var valid_607244 = header.getOrDefault("X-Amz-Algorithm")
  valid_607244 = validateParameter(valid_607244, JString, required = false,
                                 default = nil)
  if valid_607244 != nil:
    section.add "X-Amz-Algorithm", valid_607244
  var valid_607245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-SignedHeaders", valid_607245
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
  var valid_607246 = formData.getOrDefault("Stat")
  valid_607246 = validateParameter(valid_607246, JString, required = true,
                                 default = nil)
  if valid_607246 != nil:
    section.add "Stat", valid_607246
  var valid_607247 = formData.getOrDefault("MetricName")
  valid_607247 = validateParameter(valid_607247, JString, required = true,
                                 default = nil)
  if valid_607247 != nil:
    section.add "MetricName", valid_607247
  var valid_607248 = formData.getOrDefault("Dimensions")
  valid_607248 = validateParameter(valid_607248, JArray, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "Dimensions", valid_607248
  var valid_607249 = formData.getOrDefault("Namespace")
  valid_607249 = validateParameter(valid_607249, JString, required = true,
                                 default = nil)
  if valid_607249 != nil:
    section.add "Namespace", valid_607249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607250: Call_PostDeleteAnomalyDetector_607234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_607250.validator(path, query, header, formData, body)
  let scheme = call_607250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607250.url(scheme.get, call_607250.host, call_607250.base,
                         call_607250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607250, url, valid)

proc call*(call_607251: Call_PostDeleteAnomalyDetector_607234; Stat: string;
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
  var query_607252 = newJObject()
  var formData_607253 = newJObject()
  add(formData_607253, "Stat", newJString(Stat))
  add(formData_607253, "MetricName", newJString(MetricName))
  add(query_607252, "Action", newJString(Action))
  if Dimensions != nil:
    formData_607253.add "Dimensions", Dimensions
  add(formData_607253, "Namespace", newJString(Namespace))
  add(query_607252, "Version", newJString(Version))
  result = call_607251.call(nil, query_607252, nil, formData_607253, nil)

var postDeleteAnomalyDetector* = Call_PostDeleteAnomalyDetector_607234(
    name: "postDeleteAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_PostDeleteAnomalyDetector_607235, base: "/",
    url: url_PostDeleteAnomalyDetector_607236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnomalyDetector_607215 = ref object of OpenApiRestCall_606589
proc url_GetDeleteAnomalyDetector_607217(protocol: Scheme; host: string;
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

proc validate_GetDeleteAnomalyDetector_607216(path: JsonNode; query: JsonNode;
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
  var valid_607218 = query.getOrDefault("Namespace")
  valid_607218 = validateParameter(valid_607218, JString, required = true,
                                 default = nil)
  if valid_607218 != nil:
    section.add "Namespace", valid_607218
  var valid_607219 = query.getOrDefault("Dimensions")
  valid_607219 = validateParameter(valid_607219, JArray, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "Dimensions", valid_607219
  var valid_607220 = query.getOrDefault("Action")
  valid_607220 = validateParameter(valid_607220, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_607220 != nil:
    section.add "Action", valid_607220
  var valid_607221 = query.getOrDefault("Version")
  valid_607221 = validateParameter(valid_607221, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607221 != nil:
    section.add "Version", valid_607221
  var valid_607222 = query.getOrDefault("MetricName")
  valid_607222 = validateParameter(valid_607222, JString, required = true,
                                 default = nil)
  if valid_607222 != nil:
    section.add "MetricName", valid_607222
  var valid_607223 = query.getOrDefault("Stat")
  valid_607223 = validateParameter(valid_607223, JString, required = true,
                                 default = nil)
  if valid_607223 != nil:
    section.add "Stat", valid_607223
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
  var valid_607224 = header.getOrDefault("X-Amz-Signature")
  valid_607224 = validateParameter(valid_607224, JString, required = false,
                                 default = nil)
  if valid_607224 != nil:
    section.add "X-Amz-Signature", valid_607224
  var valid_607225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607225 = validateParameter(valid_607225, JString, required = false,
                                 default = nil)
  if valid_607225 != nil:
    section.add "X-Amz-Content-Sha256", valid_607225
  var valid_607226 = header.getOrDefault("X-Amz-Date")
  valid_607226 = validateParameter(valid_607226, JString, required = false,
                                 default = nil)
  if valid_607226 != nil:
    section.add "X-Amz-Date", valid_607226
  var valid_607227 = header.getOrDefault("X-Amz-Credential")
  valid_607227 = validateParameter(valid_607227, JString, required = false,
                                 default = nil)
  if valid_607227 != nil:
    section.add "X-Amz-Credential", valid_607227
  var valid_607228 = header.getOrDefault("X-Amz-Security-Token")
  valid_607228 = validateParameter(valid_607228, JString, required = false,
                                 default = nil)
  if valid_607228 != nil:
    section.add "X-Amz-Security-Token", valid_607228
  var valid_607229 = header.getOrDefault("X-Amz-Algorithm")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "X-Amz-Algorithm", valid_607229
  var valid_607230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "X-Amz-SignedHeaders", valid_607230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607231: Call_GetDeleteAnomalyDetector_607215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_607231.validator(path, query, header, formData, body)
  let scheme = call_607231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607231.url(scheme.get, call_607231.host, call_607231.base,
                         call_607231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607231, url, valid)

proc call*(call_607232: Call_GetDeleteAnomalyDetector_607215; Namespace: string;
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
  var query_607233 = newJObject()
  add(query_607233, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_607233.add "Dimensions", Dimensions
  add(query_607233, "Action", newJString(Action))
  add(query_607233, "Version", newJString(Version))
  add(query_607233, "MetricName", newJString(MetricName))
  add(query_607233, "Stat", newJString(Stat))
  result = call_607232.call(nil, query_607233, nil, nil, nil)

var getDeleteAnomalyDetector* = Call_GetDeleteAnomalyDetector_607215(
    name: "getDeleteAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_GetDeleteAnomalyDetector_607216, base: "/",
    url: url_GetDeleteAnomalyDetector_607217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDashboards_607270 = ref object of OpenApiRestCall_606589
proc url_PostDeleteDashboards_607272(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDashboards_607271(path: JsonNode; query: JsonNode;
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
  var valid_607273 = query.getOrDefault("Action")
  valid_607273 = validateParameter(valid_607273, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_607273 != nil:
    section.add "Action", valid_607273
  var valid_607274 = query.getOrDefault("Version")
  valid_607274 = validateParameter(valid_607274, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607274 != nil:
    section.add "Version", valid_607274
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
  var valid_607275 = header.getOrDefault("X-Amz-Signature")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "X-Amz-Signature", valid_607275
  var valid_607276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "X-Amz-Content-Sha256", valid_607276
  var valid_607277 = header.getOrDefault("X-Amz-Date")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Date", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Credential")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Credential", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Security-Token")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Security-Token", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Algorithm")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Algorithm", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-SignedHeaders", valid_607281
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardNames` field"
  var valid_607282 = formData.getOrDefault("DashboardNames")
  valid_607282 = validateParameter(valid_607282, JArray, required = true, default = nil)
  if valid_607282 != nil:
    section.add "DashboardNames", valid_607282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607283: Call_PostDeleteDashboards_607270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_607283.validator(path, query, header, formData, body)
  let scheme = call_607283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607283.url(scheme.get, call_607283.host, call_607283.base,
                         call_607283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607283, url, valid)

proc call*(call_607284: Call_PostDeleteDashboards_607270; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607285 = newJObject()
  var formData_607286 = newJObject()
  if DashboardNames != nil:
    formData_607286.add "DashboardNames", DashboardNames
  add(query_607285, "Action", newJString(Action))
  add(query_607285, "Version", newJString(Version))
  result = call_607284.call(nil, query_607285, nil, formData_607286, nil)

var postDeleteDashboards* = Call_PostDeleteDashboards_607270(
    name: "postDeleteDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_PostDeleteDashboards_607271, base: "/",
    url: url_PostDeleteDashboards_607272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDashboards_607254 = ref object of OpenApiRestCall_606589
proc url_GetDeleteDashboards_607256(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDashboards_607255(path: JsonNode; query: JsonNode;
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
  var valid_607257 = query.getOrDefault("DashboardNames")
  valid_607257 = validateParameter(valid_607257, JArray, required = true, default = nil)
  if valid_607257 != nil:
    section.add "DashboardNames", valid_607257
  var valid_607258 = query.getOrDefault("Action")
  valid_607258 = validateParameter(valid_607258, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_607258 != nil:
    section.add "Action", valid_607258
  var valid_607259 = query.getOrDefault("Version")
  valid_607259 = validateParameter(valid_607259, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607259 != nil:
    section.add "Version", valid_607259
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
  var valid_607260 = header.getOrDefault("X-Amz-Signature")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-Signature", valid_607260
  var valid_607261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Content-Sha256", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Date")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Date", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-Credential")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Credential", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Security-Token")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Security-Token", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Algorithm")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Algorithm", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-SignedHeaders", valid_607266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607267: Call_GetDeleteDashboards_607254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_607267.validator(path, query, header, formData, body)
  let scheme = call_607267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607267.url(scheme.get, call_607267.host, call_607267.base,
                         call_607267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607267, url, valid)

proc call*(call_607268: Call_GetDeleteDashboards_607254; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607269 = newJObject()
  if DashboardNames != nil:
    query_607269.add "DashboardNames", DashboardNames
  add(query_607269, "Action", newJString(Action))
  add(query_607269, "Version", newJString(Version))
  result = call_607268.call(nil, query_607269, nil, nil, nil)

var getDeleteDashboards* = Call_GetDeleteDashboards_607254(
    name: "getDeleteDashboards", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_GetDeleteDashboards_607255, base: "/",
    url: url_GetDeleteDashboards_607256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteInsightRules_607303 = ref object of OpenApiRestCall_606589
proc url_PostDeleteInsightRules_607305(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteInsightRules_607304(path: JsonNode; query: JsonNode;
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
  var valid_607306 = query.getOrDefault("Action")
  valid_607306 = validateParameter(valid_607306, JString, required = true,
                                 default = newJString("DeleteInsightRules"))
  if valid_607306 != nil:
    section.add "Action", valid_607306
  var valid_607307 = query.getOrDefault("Version")
  valid_607307 = validateParameter(valid_607307, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607307 != nil:
    section.add "Version", valid_607307
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
  var valid_607308 = header.getOrDefault("X-Amz-Signature")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "X-Amz-Signature", valid_607308
  var valid_607309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Content-Sha256", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Date")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Date", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-Credential")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-Credential", valid_607311
  var valid_607312 = header.getOrDefault("X-Amz-Security-Token")
  valid_607312 = validateParameter(valid_607312, JString, required = false,
                                 default = nil)
  if valid_607312 != nil:
    section.add "X-Amz-Security-Token", valid_607312
  var valid_607313 = header.getOrDefault("X-Amz-Algorithm")
  valid_607313 = validateParameter(valid_607313, JString, required = false,
                                 default = nil)
  if valid_607313 != nil:
    section.add "X-Amz-Algorithm", valid_607313
  var valid_607314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607314 = validateParameter(valid_607314, JString, required = false,
                                 default = nil)
  if valid_607314 != nil:
    section.add "X-Amz-SignedHeaders", valid_607314
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_607315 = formData.getOrDefault("RuleNames")
  valid_607315 = validateParameter(valid_607315, JArray, required = true, default = nil)
  if valid_607315 != nil:
    section.add "RuleNames", valid_607315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607316: Call_PostDeleteInsightRules_607303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_607316.validator(path, query, header, formData, body)
  let scheme = call_607316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607316.url(scheme.get, call_607316.host, call_607316.base,
                         call_607316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607316, url, valid)

proc call*(call_607317: Call_PostDeleteInsightRules_607303; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607318 = newJObject()
  var formData_607319 = newJObject()
  if RuleNames != nil:
    formData_607319.add "RuleNames", RuleNames
  add(query_607318, "Action", newJString(Action))
  add(query_607318, "Version", newJString(Version))
  result = call_607317.call(nil, query_607318, nil, formData_607319, nil)

var postDeleteInsightRules* = Call_PostDeleteInsightRules_607303(
    name: "postDeleteInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_PostDeleteInsightRules_607304, base: "/",
    url: url_PostDeleteInsightRules_607305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteInsightRules_607287 = ref object of OpenApiRestCall_606589
proc url_GetDeleteInsightRules_607289(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteInsightRules_607288(path: JsonNode; query: JsonNode;
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
  var valid_607290 = query.getOrDefault("Action")
  valid_607290 = validateParameter(valid_607290, JString, required = true,
                                 default = newJString("DeleteInsightRules"))
  if valid_607290 != nil:
    section.add "Action", valid_607290
  var valid_607291 = query.getOrDefault("RuleNames")
  valid_607291 = validateParameter(valid_607291, JArray, required = true, default = nil)
  if valid_607291 != nil:
    section.add "RuleNames", valid_607291
  var valid_607292 = query.getOrDefault("Version")
  valid_607292 = validateParameter(valid_607292, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607292 != nil:
    section.add "Version", valid_607292
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
  var valid_607293 = header.getOrDefault("X-Amz-Signature")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Signature", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Content-Sha256", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Date")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Date", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-Credential")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-Credential", valid_607296
  var valid_607297 = header.getOrDefault("X-Amz-Security-Token")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "X-Amz-Security-Token", valid_607297
  var valid_607298 = header.getOrDefault("X-Amz-Algorithm")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-Algorithm", valid_607298
  var valid_607299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607299 = validateParameter(valid_607299, JString, required = false,
                                 default = nil)
  if valid_607299 != nil:
    section.add "X-Amz-SignedHeaders", valid_607299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607300: Call_GetDeleteInsightRules_607287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_607300.validator(path, query, header, formData, body)
  let scheme = call_607300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607300.url(scheme.get, call_607300.host, call_607300.base,
                         call_607300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607300, url, valid)

proc call*(call_607301: Call_GetDeleteInsightRules_607287; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_607302 = newJObject()
  add(query_607302, "Action", newJString(Action))
  if RuleNames != nil:
    query_607302.add "RuleNames", RuleNames
  add(query_607302, "Version", newJString(Version))
  result = call_607301.call(nil, query_607302, nil, nil, nil)

var getDeleteInsightRules* = Call_GetDeleteInsightRules_607287(
    name: "getDeleteInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_GetDeleteInsightRules_607288, base: "/",
    url: url_GetDeleteInsightRules_607289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmHistory_607341 = ref object of OpenApiRestCall_606589
proc url_PostDescribeAlarmHistory_607343(protocol: Scheme; host: string;
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

proc validate_PostDescribeAlarmHistory_607342(path: JsonNode; query: JsonNode;
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
  var valid_607344 = query.getOrDefault("Action")
  valid_607344 = validateParameter(valid_607344, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_607344 != nil:
    section.add "Action", valid_607344
  var valid_607345 = query.getOrDefault("Version")
  valid_607345 = validateParameter(valid_607345, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607345 != nil:
    section.add "Version", valid_607345
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
  var valid_607346 = header.getOrDefault("X-Amz-Signature")
  valid_607346 = validateParameter(valid_607346, JString, required = false,
                                 default = nil)
  if valid_607346 != nil:
    section.add "X-Amz-Signature", valid_607346
  var valid_607347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607347 = validateParameter(valid_607347, JString, required = false,
                                 default = nil)
  if valid_607347 != nil:
    section.add "X-Amz-Content-Sha256", valid_607347
  var valid_607348 = header.getOrDefault("X-Amz-Date")
  valid_607348 = validateParameter(valid_607348, JString, required = false,
                                 default = nil)
  if valid_607348 != nil:
    section.add "X-Amz-Date", valid_607348
  var valid_607349 = header.getOrDefault("X-Amz-Credential")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "X-Amz-Credential", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Security-Token")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Security-Token", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Algorithm")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Algorithm", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-SignedHeaders", valid_607352
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
  var valid_607353 = formData.getOrDefault("AlarmName")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "AlarmName", valid_607353
  var valid_607354 = formData.getOrDefault("HistoryItemType")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_607354 != nil:
    section.add "HistoryItemType", valid_607354
  var valid_607355 = formData.getOrDefault("MaxRecords")
  valid_607355 = validateParameter(valid_607355, JInt, required = false, default = nil)
  if valid_607355 != nil:
    section.add "MaxRecords", valid_607355
  var valid_607356 = formData.getOrDefault("EndDate")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "EndDate", valid_607356
  var valid_607357 = formData.getOrDefault("NextToken")
  valid_607357 = validateParameter(valid_607357, JString, required = false,
                                 default = nil)
  if valid_607357 != nil:
    section.add "NextToken", valid_607357
  var valid_607358 = formData.getOrDefault("StartDate")
  valid_607358 = validateParameter(valid_607358, JString, required = false,
                                 default = nil)
  if valid_607358 != nil:
    section.add "StartDate", valid_607358
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607359: Call_PostDescribeAlarmHistory_607341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_607359.validator(path, query, header, formData, body)
  let scheme = call_607359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607359.url(scheme.get, call_607359.host, call_607359.base,
                         call_607359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607359, url, valid)

proc call*(call_607360: Call_PostDescribeAlarmHistory_607341;
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
  var query_607361 = newJObject()
  var formData_607362 = newJObject()
  add(formData_607362, "AlarmName", newJString(AlarmName))
  add(formData_607362, "HistoryItemType", newJString(HistoryItemType))
  add(formData_607362, "MaxRecords", newJInt(MaxRecords))
  add(formData_607362, "EndDate", newJString(EndDate))
  add(formData_607362, "NextToken", newJString(NextToken))
  add(formData_607362, "StartDate", newJString(StartDate))
  add(query_607361, "Action", newJString(Action))
  add(query_607361, "Version", newJString(Version))
  result = call_607360.call(nil, query_607361, nil, formData_607362, nil)

var postDescribeAlarmHistory* = Call_PostDescribeAlarmHistory_607341(
    name: "postDescribeAlarmHistory", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_PostDescribeAlarmHistory_607342, base: "/",
    url: url_PostDescribeAlarmHistory_607343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmHistory_607320 = ref object of OpenApiRestCall_606589
proc url_GetDescribeAlarmHistory_607322(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeAlarmHistory_607321(path: JsonNode; query: JsonNode;
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
  var valid_607323 = query.getOrDefault("EndDate")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "EndDate", valid_607323
  var valid_607324 = query.getOrDefault("NextToken")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "NextToken", valid_607324
  var valid_607325 = query.getOrDefault("HistoryItemType")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_607325 != nil:
    section.add "HistoryItemType", valid_607325
  var valid_607326 = query.getOrDefault("Action")
  valid_607326 = validateParameter(valid_607326, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_607326 != nil:
    section.add "Action", valid_607326
  var valid_607327 = query.getOrDefault("AlarmName")
  valid_607327 = validateParameter(valid_607327, JString, required = false,
                                 default = nil)
  if valid_607327 != nil:
    section.add "AlarmName", valid_607327
  var valid_607328 = query.getOrDefault("StartDate")
  valid_607328 = validateParameter(valid_607328, JString, required = false,
                                 default = nil)
  if valid_607328 != nil:
    section.add "StartDate", valid_607328
  var valid_607329 = query.getOrDefault("Version")
  valid_607329 = validateParameter(valid_607329, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607329 != nil:
    section.add "Version", valid_607329
  var valid_607330 = query.getOrDefault("MaxRecords")
  valid_607330 = validateParameter(valid_607330, JInt, required = false, default = nil)
  if valid_607330 != nil:
    section.add "MaxRecords", valid_607330
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
  var valid_607331 = header.getOrDefault("X-Amz-Signature")
  valid_607331 = validateParameter(valid_607331, JString, required = false,
                                 default = nil)
  if valid_607331 != nil:
    section.add "X-Amz-Signature", valid_607331
  var valid_607332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607332 = validateParameter(valid_607332, JString, required = false,
                                 default = nil)
  if valid_607332 != nil:
    section.add "X-Amz-Content-Sha256", valid_607332
  var valid_607333 = header.getOrDefault("X-Amz-Date")
  valid_607333 = validateParameter(valid_607333, JString, required = false,
                                 default = nil)
  if valid_607333 != nil:
    section.add "X-Amz-Date", valid_607333
  var valid_607334 = header.getOrDefault("X-Amz-Credential")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "X-Amz-Credential", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Security-Token")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Security-Token", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Algorithm")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Algorithm", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-SignedHeaders", valid_607337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607338: Call_GetDescribeAlarmHistory_607320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_607338.validator(path, query, header, formData, body)
  let scheme = call_607338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607338.url(scheme.get, call_607338.host, call_607338.base,
                         call_607338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607338, url, valid)

proc call*(call_607339: Call_GetDescribeAlarmHistory_607320; EndDate: string = "";
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
  var query_607340 = newJObject()
  add(query_607340, "EndDate", newJString(EndDate))
  add(query_607340, "NextToken", newJString(NextToken))
  add(query_607340, "HistoryItemType", newJString(HistoryItemType))
  add(query_607340, "Action", newJString(Action))
  add(query_607340, "AlarmName", newJString(AlarmName))
  add(query_607340, "StartDate", newJString(StartDate))
  add(query_607340, "Version", newJString(Version))
  add(query_607340, "MaxRecords", newJInt(MaxRecords))
  result = call_607339.call(nil, query_607340, nil, nil, nil)

var getDescribeAlarmHistory* = Call_GetDescribeAlarmHistory_607320(
    name: "getDescribeAlarmHistory", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_GetDescribeAlarmHistory_607321, base: "/",
    url: url_GetDescribeAlarmHistory_607322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarms_607384 = ref object of OpenApiRestCall_606589
proc url_PostDescribeAlarms_607386(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeAlarms_607385(path: JsonNode; query: JsonNode;
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
  var valid_607387 = query.getOrDefault("Action")
  valid_607387 = validateParameter(valid_607387, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_607387 != nil:
    section.add "Action", valid_607387
  var valid_607388 = query.getOrDefault("Version")
  valid_607388 = validateParameter(valid_607388, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607388 != nil:
    section.add "Version", valid_607388
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
  var valid_607389 = header.getOrDefault("X-Amz-Signature")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-Signature", valid_607389
  var valid_607390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607390 = validateParameter(valid_607390, JString, required = false,
                                 default = nil)
  if valid_607390 != nil:
    section.add "X-Amz-Content-Sha256", valid_607390
  var valid_607391 = header.getOrDefault("X-Amz-Date")
  valid_607391 = validateParameter(valid_607391, JString, required = false,
                                 default = nil)
  if valid_607391 != nil:
    section.add "X-Amz-Date", valid_607391
  var valid_607392 = header.getOrDefault("X-Amz-Credential")
  valid_607392 = validateParameter(valid_607392, JString, required = false,
                                 default = nil)
  if valid_607392 != nil:
    section.add "X-Amz-Credential", valid_607392
  var valid_607393 = header.getOrDefault("X-Amz-Security-Token")
  valid_607393 = validateParameter(valid_607393, JString, required = false,
                                 default = nil)
  if valid_607393 != nil:
    section.add "X-Amz-Security-Token", valid_607393
  var valid_607394 = header.getOrDefault("X-Amz-Algorithm")
  valid_607394 = validateParameter(valid_607394, JString, required = false,
                                 default = nil)
  if valid_607394 != nil:
    section.add "X-Amz-Algorithm", valid_607394
  var valid_607395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-SignedHeaders", valid_607395
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
  var valid_607396 = formData.getOrDefault("AlarmNamePrefix")
  valid_607396 = validateParameter(valid_607396, JString, required = false,
                                 default = nil)
  if valid_607396 != nil:
    section.add "AlarmNamePrefix", valid_607396
  var valid_607397 = formData.getOrDefault("StateValue")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = newJString("OK"))
  if valid_607397 != nil:
    section.add "StateValue", valid_607397
  var valid_607398 = formData.getOrDefault("NextToken")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "NextToken", valid_607398
  var valid_607399 = formData.getOrDefault("MaxRecords")
  valid_607399 = validateParameter(valid_607399, JInt, required = false, default = nil)
  if valid_607399 != nil:
    section.add "MaxRecords", valid_607399
  var valid_607400 = formData.getOrDefault("ActionPrefix")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "ActionPrefix", valid_607400
  var valid_607401 = formData.getOrDefault("AlarmNames")
  valid_607401 = validateParameter(valid_607401, JArray, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "AlarmNames", valid_607401
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607402: Call_PostDescribeAlarms_607384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_607402.validator(path, query, header, formData, body)
  let scheme = call_607402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607402.url(scheme.get, call_607402.host, call_607402.base,
                         call_607402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607402, url, valid)

proc call*(call_607403: Call_PostDescribeAlarms_607384;
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
  var query_607404 = newJObject()
  var formData_607405 = newJObject()
  add(formData_607405, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(formData_607405, "StateValue", newJString(StateValue))
  add(formData_607405, "NextToken", newJString(NextToken))
  add(formData_607405, "MaxRecords", newJInt(MaxRecords))
  add(query_607404, "Action", newJString(Action))
  add(formData_607405, "ActionPrefix", newJString(ActionPrefix))
  add(query_607404, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_607405.add "AlarmNames", AlarmNames
  result = call_607403.call(nil, query_607404, nil, formData_607405, nil)

var postDescribeAlarms* = Call_PostDescribeAlarms_607384(
    name: "postDescribeAlarms", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarms",
    validator: validate_PostDescribeAlarms_607385, base: "/",
    url: url_PostDescribeAlarms_607386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarms_607363 = ref object of OpenApiRestCall_606589
proc url_GetDescribeAlarms_607365(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeAlarms_607364(path: JsonNode; query: JsonNode;
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
  var valid_607366 = query.getOrDefault("StateValue")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = newJString("OK"))
  if valid_607366 != nil:
    section.add "StateValue", valid_607366
  var valid_607367 = query.getOrDefault("ActionPrefix")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "ActionPrefix", valid_607367
  var valid_607368 = query.getOrDefault("NextToken")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "NextToken", valid_607368
  var valid_607369 = query.getOrDefault("AlarmNamePrefix")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "AlarmNamePrefix", valid_607369
  var valid_607370 = query.getOrDefault("AlarmNames")
  valid_607370 = validateParameter(valid_607370, JArray, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "AlarmNames", valid_607370
  var valid_607371 = query.getOrDefault("Action")
  valid_607371 = validateParameter(valid_607371, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_607371 != nil:
    section.add "Action", valid_607371
  var valid_607372 = query.getOrDefault("Version")
  valid_607372 = validateParameter(valid_607372, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607372 != nil:
    section.add "Version", valid_607372
  var valid_607373 = query.getOrDefault("MaxRecords")
  valid_607373 = validateParameter(valid_607373, JInt, required = false, default = nil)
  if valid_607373 != nil:
    section.add "MaxRecords", valid_607373
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
  var valid_607374 = header.getOrDefault("X-Amz-Signature")
  valid_607374 = validateParameter(valid_607374, JString, required = false,
                                 default = nil)
  if valid_607374 != nil:
    section.add "X-Amz-Signature", valid_607374
  var valid_607375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607375 = validateParameter(valid_607375, JString, required = false,
                                 default = nil)
  if valid_607375 != nil:
    section.add "X-Amz-Content-Sha256", valid_607375
  var valid_607376 = header.getOrDefault("X-Amz-Date")
  valid_607376 = validateParameter(valid_607376, JString, required = false,
                                 default = nil)
  if valid_607376 != nil:
    section.add "X-Amz-Date", valid_607376
  var valid_607377 = header.getOrDefault("X-Amz-Credential")
  valid_607377 = validateParameter(valid_607377, JString, required = false,
                                 default = nil)
  if valid_607377 != nil:
    section.add "X-Amz-Credential", valid_607377
  var valid_607378 = header.getOrDefault("X-Amz-Security-Token")
  valid_607378 = validateParameter(valid_607378, JString, required = false,
                                 default = nil)
  if valid_607378 != nil:
    section.add "X-Amz-Security-Token", valid_607378
  var valid_607379 = header.getOrDefault("X-Amz-Algorithm")
  valid_607379 = validateParameter(valid_607379, JString, required = false,
                                 default = nil)
  if valid_607379 != nil:
    section.add "X-Amz-Algorithm", valid_607379
  var valid_607380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607380 = validateParameter(valid_607380, JString, required = false,
                                 default = nil)
  if valid_607380 != nil:
    section.add "X-Amz-SignedHeaders", valid_607380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607381: Call_GetDescribeAlarms_607363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_607381.validator(path, query, header, formData, body)
  let scheme = call_607381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607381.url(scheme.get, call_607381.host, call_607381.base,
                         call_607381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607381, url, valid)

proc call*(call_607382: Call_GetDescribeAlarms_607363; StateValue: string = "OK";
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
  var query_607383 = newJObject()
  add(query_607383, "StateValue", newJString(StateValue))
  add(query_607383, "ActionPrefix", newJString(ActionPrefix))
  add(query_607383, "NextToken", newJString(NextToken))
  add(query_607383, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  if AlarmNames != nil:
    query_607383.add "AlarmNames", AlarmNames
  add(query_607383, "Action", newJString(Action))
  add(query_607383, "Version", newJString(Version))
  add(query_607383, "MaxRecords", newJInt(MaxRecords))
  result = call_607382.call(nil, query_607383, nil, nil, nil)

var getDescribeAlarms* = Call_GetDescribeAlarms_607363(name: "getDescribeAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DescribeAlarms", validator: validate_GetDescribeAlarms_607364,
    base: "/", url: url_GetDescribeAlarms_607365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmsForMetric_607428 = ref object of OpenApiRestCall_606589
proc url_PostDescribeAlarmsForMetric_607430(protocol: Scheme; host: string;
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

proc validate_PostDescribeAlarmsForMetric_607429(path: JsonNode; query: JsonNode;
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
  var valid_607431 = query.getOrDefault("Action")
  valid_607431 = validateParameter(valid_607431, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_607431 != nil:
    section.add "Action", valid_607431
  var valid_607432 = query.getOrDefault("Version")
  valid_607432 = validateParameter(valid_607432, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607432 != nil:
    section.add "Version", valid_607432
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
  var valid_607433 = header.getOrDefault("X-Amz-Signature")
  valid_607433 = validateParameter(valid_607433, JString, required = false,
                                 default = nil)
  if valid_607433 != nil:
    section.add "X-Amz-Signature", valid_607433
  var valid_607434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607434 = validateParameter(valid_607434, JString, required = false,
                                 default = nil)
  if valid_607434 != nil:
    section.add "X-Amz-Content-Sha256", valid_607434
  var valid_607435 = header.getOrDefault("X-Amz-Date")
  valid_607435 = validateParameter(valid_607435, JString, required = false,
                                 default = nil)
  if valid_607435 != nil:
    section.add "X-Amz-Date", valid_607435
  var valid_607436 = header.getOrDefault("X-Amz-Credential")
  valid_607436 = validateParameter(valid_607436, JString, required = false,
                                 default = nil)
  if valid_607436 != nil:
    section.add "X-Amz-Credential", valid_607436
  var valid_607437 = header.getOrDefault("X-Amz-Security-Token")
  valid_607437 = validateParameter(valid_607437, JString, required = false,
                                 default = nil)
  if valid_607437 != nil:
    section.add "X-Amz-Security-Token", valid_607437
  var valid_607438 = header.getOrDefault("X-Amz-Algorithm")
  valid_607438 = validateParameter(valid_607438, JString, required = false,
                                 default = nil)
  if valid_607438 != nil:
    section.add "X-Amz-Algorithm", valid_607438
  var valid_607439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607439 = validateParameter(valid_607439, JString, required = false,
                                 default = nil)
  if valid_607439 != nil:
    section.add "X-Amz-SignedHeaders", valid_607439
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
  var valid_607440 = formData.getOrDefault("Unit")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_607440 != nil:
    section.add "Unit", valid_607440
  var valid_607441 = formData.getOrDefault("Period")
  valid_607441 = validateParameter(valid_607441, JInt, required = false, default = nil)
  if valid_607441 != nil:
    section.add "Period", valid_607441
  var valid_607442 = formData.getOrDefault("Statistic")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_607442 != nil:
    section.add "Statistic", valid_607442
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_607443 = formData.getOrDefault("MetricName")
  valid_607443 = validateParameter(valid_607443, JString, required = true,
                                 default = nil)
  if valid_607443 != nil:
    section.add "MetricName", valid_607443
  var valid_607444 = formData.getOrDefault("Dimensions")
  valid_607444 = validateParameter(valid_607444, JArray, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "Dimensions", valid_607444
  var valid_607445 = formData.getOrDefault("Namespace")
  valid_607445 = validateParameter(valid_607445, JString, required = true,
                                 default = nil)
  if valid_607445 != nil:
    section.add "Namespace", valid_607445
  var valid_607446 = formData.getOrDefault("ExtendedStatistic")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "ExtendedStatistic", valid_607446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607447: Call_PostDescribeAlarmsForMetric_607428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_607447.validator(path, query, header, formData, body)
  let scheme = call_607447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607447.url(scheme.get, call_607447.host, call_607447.base,
                         call_607447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607447, url, valid)

proc call*(call_607448: Call_PostDescribeAlarmsForMetric_607428;
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
  var query_607449 = newJObject()
  var formData_607450 = newJObject()
  add(formData_607450, "Unit", newJString(Unit))
  add(formData_607450, "Period", newJInt(Period))
  add(formData_607450, "Statistic", newJString(Statistic))
  add(formData_607450, "MetricName", newJString(MetricName))
  add(query_607449, "Action", newJString(Action))
  if Dimensions != nil:
    formData_607450.add "Dimensions", Dimensions
  add(formData_607450, "Namespace", newJString(Namespace))
  add(formData_607450, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_607449, "Version", newJString(Version))
  result = call_607448.call(nil, query_607449, nil, formData_607450, nil)

var postDescribeAlarmsForMetric* = Call_PostDescribeAlarmsForMetric_607428(
    name: "postDescribeAlarmsForMetric", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_PostDescribeAlarmsForMetric_607429, base: "/",
    url: url_PostDescribeAlarmsForMetric_607430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmsForMetric_607406 = ref object of OpenApiRestCall_606589
proc url_GetDescribeAlarmsForMetric_607408(protocol: Scheme; host: string;
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

proc validate_GetDescribeAlarmsForMetric_607407(path: JsonNode; query: JsonNode;
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
  var valid_607409 = query.getOrDefault("Statistic")
  valid_607409 = validateParameter(valid_607409, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_607409 != nil:
    section.add "Statistic", valid_607409
  var valid_607410 = query.getOrDefault("Unit")
  valid_607410 = validateParameter(valid_607410, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_607410 != nil:
    section.add "Unit", valid_607410
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_607411 = query.getOrDefault("Namespace")
  valid_607411 = validateParameter(valid_607411, JString, required = true,
                                 default = nil)
  if valid_607411 != nil:
    section.add "Namespace", valid_607411
  var valid_607412 = query.getOrDefault("ExtendedStatistic")
  valid_607412 = validateParameter(valid_607412, JString, required = false,
                                 default = nil)
  if valid_607412 != nil:
    section.add "ExtendedStatistic", valid_607412
  var valid_607413 = query.getOrDefault("Period")
  valid_607413 = validateParameter(valid_607413, JInt, required = false, default = nil)
  if valid_607413 != nil:
    section.add "Period", valid_607413
  var valid_607414 = query.getOrDefault("Dimensions")
  valid_607414 = validateParameter(valid_607414, JArray, required = false,
                                 default = nil)
  if valid_607414 != nil:
    section.add "Dimensions", valid_607414
  var valid_607415 = query.getOrDefault("Action")
  valid_607415 = validateParameter(valid_607415, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_607415 != nil:
    section.add "Action", valid_607415
  var valid_607416 = query.getOrDefault("Version")
  valid_607416 = validateParameter(valid_607416, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607416 != nil:
    section.add "Version", valid_607416
  var valid_607417 = query.getOrDefault("MetricName")
  valid_607417 = validateParameter(valid_607417, JString, required = true,
                                 default = nil)
  if valid_607417 != nil:
    section.add "MetricName", valid_607417
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
  var valid_607418 = header.getOrDefault("X-Amz-Signature")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "X-Amz-Signature", valid_607418
  var valid_607419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "X-Amz-Content-Sha256", valid_607419
  var valid_607420 = header.getOrDefault("X-Amz-Date")
  valid_607420 = validateParameter(valid_607420, JString, required = false,
                                 default = nil)
  if valid_607420 != nil:
    section.add "X-Amz-Date", valid_607420
  var valid_607421 = header.getOrDefault("X-Amz-Credential")
  valid_607421 = validateParameter(valid_607421, JString, required = false,
                                 default = nil)
  if valid_607421 != nil:
    section.add "X-Amz-Credential", valid_607421
  var valid_607422 = header.getOrDefault("X-Amz-Security-Token")
  valid_607422 = validateParameter(valid_607422, JString, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "X-Amz-Security-Token", valid_607422
  var valid_607423 = header.getOrDefault("X-Amz-Algorithm")
  valid_607423 = validateParameter(valid_607423, JString, required = false,
                                 default = nil)
  if valid_607423 != nil:
    section.add "X-Amz-Algorithm", valid_607423
  var valid_607424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607424 = validateParameter(valid_607424, JString, required = false,
                                 default = nil)
  if valid_607424 != nil:
    section.add "X-Amz-SignedHeaders", valid_607424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607425: Call_GetDescribeAlarmsForMetric_607406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_607425.validator(path, query, header, formData, body)
  let scheme = call_607425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607425.url(scheme.get, call_607425.host, call_607425.base,
                         call_607425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607425, url, valid)

proc call*(call_607426: Call_GetDescribeAlarmsForMetric_607406; Namespace: string;
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
  var query_607427 = newJObject()
  add(query_607427, "Statistic", newJString(Statistic))
  add(query_607427, "Unit", newJString(Unit))
  add(query_607427, "Namespace", newJString(Namespace))
  add(query_607427, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_607427, "Period", newJInt(Period))
  if Dimensions != nil:
    query_607427.add "Dimensions", Dimensions
  add(query_607427, "Action", newJString(Action))
  add(query_607427, "Version", newJString(Version))
  add(query_607427, "MetricName", newJString(MetricName))
  result = call_607426.call(nil, query_607427, nil, nil, nil)

var getDescribeAlarmsForMetric* = Call_GetDescribeAlarmsForMetric_607406(
    name: "getDescribeAlarmsForMetric", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_GetDescribeAlarmsForMetric_607407, base: "/",
    url: url_GetDescribeAlarmsForMetric_607408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnomalyDetectors_607471 = ref object of OpenApiRestCall_606589
proc url_PostDescribeAnomalyDetectors_607473(protocol: Scheme; host: string;
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

proc validate_PostDescribeAnomalyDetectors_607472(path: JsonNode; query: JsonNode;
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
  var valid_607474 = query.getOrDefault("Action")
  valid_607474 = validateParameter(valid_607474, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_607474 != nil:
    section.add "Action", valid_607474
  var valid_607475 = query.getOrDefault("Version")
  valid_607475 = validateParameter(valid_607475, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607475 != nil:
    section.add "Version", valid_607475
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
  var valid_607476 = header.getOrDefault("X-Amz-Signature")
  valid_607476 = validateParameter(valid_607476, JString, required = false,
                                 default = nil)
  if valid_607476 != nil:
    section.add "X-Amz-Signature", valid_607476
  var valid_607477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607477 = validateParameter(valid_607477, JString, required = false,
                                 default = nil)
  if valid_607477 != nil:
    section.add "X-Amz-Content-Sha256", valid_607477
  var valid_607478 = header.getOrDefault("X-Amz-Date")
  valid_607478 = validateParameter(valid_607478, JString, required = false,
                                 default = nil)
  if valid_607478 != nil:
    section.add "X-Amz-Date", valid_607478
  var valid_607479 = header.getOrDefault("X-Amz-Credential")
  valid_607479 = validateParameter(valid_607479, JString, required = false,
                                 default = nil)
  if valid_607479 != nil:
    section.add "X-Amz-Credential", valid_607479
  var valid_607480 = header.getOrDefault("X-Amz-Security-Token")
  valid_607480 = validateParameter(valid_607480, JString, required = false,
                                 default = nil)
  if valid_607480 != nil:
    section.add "X-Amz-Security-Token", valid_607480
  var valid_607481 = header.getOrDefault("X-Amz-Algorithm")
  valid_607481 = validateParameter(valid_607481, JString, required = false,
                                 default = nil)
  if valid_607481 != nil:
    section.add "X-Amz-Algorithm", valid_607481
  var valid_607482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607482 = validateParameter(valid_607482, JString, required = false,
                                 default = nil)
  if valid_607482 != nil:
    section.add "X-Amz-SignedHeaders", valid_607482
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
  var valid_607483 = formData.getOrDefault("NextToken")
  valid_607483 = validateParameter(valid_607483, JString, required = false,
                                 default = nil)
  if valid_607483 != nil:
    section.add "NextToken", valid_607483
  var valid_607484 = formData.getOrDefault("MetricName")
  valid_607484 = validateParameter(valid_607484, JString, required = false,
                                 default = nil)
  if valid_607484 != nil:
    section.add "MetricName", valid_607484
  var valid_607485 = formData.getOrDefault("Dimensions")
  valid_607485 = validateParameter(valid_607485, JArray, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "Dimensions", valid_607485
  var valid_607486 = formData.getOrDefault("Namespace")
  valid_607486 = validateParameter(valid_607486, JString, required = false,
                                 default = nil)
  if valid_607486 != nil:
    section.add "Namespace", valid_607486
  var valid_607487 = formData.getOrDefault("MaxResults")
  valid_607487 = validateParameter(valid_607487, JInt, required = false, default = nil)
  if valid_607487 != nil:
    section.add "MaxResults", valid_607487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607488: Call_PostDescribeAnomalyDetectors_607471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_607488.validator(path, query, header, formData, body)
  let scheme = call_607488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607488.url(scheme.get, call_607488.host, call_607488.base,
                         call_607488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607488, url, valid)

proc call*(call_607489: Call_PostDescribeAnomalyDetectors_607471;
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
  var query_607490 = newJObject()
  var formData_607491 = newJObject()
  add(formData_607491, "NextToken", newJString(NextToken))
  add(formData_607491, "MetricName", newJString(MetricName))
  add(query_607490, "Action", newJString(Action))
  if Dimensions != nil:
    formData_607491.add "Dimensions", Dimensions
  add(formData_607491, "Namespace", newJString(Namespace))
  add(query_607490, "Version", newJString(Version))
  add(formData_607491, "MaxResults", newJInt(MaxResults))
  result = call_607489.call(nil, query_607490, nil, formData_607491, nil)

var postDescribeAnomalyDetectors* = Call_PostDescribeAnomalyDetectors_607471(
    name: "postDescribeAnomalyDetectors", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_PostDescribeAnomalyDetectors_607472, base: "/",
    url: url_PostDescribeAnomalyDetectors_607473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnomalyDetectors_607451 = ref object of OpenApiRestCall_606589
proc url_GetDescribeAnomalyDetectors_607453(protocol: Scheme; host: string;
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

proc validate_GetDescribeAnomalyDetectors_607452(path: JsonNode; query: JsonNode;
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
  var valid_607454 = query.getOrDefault("MaxResults")
  valid_607454 = validateParameter(valid_607454, JInt, required = false, default = nil)
  if valid_607454 != nil:
    section.add "MaxResults", valid_607454
  var valid_607455 = query.getOrDefault("NextToken")
  valid_607455 = validateParameter(valid_607455, JString, required = false,
                                 default = nil)
  if valid_607455 != nil:
    section.add "NextToken", valid_607455
  var valid_607456 = query.getOrDefault("Namespace")
  valid_607456 = validateParameter(valid_607456, JString, required = false,
                                 default = nil)
  if valid_607456 != nil:
    section.add "Namespace", valid_607456
  var valid_607457 = query.getOrDefault("Dimensions")
  valid_607457 = validateParameter(valid_607457, JArray, required = false,
                                 default = nil)
  if valid_607457 != nil:
    section.add "Dimensions", valid_607457
  var valid_607458 = query.getOrDefault("Action")
  valid_607458 = validateParameter(valid_607458, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_607458 != nil:
    section.add "Action", valid_607458
  var valid_607459 = query.getOrDefault("Version")
  valid_607459 = validateParameter(valid_607459, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607459 != nil:
    section.add "Version", valid_607459
  var valid_607460 = query.getOrDefault("MetricName")
  valid_607460 = validateParameter(valid_607460, JString, required = false,
                                 default = nil)
  if valid_607460 != nil:
    section.add "MetricName", valid_607460
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
  var valid_607461 = header.getOrDefault("X-Amz-Signature")
  valid_607461 = validateParameter(valid_607461, JString, required = false,
                                 default = nil)
  if valid_607461 != nil:
    section.add "X-Amz-Signature", valid_607461
  var valid_607462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607462 = validateParameter(valid_607462, JString, required = false,
                                 default = nil)
  if valid_607462 != nil:
    section.add "X-Amz-Content-Sha256", valid_607462
  var valid_607463 = header.getOrDefault("X-Amz-Date")
  valid_607463 = validateParameter(valid_607463, JString, required = false,
                                 default = nil)
  if valid_607463 != nil:
    section.add "X-Amz-Date", valid_607463
  var valid_607464 = header.getOrDefault("X-Amz-Credential")
  valid_607464 = validateParameter(valid_607464, JString, required = false,
                                 default = nil)
  if valid_607464 != nil:
    section.add "X-Amz-Credential", valid_607464
  var valid_607465 = header.getOrDefault("X-Amz-Security-Token")
  valid_607465 = validateParameter(valid_607465, JString, required = false,
                                 default = nil)
  if valid_607465 != nil:
    section.add "X-Amz-Security-Token", valid_607465
  var valid_607466 = header.getOrDefault("X-Amz-Algorithm")
  valid_607466 = validateParameter(valid_607466, JString, required = false,
                                 default = nil)
  if valid_607466 != nil:
    section.add "X-Amz-Algorithm", valid_607466
  var valid_607467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607467 = validateParameter(valid_607467, JString, required = false,
                                 default = nil)
  if valid_607467 != nil:
    section.add "X-Amz-SignedHeaders", valid_607467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607468: Call_GetDescribeAnomalyDetectors_607451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_607468.validator(path, query, header, formData, body)
  let scheme = call_607468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607468.url(scheme.get, call_607468.host, call_607468.base,
                         call_607468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607468, url, valid)

proc call*(call_607469: Call_GetDescribeAnomalyDetectors_607451;
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
  var query_607470 = newJObject()
  add(query_607470, "MaxResults", newJInt(MaxResults))
  add(query_607470, "NextToken", newJString(NextToken))
  add(query_607470, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_607470.add "Dimensions", Dimensions
  add(query_607470, "Action", newJString(Action))
  add(query_607470, "Version", newJString(Version))
  add(query_607470, "MetricName", newJString(MetricName))
  result = call_607469.call(nil, query_607470, nil, nil, nil)

var getDescribeAnomalyDetectors* = Call_GetDescribeAnomalyDetectors_607451(
    name: "getDescribeAnomalyDetectors", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_GetDescribeAnomalyDetectors_607452, base: "/",
    url: url_GetDescribeAnomalyDetectors_607453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInsightRules_607509 = ref object of OpenApiRestCall_606589
proc url_PostDescribeInsightRules_607511(protocol: Scheme; host: string;
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

proc validate_PostDescribeInsightRules_607510(path: JsonNode; query: JsonNode;
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
  var valid_607512 = query.getOrDefault("Action")
  valid_607512 = validateParameter(valid_607512, JString, required = true,
                                 default = newJString("DescribeInsightRules"))
  if valid_607512 != nil:
    section.add "Action", valid_607512
  var valid_607513 = query.getOrDefault("Version")
  valid_607513 = validateParameter(valid_607513, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607513 != nil:
    section.add "Version", valid_607513
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
  var valid_607514 = header.getOrDefault("X-Amz-Signature")
  valid_607514 = validateParameter(valid_607514, JString, required = false,
                                 default = nil)
  if valid_607514 != nil:
    section.add "X-Amz-Signature", valid_607514
  var valid_607515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Content-Sha256", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-Date")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-Date", valid_607516
  var valid_607517 = header.getOrDefault("X-Amz-Credential")
  valid_607517 = validateParameter(valid_607517, JString, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "X-Amz-Credential", valid_607517
  var valid_607518 = header.getOrDefault("X-Amz-Security-Token")
  valid_607518 = validateParameter(valid_607518, JString, required = false,
                                 default = nil)
  if valid_607518 != nil:
    section.add "X-Amz-Security-Token", valid_607518
  var valid_607519 = header.getOrDefault("X-Amz-Algorithm")
  valid_607519 = validateParameter(valid_607519, JString, required = false,
                                 default = nil)
  if valid_607519 != nil:
    section.add "X-Amz-Algorithm", valid_607519
  var valid_607520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607520 = validateParameter(valid_607520, JString, required = false,
                                 default = nil)
  if valid_607520 != nil:
    section.add "X-Amz-SignedHeaders", valid_607520
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Reserved for future use.
  ##   MaxResults: JInt
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  section = newJObject()
  var valid_607521 = formData.getOrDefault("NextToken")
  valid_607521 = validateParameter(valid_607521, JString, required = false,
                                 default = nil)
  if valid_607521 != nil:
    section.add "NextToken", valid_607521
  var valid_607522 = formData.getOrDefault("MaxResults")
  valid_607522 = validateParameter(valid_607522, JInt, required = false, default = nil)
  if valid_607522 != nil:
    section.add "MaxResults", valid_607522
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607523: Call_PostDescribeInsightRules_607509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_607523.validator(path, query, header, formData, body)
  let scheme = call_607523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607523.url(scheme.get, call_607523.host, call_607523.base,
                         call_607523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607523, url, valid)

proc call*(call_607524: Call_PostDescribeInsightRules_607509;
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
  var query_607525 = newJObject()
  var formData_607526 = newJObject()
  add(formData_607526, "NextToken", newJString(NextToken))
  add(query_607525, "Action", newJString(Action))
  add(query_607525, "Version", newJString(Version))
  add(formData_607526, "MaxResults", newJInt(MaxResults))
  result = call_607524.call(nil, query_607525, nil, formData_607526, nil)

var postDescribeInsightRules* = Call_PostDescribeInsightRules_607509(
    name: "postDescribeInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_PostDescribeInsightRules_607510, base: "/",
    url: url_PostDescribeInsightRules_607511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInsightRules_607492 = ref object of OpenApiRestCall_606589
proc url_GetDescribeInsightRules_607494(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeInsightRules_607493(path: JsonNode; query: JsonNode;
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
  var valid_607495 = query.getOrDefault("MaxResults")
  valid_607495 = validateParameter(valid_607495, JInt, required = false, default = nil)
  if valid_607495 != nil:
    section.add "MaxResults", valid_607495
  var valid_607496 = query.getOrDefault("NextToken")
  valid_607496 = validateParameter(valid_607496, JString, required = false,
                                 default = nil)
  if valid_607496 != nil:
    section.add "NextToken", valid_607496
  var valid_607497 = query.getOrDefault("Action")
  valid_607497 = validateParameter(valid_607497, JString, required = true,
                                 default = newJString("DescribeInsightRules"))
  if valid_607497 != nil:
    section.add "Action", valid_607497
  var valid_607498 = query.getOrDefault("Version")
  valid_607498 = validateParameter(valid_607498, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607498 != nil:
    section.add "Version", valid_607498
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
  var valid_607499 = header.getOrDefault("X-Amz-Signature")
  valid_607499 = validateParameter(valid_607499, JString, required = false,
                                 default = nil)
  if valid_607499 != nil:
    section.add "X-Amz-Signature", valid_607499
  var valid_607500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607500 = validateParameter(valid_607500, JString, required = false,
                                 default = nil)
  if valid_607500 != nil:
    section.add "X-Amz-Content-Sha256", valid_607500
  var valid_607501 = header.getOrDefault("X-Amz-Date")
  valid_607501 = validateParameter(valid_607501, JString, required = false,
                                 default = nil)
  if valid_607501 != nil:
    section.add "X-Amz-Date", valid_607501
  var valid_607502 = header.getOrDefault("X-Amz-Credential")
  valid_607502 = validateParameter(valid_607502, JString, required = false,
                                 default = nil)
  if valid_607502 != nil:
    section.add "X-Amz-Credential", valid_607502
  var valid_607503 = header.getOrDefault("X-Amz-Security-Token")
  valid_607503 = validateParameter(valid_607503, JString, required = false,
                                 default = nil)
  if valid_607503 != nil:
    section.add "X-Amz-Security-Token", valid_607503
  var valid_607504 = header.getOrDefault("X-Amz-Algorithm")
  valid_607504 = validateParameter(valid_607504, JString, required = false,
                                 default = nil)
  if valid_607504 != nil:
    section.add "X-Amz-Algorithm", valid_607504
  var valid_607505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "X-Amz-SignedHeaders", valid_607505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607506: Call_GetDescribeInsightRules_607492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_607506.validator(path, query, header, formData, body)
  let scheme = call_607506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607506.url(scheme.get, call_607506.host, call_607506.base,
                         call_607506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607506, url, valid)

proc call*(call_607507: Call_GetDescribeInsightRules_607492; MaxResults: int = 0;
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
  var query_607508 = newJObject()
  add(query_607508, "MaxResults", newJInt(MaxResults))
  add(query_607508, "NextToken", newJString(NextToken))
  add(query_607508, "Action", newJString(Action))
  add(query_607508, "Version", newJString(Version))
  result = call_607507.call(nil, query_607508, nil, nil, nil)

var getDescribeInsightRules* = Call_GetDescribeInsightRules_607492(
    name: "getDescribeInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_GetDescribeInsightRules_607493, base: "/",
    url: url_GetDescribeInsightRules_607494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAlarmActions_607543 = ref object of OpenApiRestCall_606589
proc url_PostDisableAlarmActions_607545(protocol: Scheme; host: string; base: string;
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

proc validate_PostDisableAlarmActions_607544(path: JsonNode; query: JsonNode;
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
  var valid_607546 = query.getOrDefault("Action")
  valid_607546 = validateParameter(valid_607546, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_607546 != nil:
    section.add "Action", valid_607546
  var valid_607547 = query.getOrDefault("Version")
  valid_607547 = validateParameter(valid_607547, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607547 != nil:
    section.add "Version", valid_607547
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
  var valid_607548 = header.getOrDefault("X-Amz-Signature")
  valid_607548 = validateParameter(valid_607548, JString, required = false,
                                 default = nil)
  if valid_607548 != nil:
    section.add "X-Amz-Signature", valid_607548
  var valid_607549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "X-Amz-Content-Sha256", valid_607549
  var valid_607550 = header.getOrDefault("X-Amz-Date")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "X-Amz-Date", valid_607550
  var valid_607551 = header.getOrDefault("X-Amz-Credential")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "X-Amz-Credential", valid_607551
  var valid_607552 = header.getOrDefault("X-Amz-Security-Token")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "X-Amz-Security-Token", valid_607552
  var valid_607553 = header.getOrDefault("X-Amz-Algorithm")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-Algorithm", valid_607553
  var valid_607554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607554 = validateParameter(valid_607554, JString, required = false,
                                 default = nil)
  if valid_607554 != nil:
    section.add "X-Amz-SignedHeaders", valid_607554
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_607555 = formData.getOrDefault("AlarmNames")
  valid_607555 = validateParameter(valid_607555, JArray, required = true, default = nil)
  if valid_607555 != nil:
    section.add "AlarmNames", valid_607555
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607556: Call_PostDisableAlarmActions_607543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_607556.validator(path, query, header, formData, body)
  let scheme = call_607556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607556.url(scheme.get, call_607556.host, call_607556.base,
                         call_607556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607556, url, valid)

proc call*(call_607557: Call_PostDisableAlarmActions_607543; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_607558 = newJObject()
  var formData_607559 = newJObject()
  add(query_607558, "Action", newJString(Action))
  add(query_607558, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_607559.add "AlarmNames", AlarmNames
  result = call_607557.call(nil, query_607558, nil, formData_607559, nil)

var postDisableAlarmActions* = Call_PostDisableAlarmActions_607543(
    name: "postDisableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_PostDisableAlarmActions_607544, base: "/",
    url: url_PostDisableAlarmActions_607545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAlarmActions_607527 = ref object of OpenApiRestCall_606589
proc url_GetDisableAlarmActions_607529(protocol: Scheme; host: string; base: string;
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

proc validate_GetDisableAlarmActions_607528(path: JsonNode; query: JsonNode;
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
  var valid_607530 = query.getOrDefault("AlarmNames")
  valid_607530 = validateParameter(valid_607530, JArray, required = true, default = nil)
  if valid_607530 != nil:
    section.add "AlarmNames", valid_607530
  var valid_607531 = query.getOrDefault("Action")
  valid_607531 = validateParameter(valid_607531, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_607531 != nil:
    section.add "Action", valid_607531
  var valid_607532 = query.getOrDefault("Version")
  valid_607532 = validateParameter(valid_607532, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607532 != nil:
    section.add "Version", valid_607532
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
  var valid_607533 = header.getOrDefault("X-Amz-Signature")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "X-Amz-Signature", valid_607533
  var valid_607534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "X-Amz-Content-Sha256", valid_607534
  var valid_607535 = header.getOrDefault("X-Amz-Date")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "X-Amz-Date", valid_607535
  var valid_607536 = header.getOrDefault("X-Amz-Credential")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "X-Amz-Credential", valid_607536
  var valid_607537 = header.getOrDefault("X-Amz-Security-Token")
  valid_607537 = validateParameter(valid_607537, JString, required = false,
                                 default = nil)
  if valid_607537 != nil:
    section.add "X-Amz-Security-Token", valid_607537
  var valid_607538 = header.getOrDefault("X-Amz-Algorithm")
  valid_607538 = validateParameter(valid_607538, JString, required = false,
                                 default = nil)
  if valid_607538 != nil:
    section.add "X-Amz-Algorithm", valid_607538
  var valid_607539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607539 = validateParameter(valid_607539, JString, required = false,
                                 default = nil)
  if valid_607539 != nil:
    section.add "X-Amz-SignedHeaders", valid_607539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607540: Call_GetDisableAlarmActions_607527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_607540.validator(path, query, header, formData, body)
  let scheme = call_607540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607540.url(scheme.get, call_607540.host, call_607540.base,
                         call_607540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607540, url, valid)

proc call*(call_607541: Call_GetDisableAlarmActions_607527; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607542 = newJObject()
  if AlarmNames != nil:
    query_607542.add "AlarmNames", AlarmNames
  add(query_607542, "Action", newJString(Action))
  add(query_607542, "Version", newJString(Version))
  result = call_607541.call(nil, query_607542, nil, nil, nil)

var getDisableAlarmActions* = Call_GetDisableAlarmActions_607527(
    name: "getDisableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_GetDisableAlarmActions_607528, base: "/",
    url: url_GetDisableAlarmActions_607529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableInsightRules_607576 = ref object of OpenApiRestCall_606589
proc url_PostDisableInsightRules_607578(protocol: Scheme; host: string; base: string;
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

proc validate_PostDisableInsightRules_607577(path: JsonNode; query: JsonNode;
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
  var valid_607579 = query.getOrDefault("Action")
  valid_607579 = validateParameter(valid_607579, JString, required = true,
                                 default = newJString("DisableInsightRules"))
  if valid_607579 != nil:
    section.add "Action", valid_607579
  var valid_607580 = query.getOrDefault("Version")
  valid_607580 = validateParameter(valid_607580, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607580 != nil:
    section.add "Version", valid_607580
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
  var valid_607581 = header.getOrDefault("X-Amz-Signature")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "X-Amz-Signature", valid_607581
  var valid_607582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607582 = validateParameter(valid_607582, JString, required = false,
                                 default = nil)
  if valid_607582 != nil:
    section.add "X-Amz-Content-Sha256", valid_607582
  var valid_607583 = header.getOrDefault("X-Amz-Date")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "X-Amz-Date", valid_607583
  var valid_607584 = header.getOrDefault("X-Amz-Credential")
  valid_607584 = validateParameter(valid_607584, JString, required = false,
                                 default = nil)
  if valid_607584 != nil:
    section.add "X-Amz-Credential", valid_607584
  var valid_607585 = header.getOrDefault("X-Amz-Security-Token")
  valid_607585 = validateParameter(valid_607585, JString, required = false,
                                 default = nil)
  if valid_607585 != nil:
    section.add "X-Amz-Security-Token", valid_607585
  var valid_607586 = header.getOrDefault("X-Amz-Algorithm")
  valid_607586 = validateParameter(valid_607586, JString, required = false,
                                 default = nil)
  if valid_607586 != nil:
    section.add "X-Amz-Algorithm", valid_607586
  var valid_607587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607587 = validateParameter(valid_607587, JString, required = false,
                                 default = nil)
  if valid_607587 != nil:
    section.add "X-Amz-SignedHeaders", valid_607587
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_607588 = formData.getOrDefault("RuleNames")
  valid_607588 = validateParameter(valid_607588, JArray, required = true, default = nil)
  if valid_607588 != nil:
    section.add "RuleNames", valid_607588
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607589: Call_PostDisableInsightRules_607576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_607589.validator(path, query, header, formData, body)
  let scheme = call_607589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607589.url(scheme.get, call_607589.host, call_607589.base,
                         call_607589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607589, url, valid)

proc call*(call_607590: Call_PostDisableInsightRules_607576; RuleNames: JsonNode;
          Action: string = "DisableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607591 = newJObject()
  var formData_607592 = newJObject()
  if RuleNames != nil:
    formData_607592.add "RuleNames", RuleNames
  add(query_607591, "Action", newJString(Action))
  add(query_607591, "Version", newJString(Version))
  result = call_607590.call(nil, query_607591, nil, formData_607592, nil)

var postDisableInsightRules* = Call_PostDisableInsightRules_607576(
    name: "postDisableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_PostDisableInsightRules_607577, base: "/",
    url: url_PostDisableInsightRules_607578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableInsightRules_607560 = ref object of OpenApiRestCall_606589
proc url_GetDisableInsightRules_607562(protocol: Scheme; host: string; base: string;
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

proc validate_GetDisableInsightRules_607561(path: JsonNode; query: JsonNode;
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
  var valid_607563 = query.getOrDefault("Action")
  valid_607563 = validateParameter(valid_607563, JString, required = true,
                                 default = newJString("DisableInsightRules"))
  if valid_607563 != nil:
    section.add "Action", valid_607563
  var valid_607564 = query.getOrDefault("RuleNames")
  valid_607564 = validateParameter(valid_607564, JArray, required = true, default = nil)
  if valid_607564 != nil:
    section.add "RuleNames", valid_607564
  var valid_607565 = query.getOrDefault("Version")
  valid_607565 = validateParameter(valid_607565, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607565 != nil:
    section.add "Version", valid_607565
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
  var valid_607566 = header.getOrDefault("X-Amz-Signature")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-Signature", valid_607566
  var valid_607567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607567 = validateParameter(valid_607567, JString, required = false,
                                 default = nil)
  if valid_607567 != nil:
    section.add "X-Amz-Content-Sha256", valid_607567
  var valid_607568 = header.getOrDefault("X-Amz-Date")
  valid_607568 = validateParameter(valid_607568, JString, required = false,
                                 default = nil)
  if valid_607568 != nil:
    section.add "X-Amz-Date", valid_607568
  var valid_607569 = header.getOrDefault("X-Amz-Credential")
  valid_607569 = validateParameter(valid_607569, JString, required = false,
                                 default = nil)
  if valid_607569 != nil:
    section.add "X-Amz-Credential", valid_607569
  var valid_607570 = header.getOrDefault("X-Amz-Security-Token")
  valid_607570 = validateParameter(valid_607570, JString, required = false,
                                 default = nil)
  if valid_607570 != nil:
    section.add "X-Amz-Security-Token", valid_607570
  var valid_607571 = header.getOrDefault("X-Amz-Algorithm")
  valid_607571 = validateParameter(valid_607571, JString, required = false,
                                 default = nil)
  if valid_607571 != nil:
    section.add "X-Amz-Algorithm", valid_607571
  var valid_607572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607572 = validateParameter(valid_607572, JString, required = false,
                                 default = nil)
  if valid_607572 != nil:
    section.add "X-Amz-SignedHeaders", valid_607572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607573: Call_GetDisableInsightRules_607560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_607573.validator(path, query, header, formData, body)
  let scheme = call_607573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607573.url(scheme.get, call_607573.host, call_607573.base,
                         call_607573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607573, url, valid)

proc call*(call_607574: Call_GetDisableInsightRules_607560; RuleNames: JsonNode;
          Action: string = "DisableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_607575 = newJObject()
  add(query_607575, "Action", newJString(Action))
  if RuleNames != nil:
    query_607575.add "RuleNames", RuleNames
  add(query_607575, "Version", newJString(Version))
  result = call_607574.call(nil, query_607575, nil, nil, nil)

var getDisableInsightRules* = Call_GetDisableInsightRules_607560(
    name: "getDisableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_GetDisableInsightRules_607561, base: "/",
    url: url_GetDisableInsightRules_607562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAlarmActions_607609 = ref object of OpenApiRestCall_606589
proc url_PostEnableAlarmActions_607611(protocol: Scheme; host: string; base: string;
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

proc validate_PostEnableAlarmActions_607610(path: JsonNode; query: JsonNode;
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
  var valid_607612 = query.getOrDefault("Action")
  valid_607612 = validateParameter(valid_607612, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_607612 != nil:
    section.add "Action", valid_607612
  var valid_607613 = query.getOrDefault("Version")
  valid_607613 = validateParameter(valid_607613, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607613 != nil:
    section.add "Version", valid_607613
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
  var valid_607614 = header.getOrDefault("X-Amz-Signature")
  valid_607614 = validateParameter(valid_607614, JString, required = false,
                                 default = nil)
  if valid_607614 != nil:
    section.add "X-Amz-Signature", valid_607614
  var valid_607615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607615 = validateParameter(valid_607615, JString, required = false,
                                 default = nil)
  if valid_607615 != nil:
    section.add "X-Amz-Content-Sha256", valid_607615
  var valid_607616 = header.getOrDefault("X-Amz-Date")
  valid_607616 = validateParameter(valid_607616, JString, required = false,
                                 default = nil)
  if valid_607616 != nil:
    section.add "X-Amz-Date", valid_607616
  var valid_607617 = header.getOrDefault("X-Amz-Credential")
  valid_607617 = validateParameter(valid_607617, JString, required = false,
                                 default = nil)
  if valid_607617 != nil:
    section.add "X-Amz-Credential", valid_607617
  var valid_607618 = header.getOrDefault("X-Amz-Security-Token")
  valid_607618 = validateParameter(valid_607618, JString, required = false,
                                 default = nil)
  if valid_607618 != nil:
    section.add "X-Amz-Security-Token", valid_607618
  var valid_607619 = header.getOrDefault("X-Amz-Algorithm")
  valid_607619 = validateParameter(valid_607619, JString, required = false,
                                 default = nil)
  if valid_607619 != nil:
    section.add "X-Amz-Algorithm", valid_607619
  var valid_607620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607620 = validateParameter(valid_607620, JString, required = false,
                                 default = nil)
  if valid_607620 != nil:
    section.add "X-Amz-SignedHeaders", valid_607620
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_607621 = formData.getOrDefault("AlarmNames")
  valid_607621 = validateParameter(valid_607621, JArray, required = true, default = nil)
  if valid_607621 != nil:
    section.add "AlarmNames", valid_607621
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607622: Call_PostEnableAlarmActions_607609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_607622.validator(path, query, header, formData, body)
  let scheme = call_607622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607622.url(scheme.get, call_607622.host, call_607622.base,
                         call_607622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607622, url, valid)

proc call*(call_607623: Call_PostEnableAlarmActions_607609; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_607624 = newJObject()
  var formData_607625 = newJObject()
  add(query_607624, "Action", newJString(Action))
  add(query_607624, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_607625.add "AlarmNames", AlarmNames
  result = call_607623.call(nil, query_607624, nil, formData_607625, nil)

var postEnableAlarmActions* = Call_PostEnableAlarmActions_607609(
    name: "postEnableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_PostEnableAlarmActions_607610, base: "/",
    url: url_PostEnableAlarmActions_607611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAlarmActions_607593 = ref object of OpenApiRestCall_606589
proc url_GetEnableAlarmActions_607595(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnableAlarmActions_607594(path: JsonNode; query: JsonNode;
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
  var valid_607596 = query.getOrDefault("AlarmNames")
  valid_607596 = validateParameter(valid_607596, JArray, required = true, default = nil)
  if valid_607596 != nil:
    section.add "AlarmNames", valid_607596
  var valid_607597 = query.getOrDefault("Action")
  valid_607597 = validateParameter(valid_607597, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_607597 != nil:
    section.add "Action", valid_607597
  var valid_607598 = query.getOrDefault("Version")
  valid_607598 = validateParameter(valid_607598, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607598 != nil:
    section.add "Version", valid_607598
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
  var valid_607599 = header.getOrDefault("X-Amz-Signature")
  valid_607599 = validateParameter(valid_607599, JString, required = false,
                                 default = nil)
  if valid_607599 != nil:
    section.add "X-Amz-Signature", valid_607599
  var valid_607600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607600 = validateParameter(valid_607600, JString, required = false,
                                 default = nil)
  if valid_607600 != nil:
    section.add "X-Amz-Content-Sha256", valid_607600
  var valid_607601 = header.getOrDefault("X-Amz-Date")
  valid_607601 = validateParameter(valid_607601, JString, required = false,
                                 default = nil)
  if valid_607601 != nil:
    section.add "X-Amz-Date", valid_607601
  var valid_607602 = header.getOrDefault("X-Amz-Credential")
  valid_607602 = validateParameter(valid_607602, JString, required = false,
                                 default = nil)
  if valid_607602 != nil:
    section.add "X-Amz-Credential", valid_607602
  var valid_607603 = header.getOrDefault("X-Amz-Security-Token")
  valid_607603 = validateParameter(valid_607603, JString, required = false,
                                 default = nil)
  if valid_607603 != nil:
    section.add "X-Amz-Security-Token", valid_607603
  var valid_607604 = header.getOrDefault("X-Amz-Algorithm")
  valid_607604 = validateParameter(valid_607604, JString, required = false,
                                 default = nil)
  if valid_607604 != nil:
    section.add "X-Amz-Algorithm", valid_607604
  var valid_607605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "X-Amz-SignedHeaders", valid_607605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607606: Call_GetEnableAlarmActions_607593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_607606.validator(path, query, header, formData, body)
  let scheme = call_607606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607606.url(scheme.get, call_607606.host, call_607606.base,
                         call_607606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607606, url, valid)

proc call*(call_607607: Call_GetEnableAlarmActions_607593; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607608 = newJObject()
  if AlarmNames != nil:
    query_607608.add "AlarmNames", AlarmNames
  add(query_607608, "Action", newJString(Action))
  add(query_607608, "Version", newJString(Version))
  result = call_607607.call(nil, query_607608, nil, nil, nil)

var getEnableAlarmActions* = Call_GetEnableAlarmActions_607593(
    name: "getEnableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_GetEnableAlarmActions_607594, base: "/",
    url: url_GetEnableAlarmActions_607595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableInsightRules_607642 = ref object of OpenApiRestCall_606589
proc url_PostEnableInsightRules_607644(protocol: Scheme; host: string; base: string;
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

proc validate_PostEnableInsightRules_607643(path: JsonNode; query: JsonNode;
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
  var valid_607645 = query.getOrDefault("Action")
  valid_607645 = validateParameter(valid_607645, JString, required = true,
                                 default = newJString("EnableInsightRules"))
  if valid_607645 != nil:
    section.add "Action", valid_607645
  var valid_607646 = query.getOrDefault("Version")
  valid_607646 = validateParameter(valid_607646, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607646 != nil:
    section.add "Version", valid_607646
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
  var valid_607647 = header.getOrDefault("X-Amz-Signature")
  valid_607647 = validateParameter(valid_607647, JString, required = false,
                                 default = nil)
  if valid_607647 != nil:
    section.add "X-Amz-Signature", valid_607647
  var valid_607648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607648 = validateParameter(valid_607648, JString, required = false,
                                 default = nil)
  if valid_607648 != nil:
    section.add "X-Amz-Content-Sha256", valid_607648
  var valid_607649 = header.getOrDefault("X-Amz-Date")
  valid_607649 = validateParameter(valid_607649, JString, required = false,
                                 default = nil)
  if valid_607649 != nil:
    section.add "X-Amz-Date", valid_607649
  var valid_607650 = header.getOrDefault("X-Amz-Credential")
  valid_607650 = validateParameter(valid_607650, JString, required = false,
                                 default = nil)
  if valid_607650 != nil:
    section.add "X-Amz-Credential", valid_607650
  var valid_607651 = header.getOrDefault("X-Amz-Security-Token")
  valid_607651 = validateParameter(valid_607651, JString, required = false,
                                 default = nil)
  if valid_607651 != nil:
    section.add "X-Amz-Security-Token", valid_607651
  var valid_607652 = header.getOrDefault("X-Amz-Algorithm")
  valid_607652 = validateParameter(valid_607652, JString, required = false,
                                 default = nil)
  if valid_607652 != nil:
    section.add "X-Amz-Algorithm", valid_607652
  var valid_607653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607653 = validateParameter(valid_607653, JString, required = false,
                                 default = nil)
  if valid_607653 != nil:
    section.add "X-Amz-SignedHeaders", valid_607653
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_607654 = formData.getOrDefault("RuleNames")
  valid_607654 = validateParameter(valid_607654, JArray, required = true, default = nil)
  if valid_607654 != nil:
    section.add "RuleNames", valid_607654
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607655: Call_PostEnableInsightRules_607642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_607655.validator(path, query, header, formData, body)
  let scheme = call_607655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607655.url(scheme.get, call_607655.host, call_607655.base,
                         call_607655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607655, url, valid)

proc call*(call_607656: Call_PostEnableInsightRules_607642; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607657 = newJObject()
  var formData_607658 = newJObject()
  if RuleNames != nil:
    formData_607658.add "RuleNames", RuleNames
  add(query_607657, "Action", newJString(Action))
  add(query_607657, "Version", newJString(Version))
  result = call_607656.call(nil, query_607657, nil, formData_607658, nil)

var postEnableInsightRules* = Call_PostEnableInsightRules_607642(
    name: "postEnableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_PostEnableInsightRules_607643, base: "/",
    url: url_PostEnableInsightRules_607644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableInsightRules_607626 = ref object of OpenApiRestCall_606589
proc url_GetEnableInsightRules_607628(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnableInsightRules_607627(path: JsonNode; query: JsonNode;
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
  var valid_607629 = query.getOrDefault("Action")
  valid_607629 = validateParameter(valid_607629, JString, required = true,
                                 default = newJString("EnableInsightRules"))
  if valid_607629 != nil:
    section.add "Action", valid_607629
  var valid_607630 = query.getOrDefault("RuleNames")
  valid_607630 = validateParameter(valid_607630, JArray, required = true, default = nil)
  if valid_607630 != nil:
    section.add "RuleNames", valid_607630
  var valid_607631 = query.getOrDefault("Version")
  valid_607631 = validateParameter(valid_607631, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607631 != nil:
    section.add "Version", valid_607631
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
  var valid_607632 = header.getOrDefault("X-Amz-Signature")
  valid_607632 = validateParameter(valid_607632, JString, required = false,
                                 default = nil)
  if valid_607632 != nil:
    section.add "X-Amz-Signature", valid_607632
  var valid_607633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607633 = validateParameter(valid_607633, JString, required = false,
                                 default = nil)
  if valid_607633 != nil:
    section.add "X-Amz-Content-Sha256", valid_607633
  var valid_607634 = header.getOrDefault("X-Amz-Date")
  valid_607634 = validateParameter(valid_607634, JString, required = false,
                                 default = nil)
  if valid_607634 != nil:
    section.add "X-Amz-Date", valid_607634
  var valid_607635 = header.getOrDefault("X-Amz-Credential")
  valid_607635 = validateParameter(valid_607635, JString, required = false,
                                 default = nil)
  if valid_607635 != nil:
    section.add "X-Amz-Credential", valid_607635
  var valid_607636 = header.getOrDefault("X-Amz-Security-Token")
  valid_607636 = validateParameter(valid_607636, JString, required = false,
                                 default = nil)
  if valid_607636 != nil:
    section.add "X-Amz-Security-Token", valid_607636
  var valid_607637 = header.getOrDefault("X-Amz-Algorithm")
  valid_607637 = validateParameter(valid_607637, JString, required = false,
                                 default = nil)
  if valid_607637 != nil:
    section.add "X-Amz-Algorithm", valid_607637
  var valid_607638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "X-Amz-SignedHeaders", valid_607638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607639: Call_GetEnableInsightRules_607626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_607639.validator(path, query, header, formData, body)
  let scheme = call_607639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607639.url(scheme.get, call_607639.host, call_607639.base,
                         call_607639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607639, url, valid)

proc call*(call_607640: Call_GetEnableInsightRules_607626; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_607641 = newJObject()
  add(query_607641, "Action", newJString(Action))
  if RuleNames != nil:
    query_607641.add "RuleNames", RuleNames
  add(query_607641, "Version", newJString(Version))
  result = call_607640.call(nil, query_607641, nil, nil, nil)

var getEnableInsightRules* = Call_GetEnableInsightRules_607626(
    name: "getEnableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_GetEnableInsightRules_607627, base: "/",
    url: url_GetEnableInsightRules_607628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetDashboard_607675 = ref object of OpenApiRestCall_606589
proc url_PostGetDashboard_607677(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetDashboard_607676(path: JsonNode; query: JsonNode;
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
  var valid_607678 = query.getOrDefault("Action")
  valid_607678 = validateParameter(valid_607678, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_607678 != nil:
    section.add "Action", valid_607678
  var valid_607679 = query.getOrDefault("Version")
  valid_607679 = validateParameter(valid_607679, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607679 != nil:
    section.add "Version", valid_607679
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
  var valid_607680 = header.getOrDefault("X-Amz-Signature")
  valid_607680 = validateParameter(valid_607680, JString, required = false,
                                 default = nil)
  if valid_607680 != nil:
    section.add "X-Amz-Signature", valid_607680
  var valid_607681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607681 = validateParameter(valid_607681, JString, required = false,
                                 default = nil)
  if valid_607681 != nil:
    section.add "X-Amz-Content-Sha256", valid_607681
  var valid_607682 = header.getOrDefault("X-Amz-Date")
  valid_607682 = validateParameter(valid_607682, JString, required = false,
                                 default = nil)
  if valid_607682 != nil:
    section.add "X-Amz-Date", valid_607682
  var valid_607683 = header.getOrDefault("X-Amz-Credential")
  valid_607683 = validateParameter(valid_607683, JString, required = false,
                                 default = nil)
  if valid_607683 != nil:
    section.add "X-Amz-Credential", valid_607683
  var valid_607684 = header.getOrDefault("X-Amz-Security-Token")
  valid_607684 = validateParameter(valid_607684, JString, required = false,
                                 default = nil)
  if valid_607684 != nil:
    section.add "X-Amz-Security-Token", valid_607684
  var valid_607685 = header.getOrDefault("X-Amz-Algorithm")
  valid_607685 = validateParameter(valid_607685, JString, required = false,
                                 default = nil)
  if valid_607685 != nil:
    section.add "X-Amz-Algorithm", valid_607685
  var valid_607686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607686 = validateParameter(valid_607686, JString, required = false,
                                 default = nil)
  if valid_607686 != nil:
    section.add "X-Amz-SignedHeaders", valid_607686
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_607687 = formData.getOrDefault("DashboardName")
  valid_607687 = validateParameter(valid_607687, JString, required = true,
                                 default = nil)
  if valid_607687 != nil:
    section.add "DashboardName", valid_607687
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607688: Call_PostGetDashboard_607675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_607688.validator(path, query, header, formData, body)
  let scheme = call_607688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607688.url(scheme.get, call_607688.host, call_607688.base,
                         call_607688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607688, url, valid)

proc call*(call_607689: Call_PostGetDashboard_607675; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## postGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607690 = newJObject()
  var formData_607691 = newJObject()
  add(formData_607691, "DashboardName", newJString(DashboardName))
  add(query_607690, "Action", newJString(Action))
  add(query_607690, "Version", newJString(Version))
  result = call_607689.call(nil, query_607690, nil, formData_607691, nil)

var postGetDashboard* = Call_PostGetDashboard_607675(name: "postGetDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_PostGetDashboard_607676,
    base: "/", url: url_PostGetDashboard_607677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetDashboard_607659 = ref object of OpenApiRestCall_606589
proc url_GetGetDashboard_607661(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetDashboard_607660(path: JsonNode; query: JsonNode;
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
  var valid_607662 = query.getOrDefault("Action")
  valid_607662 = validateParameter(valid_607662, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_607662 != nil:
    section.add "Action", valid_607662
  var valid_607663 = query.getOrDefault("DashboardName")
  valid_607663 = validateParameter(valid_607663, JString, required = true,
                                 default = nil)
  if valid_607663 != nil:
    section.add "DashboardName", valid_607663
  var valid_607664 = query.getOrDefault("Version")
  valid_607664 = validateParameter(valid_607664, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607664 != nil:
    section.add "Version", valid_607664
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
  var valid_607665 = header.getOrDefault("X-Amz-Signature")
  valid_607665 = validateParameter(valid_607665, JString, required = false,
                                 default = nil)
  if valid_607665 != nil:
    section.add "X-Amz-Signature", valid_607665
  var valid_607666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607666 = validateParameter(valid_607666, JString, required = false,
                                 default = nil)
  if valid_607666 != nil:
    section.add "X-Amz-Content-Sha256", valid_607666
  var valid_607667 = header.getOrDefault("X-Amz-Date")
  valid_607667 = validateParameter(valid_607667, JString, required = false,
                                 default = nil)
  if valid_607667 != nil:
    section.add "X-Amz-Date", valid_607667
  var valid_607668 = header.getOrDefault("X-Amz-Credential")
  valid_607668 = validateParameter(valid_607668, JString, required = false,
                                 default = nil)
  if valid_607668 != nil:
    section.add "X-Amz-Credential", valid_607668
  var valid_607669 = header.getOrDefault("X-Amz-Security-Token")
  valid_607669 = validateParameter(valid_607669, JString, required = false,
                                 default = nil)
  if valid_607669 != nil:
    section.add "X-Amz-Security-Token", valid_607669
  var valid_607670 = header.getOrDefault("X-Amz-Algorithm")
  valid_607670 = validateParameter(valid_607670, JString, required = false,
                                 default = nil)
  if valid_607670 != nil:
    section.add "X-Amz-Algorithm", valid_607670
  var valid_607671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607671 = validateParameter(valid_607671, JString, required = false,
                                 default = nil)
  if valid_607671 != nil:
    section.add "X-Amz-SignedHeaders", valid_607671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607672: Call_GetGetDashboard_607659; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_607672.validator(path, query, header, formData, body)
  let scheme = call_607672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607672.url(scheme.get, call_607672.host, call_607672.base,
                         call_607672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607672, url, valid)

proc call*(call_607673: Call_GetGetDashboard_607659; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## getGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Version: string (required)
  var query_607674 = newJObject()
  add(query_607674, "Action", newJString(Action))
  add(query_607674, "DashboardName", newJString(DashboardName))
  add(query_607674, "Version", newJString(Version))
  result = call_607673.call(nil, query_607674, nil, nil, nil)

var getGetDashboard* = Call_GetGetDashboard_607659(name: "getGetDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_GetGetDashboard_607660,
    base: "/", url: url_GetGetDashboard_607661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetInsightRuleReport_607714 = ref object of OpenApiRestCall_606589
proc url_PostGetInsightRuleReport_607716(protocol: Scheme; host: string;
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

proc validate_PostGetInsightRuleReport_607715(path: JsonNode; query: JsonNode;
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
  var valid_607717 = query.getOrDefault("Action")
  valid_607717 = validateParameter(valid_607717, JString, required = true,
                                 default = newJString("GetInsightRuleReport"))
  if valid_607717 != nil:
    section.add "Action", valid_607717
  var valid_607718 = query.getOrDefault("Version")
  valid_607718 = validateParameter(valid_607718, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607718 != nil:
    section.add "Version", valid_607718
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
  var valid_607719 = header.getOrDefault("X-Amz-Signature")
  valid_607719 = validateParameter(valid_607719, JString, required = false,
                                 default = nil)
  if valid_607719 != nil:
    section.add "X-Amz-Signature", valid_607719
  var valid_607720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607720 = validateParameter(valid_607720, JString, required = false,
                                 default = nil)
  if valid_607720 != nil:
    section.add "X-Amz-Content-Sha256", valid_607720
  var valid_607721 = header.getOrDefault("X-Amz-Date")
  valid_607721 = validateParameter(valid_607721, JString, required = false,
                                 default = nil)
  if valid_607721 != nil:
    section.add "X-Amz-Date", valid_607721
  var valid_607722 = header.getOrDefault("X-Amz-Credential")
  valid_607722 = validateParameter(valid_607722, JString, required = false,
                                 default = nil)
  if valid_607722 != nil:
    section.add "X-Amz-Credential", valid_607722
  var valid_607723 = header.getOrDefault("X-Amz-Security-Token")
  valid_607723 = validateParameter(valid_607723, JString, required = false,
                                 default = nil)
  if valid_607723 != nil:
    section.add "X-Amz-Security-Token", valid_607723
  var valid_607724 = header.getOrDefault("X-Amz-Algorithm")
  valid_607724 = validateParameter(valid_607724, JString, required = false,
                                 default = nil)
  if valid_607724 != nil:
    section.add "X-Amz-Algorithm", valid_607724
  var valid_607725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607725 = validateParameter(valid_607725, JString, required = false,
                                 default = nil)
  if valid_607725 != nil:
    section.add "X-Amz-SignedHeaders", valid_607725
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
  var valid_607726 = formData.getOrDefault("RuleName")
  valid_607726 = validateParameter(valid_607726, JString, required = true,
                                 default = nil)
  if valid_607726 != nil:
    section.add "RuleName", valid_607726
  var valid_607727 = formData.getOrDefault("Period")
  valid_607727 = validateParameter(valid_607727, JInt, required = true, default = nil)
  if valid_607727 != nil:
    section.add "Period", valid_607727
  var valid_607728 = formData.getOrDefault("OrderBy")
  valid_607728 = validateParameter(valid_607728, JString, required = false,
                                 default = nil)
  if valid_607728 != nil:
    section.add "OrderBy", valid_607728
  var valid_607729 = formData.getOrDefault("EndTime")
  valid_607729 = validateParameter(valid_607729, JString, required = true,
                                 default = nil)
  if valid_607729 != nil:
    section.add "EndTime", valid_607729
  var valid_607730 = formData.getOrDefault("StartTime")
  valid_607730 = validateParameter(valid_607730, JString, required = true,
                                 default = nil)
  if valid_607730 != nil:
    section.add "StartTime", valid_607730
  var valid_607731 = formData.getOrDefault("MaxContributorCount")
  valid_607731 = validateParameter(valid_607731, JInt, required = false, default = nil)
  if valid_607731 != nil:
    section.add "MaxContributorCount", valid_607731
  var valid_607732 = formData.getOrDefault("Metrics")
  valid_607732 = validateParameter(valid_607732, JArray, required = false,
                                 default = nil)
  if valid_607732 != nil:
    section.add "Metrics", valid_607732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607733: Call_PostGetInsightRuleReport_607714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_607733.validator(path, query, header, formData, body)
  let scheme = call_607733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607733.url(scheme.get, call_607733.host, call_607733.base,
                         call_607733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607733, url, valid)

proc call*(call_607734: Call_PostGetInsightRuleReport_607714; RuleName: string;
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
  var query_607735 = newJObject()
  var formData_607736 = newJObject()
  add(formData_607736, "RuleName", newJString(RuleName))
  add(formData_607736, "Period", newJInt(Period))
  add(formData_607736, "OrderBy", newJString(OrderBy))
  add(formData_607736, "EndTime", newJString(EndTime))
  add(formData_607736, "StartTime", newJString(StartTime))
  add(query_607735, "Action", newJString(Action))
  add(query_607735, "Version", newJString(Version))
  add(formData_607736, "MaxContributorCount", newJInt(MaxContributorCount))
  if Metrics != nil:
    formData_607736.add "Metrics", Metrics
  result = call_607734.call(nil, query_607735, nil, formData_607736, nil)

var postGetInsightRuleReport* = Call_PostGetInsightRuleReport_607714(
    name: "postGetInsightRuleReport", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_PostGetInsightRuleReport_607715, base: "/",
    url: url_PostGetInsightRuleReport_607716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetInsightRuleReport_607692 = ref object of OpenApiRestCall_606589
proc url_GetGetInsightRuleReport_607694(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetInsightRuleReport_607693(path: JsonNode; query: JsonNode;
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
  var valid_607695 = query.getOrDefault("RuleName")
  valid_607695 = validateParameter(valid_607695, JString, required = true,
                                 default = nil)
  if valid_607695 != nil:
    section.add "RuleName", valid_607695
  var valid_607696 = query.getOrDefault("MaxContributorCount")
  valid_607696 = validateParameter(valid_607696, JInt, required = false, default = nil)
  if valid_607696 != nil:
    section.add "MaxContributorCount", valid_607696
  var valid_607697 = query.getOrDefault("OrderBy")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "OrderBy", valid_607697
  var valid_607698 = query.getOrDefault("Period")
  valid_607698 = validateParameter(valid_607698, JInt, required = true, default = nil)
  if valid_607698 != nil:
    section.add "Period", valid_607698
  var valid_607699 = query.getOrDefault("Action")
  valid_607699 = validateParameter(valid_607699, JString, required = true,
                                 default = newJString("GetInsightRuleReport"))
  if valid_607699 != nil:
    section.add "Action", valid_607699
  var valid_607700 = query.getOrDefault("StartTime")
  valid_607700 = validateParameter(valid_607700, JString, required = true,
                                 default = nil)
  if valid_607700 != nil:
    section.add "StartTime", valid_607700
  var valid_607701 = query.getOrDefault("EndTime")
  valid_607701 = validateParameter(valid_607701, JString, required = true,
                                 default = nil)
  if valid_607701 != nil:
    section.add "EndTime", valid_607701
  var valid_607702 = query.getOrDefault("Metrics")
  valid_607702 = validateParameter(valid_607702, JArray, required = false,
                                 default = nil)
  if valid_607702 != nil:
    section.add "Metrics", valid_607702
  var valid_607703 = query.getOrDefault("Version")
  valid_607703 = validateParameter(valid_607703, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607703 != nil:
    section.add "Version", valid_607703
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
  var valid_607704 = header.getOrDefault("X-Amz-Signature")
  valid_607704 = validateParameter(valid_607704, JString, required = false,
                                 default = nil)
  if valid_607704 != nil:
    section.add "X-Amz-Signature", valid_607704
  var valid_607705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607705 = validateParameter(valid_607705, JString, required = false,
                                 default = nil)
  if valid_607705 != nil:
    section.add "X-Amz-Content-Sha256", valid_607705
  var valid_607706 = header.getOrDefault("X-Amz-Date")
  valid_607706 = validateParameter(valid_607706, JString, required = false,
                                 default = nil)
  if valid_607706 != nil:
    section.add "X-Amz-Date", valid_607706
  var valid_607707 = header.getOrDefault("X-Amz-Credential")
  valid_607707 = validateParameter(valid_607707, JString, required = false,
                                 default = nil)
  if valid_607707 != nil:
    section.add "X-Amz-Credential", valid_607707
  var valid_607708 = header.getOrDefault("X-Amz-Security-Token")
  valid_607708 = validateParameter(valid_607708, JString, required = false,
                                 default = nil)
  if valid_607708 != nil:
    section.add "X-Amz-Security-Token", valid_607708
  var valid_607709 = header.getOrDefault("X-Amz-Algorithm")
  valid_607709 = validateParameter(valid_607709, JString, required = false,
                                 default = nil)
  if valid_607709 != nil:
    section.add "X-Amz-Algorithm", valid_607709
  var valid_607710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "X-Amz-SignedHeaders", valid_607710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607711: Call_GetGetInsightRuleReport_607692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_607711.validator(path, query, header, formData, body)
  let scheme = call_607711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607711.url(scheme.get, call_607711.host, call_607711.base,
                         call_607711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607711, url, valid)

proc call*(call_607712: Call_GetGetInsightRuleReport_607692; RuleName: string;
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
  var query_607713 = newJObject()
  add(query_607713, "RuleName", newJString(RuleName))
  add(query_607713, "MaxContributorCount", newJInt(MaxContributorCount))
  add(query_607713, "OrderBy", newJString(OrderBy))
  add(query_607713, "Period", newJInt(Period))
  add(query_607713, "Action", newJString(Action))
  add(query_607713, "StartTime", newJString(StartTime))
  add(query_607713, "EndTime", newJString(EndTime))
  if Metrics != nil:
    query_607713.add "Metrics", Metrics
  add(query_607713, "Version", newJString(Version))
  result = call_607712.call(nil, query_607713, nil, nil, nil)

var getGetInsightRuleReport* = Call_GetGetInsightRuleReport_607692(
    name: "getGetInsightRuleReport", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_GetGetInsightRuleReport_607693, base: "/",
    url: url_GetGetInsightRuleReport_607694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricData_607758 = ref object of OpenApiRestCall_606589
proc url_PostGetMetricData_607760(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetMetricData_607759(path: JsonNode; query: JsonNode;
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
  var valid_607761 = query.getOrDefault("Action")
  valid_607761 = validateParameter(valid_607761, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_607761 != nil:
    section.add "Action", valid_607761
  var valid_607762 = query.getOrDefault("Version")
  valid_607762 = validateParameter(valid_607762, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607762 != nil:
    section.add "Version", valid_607762
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
  var valid_607763 = header.getOrDefault("X-Amz-Signature")
  valid_607763 = validateParameter(valid_607763, JString, required = false,
                                 default = nil)
  if valid_607763 != nil:
    section.add "X-Amz-Signature", valid_607763
  var valid_607764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607764 = validateParameter(valid_607764, JString, required = false,
                                 default = nil)
  if valid_607764 != nil:
    section.add "X-Amz-Content-Sha256", valid_607764
  var valid_607765 = header.getOrDefault("X-Amz-Date")
  valid_607765 = validateParameter(valid_607765, JString, required = false,
                                 default = nil)
  if valid_607765 != nil:
    section.add "X-Amz-Date", valid_607765
  var valid_607766 = header.getOrDefault("X-Amz-Credential")
  valid_607766 = validateParameter(valid_607766, JString, required = false,
                                 default = nil)
  if valid_607766 != nil:
    section.add "X-Amz-Credential", valid_607766
  var valid_607767 = header.getOrDefault("X-Amz-Security-Token")
  valid_607767 = validateParameter(valid_607767, JString, required = false,
                                 default = nil)
  if valid_607767 != nil:
    section.add "X-Amz-Security-Token", valid_607767
  var valid_607768 = header.getOrDefault("X-Amz-Algorithm")
  valid_607768 = validateParameter(valid_607768, JString, required = false,
                                 default = nil)
  if valid_607768 != nil:
    section.add "X-Amz-Algorithm", valid_607768
  var valid_607769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607769 = validateParameter(valid_607769, JString, required = false,
                                 default = nil)
  if valid_607769 != nil:
    section.add "X-Amz-SignedHeaders", valid_607769
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
  var valid_607770 = formData.getOrDefault("NextToken")
  valid_607770 = validateParameter(valid_607770, JString, required = false,
                                 default = nil)
  if valid_607770 != nil:
    section.add "NextToken", valid_607770
  var valid_607771 = formData.getOrDefault("ScanBy")
  valid_607771 = validateParameter(valid_607771, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_607771 != nil:
    section.add "ScanBy", valid_607771
  assert formData != nil,
        "formData argument is necessary due to required `EndTime` field"
  var valid_607772 = formData.getOrDefault("EndTime")
  valid_607772 = validateParameter(valid_607772, JString, required = true,
                                 default = nil)
  if valid_607772 != nil:
    section.add "EndTime", valid_607772
  var valid_607773 = formData.getOrDefault("StartTime")
  valid_607773 = validateParameter(valid_607773, JString, required = true,
                                 default = nil)
  if valid_607773 != nil:
    section.add "StartTime", valid_607773
  var valid_607774 = formData.getOrDefault("MetricDataQueries")
  valid_607774 = validateParameter(valid_607774, JArray, required = true, default = nil)
  if valid_607774 != nil:
    section.add "MetricDataQueries", valid_607774
  var valid_607775 = formData.getOrDefault("MaxDatapoints")
  valid_607775 = validateParameter(valid_607775, JInt, required = false, default = nil)
  if valid_607775 != nil:
    section.add "MaxDatapoints", valid_607775
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607776: Call_PostGetMetricData_607758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_607776.validator(path, query, header, formData, body)
  let scheme = call_607776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607776.url(scheme.get, call_607776.host, call_607776.base,
                         call_607776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607776, url, valid)

proc call*(call_607777: Call_PostGetMetricData_607758; EndTime: string;
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
  var query_607778 = newJObject()
  var formData_607779 = newJObject()
  add(formData_607779, "NextToken", newJString(NextToken))
  add(formData_607779, "ScanBy", newJString(ScanBy))
  add(formData_607779, "EndTime", newJString(EndTime))
  add(formData_607779, "StartTime", newJString(StartTime))
  add(query_607778, "Action", newJString(Action))
  add(query_607778, "Version", newJString(Version))
  if MetricDataQueries != nil:
    formData_607779.add "MetricDataQueries", MetricDataQueries
  add(formData_607779, "MaxDatapoints", newJInt(MaxDatapoints))
  result = call_607777.call(nil, query_607778, nil, formData_607779, nil)

var postGetMetricData* = Call_PostGetMetricData_607758(name: "postGetMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_PostGetMetricData_607759,
    base: "/", url: url_PostGetMetricData_607760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricData_607737 = ref object of OpenApiRestCall_606589
proc url_GetGetMetricData_607739(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricData_607738(path: JsonNode; query: JsonNode;
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
  var valid_607740 = query.getOrDefault("NextToken")
  valid_607740 = validateParameter(valid_607740, JString, required = false,
                                 default = nil)
  if valid_607740 != nil:
    section.add "NextToken", valid_607740
  var valid_607741 = query.getOrDefault("MaxDatapoints")
  valid_607741 = validateParameter(valid_607741, JInt, required = false, default = nil)
  if valid_607741 != nil:
    section.add "MaxDatapoints", valid_607741
  var valid_607742 = query.getOrDefault("Action")
  valid_607742 = validateParameter(valid_607742, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_607742 != nil:
    section.add "Action", valid_607742
  var valid_607743 = query.getOrDefault("StartTime")
  valid_607743 = validateParameter(valid_607743, JString, required = true,
                                 default = nil)
  if valid_607743 != nil:
    section.add "StartTime", valid_607743
  var valid_607744 = query.getOrDefault("EndTime")
  valid_607744 = validateParameter(valid_607744, JString, required = true,
                                 default = nil)
  if valid_607744 != nil:
    section.add "EndTime", valid_607744
  var valid_607745 = query.getOrDefault("Version")
  valid_607745 = validateParameter(valid_607745, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607745 != nil:
    section.add "Version", valid_607745
  var valid_607746 = query.getOrDefault("MetricDataQueries")
  valid_607746 = validateParameter(valid_607746, JArray, required = true, default = nil)
  if valid_607746 != nil:
    section.add "MetricDataQueries", valid_607746
  var valid_607747 = query.getOrDefault("ScanBy")
  valid_607747 = validateParameter(valid_607747, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_607747 != nil:
    section.add "ScanBy", valid_607747
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
  var valid_607748 = header.getOrDefault("X-Amz-Signature")
  valid_607748 = validateParameter(valid_607748, JString, required = false,
                                 default = nil)
  if valid_607748 != nil:
    section.add "X-Amz-Signature", valid_607748
  var valid_607749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607749 = validateParameter(valid_607749, JString, required = false,
                                 default = nil)
  if valid_607749 != nil:
    section.add "X-Amz-Content-Sha256", valid_607749
  var valid_607750 = header.getOrDefault("X-Amz-Date")
  valid_607750 = validateParameter(valid_607750, JString, required = false,
                                 default = nil)
  if valid_607750 != nil:
    section.add "X-Amz-Date", valid_607750
  var valid_607751 = header.getOrDefault("X-Amz-Credential")
  valid_607751 = validateParameter(valid_607751, JString, required = false,
                                 default = nil)
  if valid_607751 != nil:
    section.add "X-Amz-Credential", valid_607751
  var valid_607752 = header.getOrDefault("X-Amz-Security-Token")
  valid_607752 = validateParameter(valid_607752, JString, required = false,
                                 default = nil)
  if valid_607752 != nil:
    section.add "X-Amz-Security-Token", valid_607752
  var valid_607753 = header.getOrDefault("X-Amz-Algorithm")
  valid_607753 = validateParameter(valid_607753, JString, required = false,
                                 default = nil)
  if valid_607753 != nil:
    section.add "X-Amz-Algorithm", valid_607753
  var valid_607754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607754 = validateParameter(valid_607754, JString, required = false,
                                 default = nil)
  if valid_607754 != nil:
    section.add "X-Amz-SignedHeaders", valid_607754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607755: Call_GetGetMetricData_607737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_607755.validator(path, query, header, formData, body)
  let scheme = call_607755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607755.url(scheme.get, call_607755.host, call_607755.base,
                         call_607755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607755, url, valid)

proc call*(call_607756: Call_GetGetMetricData_607737; StartTime: string;
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
  var query_607757 = newJObject()
  add(query_607757, "NextToken", newJString(NextToken))
  add(query_607757, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_607757, "Action", newJString(Action))
  add(query_607757, "StartTime", newJString(StartTime))
  add(query_607757, "EndTime", newJString(EndTime))
  add(query_607757, "Version", newJString(Version))
  if MetricDataQueries != nil:
    query_607757.add "MetricDataQueries", MetricDataQueries
  add(query_607757, "ScanBy", newJString(ScanBy))
  result = call_607756.call(nil, query_607757, nil, nil, nil)

var getGetMetricData* = Call_GetGetMetricData_607737(name: "getGetMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_GetGetMetricData_607738,
    base: "/", url: url_GetGetMetricData_607739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricStatistics_607804 = ref object of OpenApiRestCall_606589
proc url_PostGetMetricStatistics_607806(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetMetricStatistics_607805(path: JsonNode; query: JsonNode;
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
  var valid_607807 = query.getOrDefault("Action")
  valid_607807 = validateParameter(valid_607807, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_607807 != nil:
    section.add "Action", valid_607807
  var valid_607808 = query.getOrDefault("Version")
  valid_607808 = validateParameter(valid_607808, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607808 != nil:
    section.add "Version", valid_607808
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
  var valid_607809 = header.getOrDefault("X-Amz-Signature")
  valid_607809 = validateParameter(valid_607809, JString, required = false,
                                 default = nil)
  if valid_607809 != nil:
    section.add "X-Amz-Signature", valid_607809
  var valid_607810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607810 = validateParameter(valid_607810, JString, required = false,
                                 default = nil)
  if valid_607810 != nil:
    section.add "X-Amz-Content-Sha256", valid_607810
  var valid_607811 = header.getOrDefault("X-Amz-Date")
  valid_607811 = validateParameter(valid_607811, JString, required = false,
                                 default = nil)
  if valid_607811 != nil:
    section.add "X-Amz-Date", valid_607811
  var valid_607812 = header.getOrDefault("X-Amz-Credential")
  valid_607812 = validateParameter(valid_607812, JString, required = false,
                                 default = nil)
  if valid_607812 != nil:
    section.add "X-Amz-Credential", valid_607812
  var valid_607813 = header.getOrDefault("X-Amz-Security-Token")
  valid_607813 = validateParameter(valid_607813, JString, required = false,
                                 default = nil)
  if valid_607813 != nil:
    section.add "X-Amz-Security-Token", valid_607813
  var valid_607814 = header.getOrDefault("X-Amz-Algorithm")
  valid_607814 = validateParameter(valid_607814, JString, required = false,
                                 default = nil)
  if valid_607814 != nil:
    section.add "X-Amz-Algorithm", valid_607814
  var valid_607815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "X-Amz-SignedHeaders", valid_607815
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
  var valid_607816 = formData.getOrDefault("Unit")
  valid_607816 = validateParameter(valid_607816, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_607816 != nil:
    section.add "Unit", valid_607816
  assert formData != nil,
        "formData argument is necessary due to required `Period` field"
  var valid_607817 = formData.getOrDefault("Period")
  valid_607817 = validateParameter(valid_607817, JInt, required = true, default = nil)
  if valid_607817 != nil:
    section.add "Period", valid_607817
  var valid_607818 = formData.getOrDefault("Statistics")
  valid_607818 = validateParameter(valid_607818, JArray, required = false,
                                 default = nil)
  if valid_607818 != nil:
    section.add "Statistics", valid_607818
  var valid_607819 = formData.getOrDefault("ExtendedStatistics")
  valid_607819 = validateParameter(valid_607819, JArray, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "ExtendedStatistics", valid_607819
  var valid_607820 = formData.getOrDefault("EndTime")
  valid_607820 = validateParameter(valid_607820, JString, required = true,
                                 default = nil)
  if valid_607820 != nil:
    section.add "EndTime", valid_607820
  var valid_607821 = formData.getOrDefault("StartTime")
  valid_607821 = validateParameter(valid_607821, JString, required = true,
                                 default = nil)
  if valid_607821 != nil:
    section.add "StartTime", valid_607821
  var valid_607822 = formData.getOrDefault("MetricName")
  valid_607822 = validateParameter(valid_607822, JString, required = true,
                                 default = nil)
  if valid_607822 != nil:
    section.add "MetricName", valid_607822
  var valid_607823 = formData.getOrDefault("Dimensions")
  valid_607823 = validateParameter(valid_607823, JArray, required = false,
                                 default = nil)
  if valid_607823 != nil:
    section.add "Dimensions", valid_607823
  var valid_607824 = formData.getOrDefault("Namespace")
  valid_607824 = validateParameter(valid_607824, JString, required = true,
                                 default = nil)
  if valid_607824 != nil:
    section.add "Namespace", valid_607824
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607825: Call_PostGetMetricStatistics_607804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_607825.validator(path, query, header, formData, body)
  let scheme = call_607825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607825.url(scheme.get, call_607825.host, call_607825.base,
                         call_607825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607825, url, valid)

proc call*(call_607826: Call_PostGetMetricStatistics_607804; Period: int;
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
  var query_607827 = newJObject()
  var formData_607828 = newJObject()
  add(formData_607828, "Unit", newJString(Unit))
  add(formData_607828, "Period", newJInt(Period))
  if Statistics != nil:
    formData_607828.add "Statistics", Statistics
  if ExtendedStatistics != nil:
    formData_607828.add "ExtendedStatistics", ExtendedStatistics
  add(formData_607828, "EndTime", newJString(EndTime))
  add(formData_607828, "StartTime", newJString(StartTime))
  add(formData_607828, "MetricName", newJString(MetricName))
  add(query_607827, "Action", newJString(Action))
  if Dimensions != nil:
    formData_607828.add "Dimensions", Dimensions
  add(formData_607828, "Namespace", newJString(Namespace))
  add(query_607827, "Version", newJString(Version))
  result = call_607826.call(nil, query_607827, nil, formData_607828, nil)

var postGetMetricStatistics* = Call_PostGetMetricStatistics_607804(
    name: "postGetMetricStatistics", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_PostGetMetricStatistics_607805, base: "/",
    url: url_PostGetMetricStatistics_607806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricStatistics_607780 = ref object of OpenApiRestCall_606589
proc url_GetGetMetricStatistics_607782(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricStatistics_607781(path: JsonNode; query: JsonNode;
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
  var valid_607783 = query.getOrDefault("Unit")
  valid_607783 = validateParameter(valid_607783, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_607783 != nil:
    section.add "Unit", valid_607783
  var valid_607784 = query.getOrDefault("ExtendedStatistics")
  valid_607784 = validateParameter(valid_607784, JArray, required = false,
                                 default = nil)
  if valid_607784 != nil:
    section.add "ExtendedStatistics", valid_607784
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_607785 = query.getOrDefault("Namespace")
  valid_607785 = validateParameter(valid_607785, JString, required = true,
                                 default = nil)
  if valid_607785 != nil:
    section.add "Namespace", valid_607785
  var valid_607786 = query.getOrDefault("Statistics")
  valid_607786 = validateParameter(valid_607786, JArray, required = false,
                                 default = nil)
  if valid_607786 != nil:
    section.add "Statistics", valid_607786
  var valid_607787 = query.getOrDefault("Period")
  valid_607787 = validateParameter(valid_607787, JInt, required = true, default = nil)
  if valid_607787 != nil:
    section.add "Period", valid_607787
  var valid_607788 = query.getOrDefault("Dimensions")
  valid_607788 = validateParameter(valid_607788, JArray, required = false,
                                 default = nil)
  if valid_607788 != nil:
    section.add "Dimensions", valid_607788
  var valid_607789 = query.getOrDefault("Action")
  valid_607789 = validateParameter(valid_607789, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_607789 != nil:
    section.add "Action", valid_607789
  var valid_607790 = query.getOrDefault("StartTime")
  valid_607790 = validateParameter(valid_607790, JString, required = true,
                                 default = nil)
  if valid_607790 != nil:
    section.add "StartTime", valid_607790
  var valid_607791 = query.getOrDefault("EndTime")
  valid_607791 = validateParameter(valid_607791, JString, required = true,
                                 default = nil)
  if valid_607791 != nil:
    section.add "EndTime", valid_607791
  var valid_607792 = query.getOrDefault("Version")
  valid_607792 = validateParameter(valid_607792, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607792 != nil:
    section.add "Version", valid_607792
  var valid_607793 = query.getOrDefault("MetricName")
  valid_607793 = validateParameter(valid_607793, JString, required = true,
                                 default = nil)
  if valid_607793 != nil:
    section.add "MetricName", valid_607793
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
  var valid_607794 = header.getOrDefault("X-Amz-Signature")
  valid_607794 = validateParameter(valid_607794, JString, required = false,
                                 default = nil)
  if valid_607794 != nil:
    section.add "X-Amz-Signature", valid_607794
  var valid_607795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607795 = validateParameter(valid_607795, JString, required = false,
                                 default = nil)
  if valid_607795 != nil:
    section.add "X-Amz-Content-Sha256", valid_607795
  var valid_607796 = header.getOrDefault("X-Amz-Date")
  valid_607796 = validateParameter(valid_607796, JString, required = false,
                                 default = nil)
  if valid_607796 != nil:
    section.add "X-Amz-Date", valid_607796
  var valid_607797 = header.getOrDefault("X-Amz-Credential")
  valid_607797 = validateParameter(valid_607797, JString, required = false,
                                 default = nil)
  if valid_607797 != nil:
    section.add "X-Amz-Credential", valid_607797
  var valid_607798 = header.getOrDefault("X-Amz-Security-Token")
  valid_607798 = validateParameter(valid_607798, JString, required = false,
                                 default = nil)
  if valid_607798 != nil:
    section.add "X-Amz-Security-Token", valid_607798
  var valid_607799 = header.getOrDefault("X-Amz-Algorithm")
  valid_607799 = validateParameter(valid_607799, JString, required = false,
                                 default = nil)
  if valid_607799 != nil:
    section.add "X-Amz-Algorithm", valid_607799
  var valid_607800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607800 = validateParameter(valid_607800, JString, required = false,
                                 default = nil)
  if valid_607800 != nil:
    section.add "X-Amz-SignedHeaders", valid_607800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607801: Call_GetGetMetricStatistics_607780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_607801.validator(path, query, header, formData, body)
  let scheme = call_607801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607801.url(scheme.get, call_607801.host, call_607801.base,
                         call_607801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607801, url, valid)

proc call*(call_607802: Call_GetGetMetricStatistics_607780; Namespace: string;
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
  var query_607803 = newJObject()
  add(query_607803, "Unit", newJString(Unit))
  if ExtendedStatistics != nil:
    query_607803.add "ExtendedStatistics", ExtendedStatistics
  add(query_607803, "Namespace", newJString(Namespace))
  if Statistics != nil:
    query_607803.add "Statistics", Statistics
  add(query_607803, "Period", newJInt(Period))
  if Dimensions != nil:
    query_607803.add "Dimensions", Dimensions
  add(query_607803, "Action", newJString(Action))
  add(query_607803, "StartTime", newJString(StartTime))
  add(query_607803, "EndTime", newJString(EndTime))
  add(query_607803, "Version", newJString(Version))
  add(query_607803, "MetricName", newJString(MetricName))
  result = call_607802.call(nil, query_607803, nil, nil, nil)

var getGetMetricStatistics* = Call_GetGetMetricStatistics_607780(
    name: "getGetMetricStatistics", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_GetGetMetricStatistics_607781, base: "/",
    url: url_GetGetMetricStatistics_607782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricWidgetImage_607846 = ref object of OpenApiRestCall_606589
proc url_PostGetMetricWidgetImage_607848(protocol: Scheme; host: string;
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

proc validate_PostGetMetricWidgetImage_607847(path: JsonNode; query: JsonNode;
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
  var valid_607849 = query.getOrDefault("Action")
  valid_607849 = validateParameter(valid_607849, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_607849 != nil:
    section.add "Action", valid_607849
  var valid_607850 = query.getOrDefault("Version")
  valid_607850 = validateParameter(valid_607850, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607850 != nil:
    section.add "Version", valid_607850
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
  var valid_607851 = header.getOrDefault("X-Amz-Signature")
  valid_607851 = validateParameter(valid_607851, JString, required = false,
                                 default = nil)
  if valid_607851 != nil:
    section.add "X-Amz-Signature", valid_607851
  var valid_607852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607852 = validateParameter(valid_607852, JString, required = false,
                                 default = nil)
  if valid_607852 != nil:
    section.add "X-Amz-Content-Sha256", valid_607852
  var valid_607853 = header.getOrDefault("X-Amz-Date")
  valid_607853 = validateParameter(valid_607853, JString, required = false,
                                 default = nil)
  if valid_607853 != nil:
    section.add "X-Amz-Date", valid_607853
  var valid_607854 = header.getOrDefault("X-Amz-Credential")
  valid_607854 = validateParameter(valid_607854, JString, required = false,
                                 default = nil)
  if valid_607854 != nil:
    section.add "X-Amz-Credential", valid_607854
  var valid_607855 = header.getOrDefault("X-Amz-Security-Token")
  valid_607855 = validateParameter(valid_607855, JString, required = false,
                                 default = nil)
  if valid_607855 != nil:
    section.add "X-Amz-Security-Token", valid_607855
  var valid_607856 = header.getOrDefault("X-Amz-Algorithm")
  valid_607856 = validateParameter(valid_607856, JString, required = false,
                                 default = nil)
  if valid_607856 != nil:
    section.add "X-Amz-Algorithm", valid_607856
  var valid_607857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607857 = validateParameter(valid_607857, JString, required = false,
                                 default = nil)
  if valid_607857 != nil:
    section.add "X-Amz-SignedHeaders", valid_607857
  result.add "header", section
  ## parameters in `formData` object:
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MetricWidget` field"
  var valid_607858 = formData.getOrDefault("MetricWidget")
  valid_607858 = validateParameter(valid_607858, JString, required = true,
                                 default = nil)
  if valid_607858 != nil:
    section.add "MetricWidget", valid_607858
  var valid_607859 = formData.getOrDefault("OutputFormat")
  valid_607859 = validateParameter(valid_607859, JString, required = false,
                                 default = nil)
  if valid_607859 != nil:
    section.add "OutputFormat", valid_607859
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607860: Call_PostGetMetricWidgetImage_607846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_607860.validator(path, query, header, formData, body)
  let scheme = call_607860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607860.url(scheme.get, call_607860.host, call_607860.base,
                         call_607860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607860, url, valid)

proc call*(call_607861: Call_PostGetMetricWidgetImage_607846; MetricWidget: string;
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
  var query_607862 = newJObject()
  var formData_607863 = newJObject()
  add(formData_607863, "MetricWidget", newJString(MetricWidget))
  add(formData_607863, "OutputFormat", newJString(OutputFormat))
  add(query_607862, "Action", newJString(Action))
  add(query_607862, "Version", newJString(Version))
  result = call_607861.call(nil, query_607862, nil, formData_607863, nil)

var postGetMetricWidgetImage* = Call_PostGetMetricWidgetImage_607846(
    name: "postGetMetricWidgetImage", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_PostGetMetricWidgetImage_607847, base: "/",
    url: url_PostGetMetricWidgetImage_607848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricWidgetImage_607829 = ref object of OpenApiRestCall_606589
proc url_GetGetMetricWidgetImage_607831(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricWidgetImage_607830(path: JsonNode; query: JsonNode;
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
  var valid_607832 = query.getOrDefault("OutputFormat")
  valid_607832 = validateParameter(valid_607832, JString, required = false,
                                 default = nil)
  if valid_607832 != nil:
    section.add "OutputFormat", valid_607832
  assert query != nil,
        "query argument is necessary due to required `MetricWidget` field"
  var valid_607833 = query.getOrDefault("MetricWidget")
  valid_607833 = validateParameter(valid_607833, JString, required = true,
                                 default = nil)
  if valid_607833 != nil:
    section.add "MetricWidget", valid_607833
  var valid_607834 = query.getOrDefault("Action")
  valid_607834 = validateParameter(valid_607834, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_607834 != nil:
    section.add "Action", valid_607834
  var valid_607835 = query.getOrDefault("Version")
  valid_607835 = validateParameter(valid_607835, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607835 != nil:
    section.add "Version", valid_607835
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
  var valid_607836 = header.getOrDefault("X-Amz-Signature")
  valid_607836 = validateParameter(valid_607836, JString, required = false,
                                 default = nil)
  if valid_607836 != nil:
    section.add "X-Amz-Signature", valid_607836
  var valid_607837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607837 = validateParameter(valid_607837, JString, required = false,
                                 default = nil)
  if valid_607837 != nil:
    section.add "X-Amz-Content-Sha256", valid_607837
  var valid_607838 = header.getOrDefault("X-Amz-Date")
  valid_607838 = validateParameter(valid_607838, JString, required = false,
                                 default = nil)
  if valid_607838 != nil:
    section.add "X-Amz-Date", valid_607838
  var valid_607839 = header.getOrDefault("X-Amz-Credential")
  valid_607839 = validateParameter(valid_607839, JString, required = false,
                                 default = nil)
  if valid_607839 != nil:
    section.add "X-Amz-Credential", valid_607839
  var valid_607840 = header.getOrDefault("X-Amz-Security-Token")
  valid_607840 = validateParameter(valid_607840, JString, required = false,
                                 default = nil)
  if valid_607840 != nil:
    section.add "X-Amz-Security-Token", valid_607840
  var valid_607841 = header.getOrDefault("X-Amz-Algorithm")
  valid_607841 = validateParameter(valid_607841, JString, required = false,
                                 default = nil)
  if valid_607841 != nil:
    section.add "X-Amz-Algorithm", valid_607841
  var valid_607842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607842 = validateParameter(valid_607842, JString, required = false,
                                 default = nil)
  if valid_607842 != nil:
    section.add "X-Amz-SignedHeaders", valid_607842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607843: Call_GetGetMetricWidgetImage_607829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_607843.validator(path, query, header, formData, body)
  let scheme = call_607843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607843.url(scheme.get, call_607843.host, call_607843.base,
                         call_607843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607843, url, valid)

proc call*(call_607844: Call_GetGetMetricWidgetImage_607829; MetricWidget: string;
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
  var query_607845 = newJObject()
  add(query_607845, "OutputFormat", newJString(OutputFormat))
  add(query_607845, "MetricWidget", newJString(MetricWidget))
  add(query_607845, "Action", newJString(Action))
  add(query_607845, "Version", newJString(Version))
  result = call_607844.call(nil, query_607845, nil, nil, nil)

var getGetMetricWidgetImage* = Call_GetGetMetricWidgetImage_607829(
    name: "getGetMetricWidgetImage", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_GetGetMetricWidgetImage_607830, base: "/",
    url: url_GetGetMetricWidgetImage_607831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDashboards_607881 = ref object of OpenApiRestCall_606589
proc url_PostListDashboards_607883(protocol: Scheme; host: string; base: string;
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

proc validate_PostListDashboards_607882(path: JsonNode; query: JsonNode;
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
  var valid_607884 = query.getOrDefault("Action")
  valid_607884 = validateParameter(valid_607884, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_607884 != nil:
    section.add "Action", valid_607884
  var valid_607885 = query.getOrDefault("Version")
  valid_607885 = validateParameter(valid_607885, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607885 != nil:
    section.add "Version", valid_607885
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
  var valid_607886 = header.getOrDefault("X-Amz-Signature")
  valid_607886 = validateParameter(valid_607886, JString, required = false,
                                 default = nil)
  if valid_607886 != nil:
    section.add "X-Amz-Signature", valid_607886
  var valid_607887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607887 = validateParameter(valid_607887, JString, required = false,
                                 default = nil)
  if valid_607887 != nil:
    section.add "X-Amz-Content-Sha256", valid_607887
  var valid_607888 = header.getOrDefault("X-Amz-Date")
  valid_607888 = validateParameter(valid_607888, JString, required = false,
                                 default = nil)
  if valid_607888 != nil:
    section.add "X-Amz-Date", valid_607888
  var valid_607889 = header.getOrDefault("X-Amz-Credential")
  valid_607889 = validateParameter(valid_607889, JString, required = false,
                                 default = nil)
  if valid_607889 != nil:
    section.add "X-Amz-Credential", valid_607889
  var valid_607890 = header.getOrDefault("X-Amz-Security-Token")
  valid_607890 = validateParameter(valid_607890, JString, required = false,
                                 default = nil)
  if valid_607890 != nil:
    section.add "X-Amz-Security-Token", valid_607890
  var valid_607891 = header.getOrDefault("X-Amz-Algorithm")
  valid_607891 = validateParameter(valid_607891, JString, required = false,
                                 default = nil)
  if valid_607891 != nil:
    section.add "X-Amz-Algorithm", valid_607891
  var valid_607892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607892 = validateParameter(valid_607892, JString, required = false,
                                 default = nil)
  if valid_607892 != nil:
    section.add "X-Amz-SignedHeaders", valid_607892
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   DashboardNamePrefix: JString
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  section = newJObject()
  var valid_607893 = formData.getOrDefault("NextToken")
  valid_607893 = validateParameter(valid_607893, JString, required = false,
                                 default = nil)
  if valid_607893 != nil:
    section.add "NextToken", valid_607893
  var valid_607894 = formData.getOrDefault("DashboardNamePrefix")
  valid_607894 = validateParameter(valid_607894, JString, required = false,
                                 default = nil)
  if valid_607894 != nil:
    section.add "DashboardNamePrefix", valid_607894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607895: Call_PostListDashboards_607881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_607895.validator(path, query, header, formData, body)
  let scheme = call_607895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607895.url(scheme.get, call_607895.host, call_607895.base,
                         call_607895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607895, url, valid)

proc call*(call_607896: Call_PostListDashboards_607881; NextToken: string = "";
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
  var query_607897 = newJObject()
  var formData_607898 = newJObject()
  add(formData_607898, "NextToken", newJString(NextToken))
  add(formData_607898, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_607897, "Action", newJString(Action))
  add(query_607897, "Version", newJString(Version))
  result = call_607896.call(nil, query_607897, nil, formData_607898, nil)

var postListDashboards* = Call_PostListDashboards_607881(
    name: "postListDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListDashboards",
    validator: validate_PostListDashboards_607882, base: "/",
    url: url_PostListDashboards_607883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDashboards_607864 = ref object of OpenApiRestCall_606589
proc url_GetListDashboards_607866(protocol: Scheme; host: string; base: string;
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

proc validate_GetListDashboards_607865(path: JsonNode; query: JsonNode;
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
  var valid_607867 = query.getOrDefault("DashboardNamePrefix")
  valid_607867 = validateParameter(valid_607867, JString, required = false,
                                 default = nil)
  if valid_607867 != nil:
    section.add "DashboardNamePrefix", valid_607867
  var valid_607868 = query.getOrDefault("NextToken")
  valid_607868 = validateParameter(valid_607868, JString, required = false,
                                 default = nil)
  if valid_607868 != nil:
    section.add "NextToken", valid_607868
  var valid_607869 = query.getOrDefault("Action")
  valid_607869 = validateParameter(valid_607869, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_607869 != nil:
    section.add "Action", valid_607869
  var valid_607870 = query.getOrDefault("Version")
  valid_607870 = validateParameter(valid_607870, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607870 != nil:
    section.add "Version", valid_607870
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
  var valid_607871 = header.getOrDefault("X-Amz-Signature")
  valid_607871 = validateParameter(valid_607871, JString, required = false,
                                 default = nil)
  if valid_607871 != nil:
    section.add "X-Amz-Signature", valid_607871
  var valid_607872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607872 = validateParameter(valid_607872, JString, required = false,
                                 default = nil)
  if valid_607872 != nil:
    section.add "X-Amz-Content-Sha256", valid_607872
  var valid_607873 = header.getOrDefault("X-Amz-Date")
  valid_607873 = validateParameter(valid_607873, JString, required = false,
                                 default = nil)
  if valid_607873 != nil:
    section.add "X-Amz-Date", valid_607873
  var valid_607874 = header.getOrDefault("X-Amz-Credential")
  valid_607874 = validateParameter(valid_607874, JString, required = false,
                                 default = nil)
  if valid_607874 != nil:
    section.add "X-Amz-Credential", valid_607874
  var valid_607875 = header.getOrDefault("X-Amz-Security-Token")
  valid_607875 = validateParameter(valid_607875, JString, required = false,
                                 default = nil)
  if valid_607875 != nil:
    section.add "X-Amz-Security-Token", valid_607875
  var valid_607876 = header.getOrDefault("X-Amz-Algorithm")
  valid_607876 = validateParameter(valid_607876, JString, required = false,
                                 default = nil)
  if valid_607876 != nil:
    section.add "X-Amz-Algorithm", valid_607876
  var valid_607877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607877 = validateParameter(valid_607877, JString, required = false,
                                 default = nil)
  if valid_607877 != nil:
    section.add "X-Amz-SignedHeaders", valid_607877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607878: Call_GetListDashboards_607864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_607878.validator(path, query, header, formData, body)
  let scheme = call_607878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607878.url(scheme.get, call_607878.host, call_607878.base,
                         call_607878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607878, url, valid)

proc call*(call_607879: Call_GetListDashboards_607864;
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
  var query_607880 = newJObject()
  add(query_607880, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_607880, "NextToken", newJString(NextToken))
  add(query_607880, "Action", newJString(Action))
  add(query_607880, "Version", newJString(Version))
  result = call_607879.call(nil, query_607880, nil, nil, nil)

var getListDashboards* = Call_GetListDashboards_607864(name: "getListDashboards",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListDashboards", validator: validate_GetListDashboards_607865,
    base: "/", url: url_GetListDashboards_607866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListMetrics_607918 = ref object of OpenApiRestCall_606589
proc url_PostListMetrics_607920(protocol: Scheme; host: string; base: string;
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

proc validate_PostListMetrics_607919(path: JsonNode; query: JsonNode;
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
  var valid_607921 = query.getOrDefault("Action")
  valid_607921 = validateParameter(valid_607921, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_607921 != nil:
    section.add "Action", valid_607921
  var valid_607922 = query.getOrDefault("Version")
  valid_607922 = validateParameter(valid_607922, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607922 != nil:
    section.add "Version", valid_607922
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
  var valid_607923 = header.getOrDefault("X-Amz-Signature")
  valid_607923 = validateParameter(valid_607923, JString, required = false,
                                 default = nil)
  if valid_607923 != nil:
    section.add "X-Amz-Signature", valid_607923
  var valid_607924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607924 = validateParameter(valid_607924, JString, required = false,
                                 default = nil)
  if valid_607924 != nil:
    section.add "X-Amz-Content-Sha256", valid_607924
  var valid_607925 = header.getOrDefault("X-Amz-Date")
  valid_607925 = validateParameter(valid_607925, JString, required = false,
                                 default = nil)
  if valid_607925 != nil:
    section.add "X-Amz-Date", valid_607925
  var valid_607926 = header.getOrDefault("X-Amz-Credential")
  valid_607926 = validateParameter(valid_607926, JString, required = false,
                                 default = nil)
  if valid_607926 != nil:
    section.add "X-Amz-Credential", valid_607926
  var valid_607927 = header.getOrDefault("X-Amz-Security-Token")
  valid_607927 = validateParameter(valid_607927, JString, required = false,
                                 default = nil)
  if valid_607927 != nil:
    section.add "X-Amz-Security-Token", valid_607927
  var valid_607928 = header.getOrDefault("X-Amz-Algorithm")
  valid_607928 = validateParameter(valid_607928, JString, required = false,
                                 default = nil)
  if valid_607928 != nil:
    section.add "X-Amz-Algorithm", valid_607928
  var valid_607929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607929 = validateParameter(valid_607929, JString, required = false,
                                 default = nil)
  if valid_607929 != nil:
    section.add "X-Amz-SignedHeaders", valid_607929
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
  var valid_607930 = formData.getOrDefault("NextToken")
  valid_607930 = validateParameter(valid_607930, JString, required = false,
                                 default = nil)
  if valid_607930 != nil:
    section.add "NextToken", valid_607930
  var valid_607931 = formData.getOrDefault("MetricName")
  valid_607931 = validateParameter(valid_607931, JString, required = false,
                                 default = nil)
  if valid_607931 != nil:
    section.add "MetricName", valid_607931
  var valid_607932 = formData.getOrDefault("Dimensions")
  valid_607932 = validateParameter(valid_607932, JArray, required = false,
                                 default = nil)
  if valid_607932 != nil:
    section.add "Dimensions", valid_607932
  var valid_607933 = formData.getOrDefault("Namespace")
  valid_607933 = validateParameter(valid_607933, JString, required = false,
                                 default = nil)
  if valid_607933 != nil:
    section.add "Namespace", valid_607933
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607934: Call_PostListMetrics_607918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_607934.validator(path, query, header, formData, body)
  let scheme = call_607934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607934.url(scheme.get, call_607934.host, call_607934.base,
                         call_607934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607934, url, valid)

proc call*(call_607935: Call_PostListMetrics_607918; NextToken: string = "";
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
  var query_607936 = newJObject()
  var formData_607937 = newJObject()
  add(formData_607937, "NextToken", newJString(NextToken))
  add(formData_607937, "MetricName", newJString(MetricName))
  add(query_607936, "Action", newJString(Action))
  if Dimensions != nil:
    formData_607937.add "Dimensions", Dimensions
  add(formData_607937, "Namespace", newJString(Namespace))
  add(query_607936, "Version", newJString(Version))
  result = call_607935.call(nil, query_607936, nil, formData_607937, nil)

var postListMetrics* = Call_PostListMetrics_607918(name: "postListMetrics",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_PostListMetrics_607919,
    base: "/", url: url_PostListMetrics_607920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListMetrics_607899 = ref object of OpenApiRestCall_606589
proc url_GetListMetrics_607901(protocol: Scheme; host: string; base: string;
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

proc validate_GetListMetrics_607900(path: JsonNode; query: JsonNode;
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
  var valid_607902 = query.getOrDefault("NextToken")
  valid_607902 = validateParameter(valid_607902, JString, required = false,
                                 default = nil)
  if valid_607902 != nil:
    section.add "NextToken", valid_607902
  var valid_607903 = query.getOrDefault("Namespace")
  valid_607903 = validateParameter(valid_607903, JString, required = false,
                                 default = nil)
  if valid_607903 != nil:
    section.add "Namespace", valid_607903
  var valid_607904 = query.getOrDefault("Dimensions")
  valid_607904 = validateParameter(valid_607904, JArray, required = false,
                                 default = nil)
  if valid_607904 != nil:
    section.add "Dimensions", valid_607904
  var valid_607905 = query.getOrDefault("Action")
  valid_607905 = validateParameter(valid_607905, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_607905 != nil:
    section.add "Action", valid_607905
  var valid_607906 = query.getOrDefault("Version")
  valid_607906 = validateParameter(valid_607906, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607906 != nil:
    section.add "Version", valid_607906
  var valid_607907 = query.getOrDefault("MetricName")
  valid_607907 = validateParameter(valid_607907, JString, required = false,
                                 default = nil)
  if valid_607907 != nil:
    section.add "MetricName", valid_607907
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
  var valid_607908 = header.getOrDefault("X-Amz-Signature")
  valid_607908 = validateParameter(valid_607908, JString, required = false,
                                 default = nil)
  if valid_607908 != nil:
    section.add "X-Amz-Signature", valid_607908
  var valid_607909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607909 = validateParameter(valid_607909, JString, required = false,
                                 default = nil)
  if valid_607909 != nil:
    section.add "X-Amz-Content-Sha256", valid_607909
  var valid_607910 = header.getOrDefault("X-Amz-Date")
  valid_607910 = validateParameter(valid_607910, JString, required = false,
                                 default = nil)
  if valid_607910 != nil:
    section.add "X-Amz-Date", valid_607910
  var valid_607911 = header.getOrDefault("X-Amz-Credential")
  valid_607911 = validateParameter(valid_607911, JString, required = false,
                                 default = nil)
  if valid_607911 != nil:
    section.add "X-Amz-Credential", valid_607911
  var valid_607912 = header.getOrDefault("X-Amz-Security-Token")
  valid_607912 = validateParameter(valid_607912, JString, required = false,
                                 default = nil)
  if valid_607912 != nil:
    section.add "X-Amz-Security-Token", valid_607912
  var valid_607913 = header.getOrDefault("X-Amz-Algorithm")
  valid_607913 = validateParameter(valid_607913, JString, required = false,
                                 default = nil)
  if valid_607913 != nil:
    section.add "X-Amz-Algorithm", valid_607913
  var valid_607914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607914 = validateParameter(valid_607914, JString, required = false,
                                 default = nil)
  if valid_607914 != nil:
    section.add "X-Amz-SignedHeaders", valid_607914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607915: Call_GetListMetrics_607899; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_607915.validator(path, query, header, formData, body)
  let scheme = call_607915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607915.url(scheme.get, call_607915.host, call_607915.base,
                         call_607915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607915, url, valid)

proc call*(call_607916: Call_GetListMetrics_607899; NextToken: string = "";
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
  var query_607917 = newJObject()
  add(query_607917, "NextToken", newJString(NextToken))
  add(query_607917, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_607917.add "Dimensions", Dimensions
  add(query_607917, "Action", newJString(Action))
  add(query_607917, "Version", newJString(Version))
  add(query_607917, "MetricName", newJString(MetricName))
  result = call_607916.call(nil, query_607917, nil, nil, nil)

var getListMetrics* = Call_GetListMetrics_607899(name: "getListMetrics",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_GetListMetrics_607900,
    base: "/", url: url_GetListMetrics_607901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_607954 = ref object of OpenApiRestCall_606589
proc url_PostListTagsForResource_607956(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_607955(path: JsonNode; query: JsonNode;
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
  var valid_607957 = query.getOrDefault("Action")
  valid_607957 = validateParameter(valid_607957, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607957 != nil:
    section.add "Action", valid_607957
  var valid_607958 = query.getOrDefault("Version")
  valid_607958 = validateParameter(valid_607958, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607958 != nil:
    section.add "Version", valid_607958
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
  var valid_607959 = header.getOrDefault("X-Amz-Signature")
  valid_607959 = validateParameter(valid_607959, JString, required = false,
                                 default = nil)
  if valid_607959 != nil:
    section.add "X-Amz-Signature", valid_607959
  var valid_607960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607960 = validateParameter(valid_607960, JString, required = false,
                                 default = nil)
  if valid_607960 != nil:
    section.add "X-Amz-Content-Sha256", valid_607960
  var valid_607961 = header.getOrDefault("X-Amz-Date")
  valid_607961 = validateParameter(valid_607961, JString, required = false,
                                 default = nil)
  if valid_607961 != nil:
    section.add "X-Amz-Date", valid_607961
  var valid_607962 = header.getOrDefault("X-Amz-Credential")
  valid_607962 = validateParameter(valid_607962, JString, required = false,
                                 default = nil)
  if valid_607962 != nil:
    section.add "X-Amz-Credential", valid_607962
  var valid_607963 = header.getOrDefault("X-Amz-Security-Token")
  valid_607963 = validateParameter(valid_607963, JString, required = false,
                                 default = nil)
  if valid_607963 != nil:
    section.add "X-Amz-Security-Token", valid_607963
  var valid_607964 = header.getOrDefault("X-Amz-Algorithm")
  valid_607964 = validateParameter(valid_607964, JString, required = false,
                                 default = nil)
  if valid_607964 != nil:
    section.add "X-Amz-Algorithm", valid_607964
  var valid_607965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607965 = validateParameter(valid_607965, JString, required = false,
                                 default = nil)
  if valid_607965 != nil:
    section.add "X-Amz-SignedHeaders", valid_607965
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceARN` field"
  var valid_607966 = formData.getOrDefault("ResourceARN")
  valid_607966 = validateParameter(valid_607966, JString, required = true,
                                 default = nil)
  if valid_607966 != nil:
    section.add "ResourceARN", valid_607966
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607967: Call_PostListTagsForResource_607954; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_607967.validator(path, query, header, formData, body)
  let scheme = call_607967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607967.url(scheme.get, call_607967.host, call_607967.base,
                         call_607967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607967, url, valid)

proc call*(call_607968: Call_PostListTagsForResource_607954; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## postListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  var query_607969 = newJObject()
  var formData_607970 = newJObject()
  add(query_607969, "Action", newJString(Action))
  add(query_607969, "Version", newJString(Version))
  add(formData_607970, "ResourceARN", newJString(ResourceARN))
  result = call_607968.call(nil, query_607969, nil, formData_607970, nil)

var postListTagsForResource* = Call_PostListTagsForResource_607954(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_607955, base: "/",
    url: url_PostListTagsForResource_607956, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_607938 = ref object of OpenApiRestCall_606589
proc url_GetListTagsForResource_607940(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_607939(path: JsonNode; query: JsonNode;
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
  var valid_607941 = query.getOrDefault("Action")
  valid_607941 = validateParameter(valid_607941, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607941 != nil:
    section.add "Action", valid_607941
  var valid_607942 = query.getOrDefault("ResourceARN")
  valid_607942 = validateParameter(valid_607942, JString, required = true,
                                 default = nil)
  if valid_607942 != nil:
    section.add "ResourceARN", valid_607942
  var valid_607943 = query.getOrDefault("Version")
  valid_607943 = validateParameter(valid_607943, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607943 != nil:
    section.add "Version", valid_607943
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
  var valid_607944 = header.getOrDefault("X-Amz-Signature")
  valid_607944 = validateParameter(valid_607944, JString, required = false,
                                 default = nil)
  if valid_607944 != nil:
    section.add "X-Amz-Signature", valid_607944
  var valid_607945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607945 = validateParameter(valid_607945, JString, required = false,
                                 default = nil)
  if valid_607945 != nil:
    section.add "X-Amz-Content-Sha256", valid_607945
  var valid_607946 = header.getOrDefault("X-Amz-Date")
  valid_607946 = validateParameter(valid_607946, JString, required = false,
                                 default = nil)
  if valid_607946 != nil:
    section.add "X-Amz-Date", valid_607946
  var valid_607947 = header.getOrDefault("X-Amz-Credential")
  valid_607947 = validateParameter(valid_607947, JString, required = false,
                                 default = nil)
  if valid_607947 != nil:
    section.add "X-Amz-Credential", valid_607947
  var valid_607948 = header.getOrDefault("X-Amz-Security-Token")
  valid_607948 = validateParameter(valid_607948, JString, required = false,
                                 default = nil)
  if valid_607948 != nil:
    section.add "X-Amz-Security-Token", valid_607948
  var valid_607949 = header.getOrDefault("X-Amz-Algorithm")
  valid_607949 = validateParameter(valid_607949, JString, required = false,
                                 default = nil)
  if valid_607949 != nil:
    section.add "X-Amz-Algorithm", valid_607949
  var valid_607950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607950 = validateParameter(valid_607950, JString, required = false,
                                 default = nil)
  if valid_607950 != nil:
    section.add "X-Amz-SignedHeaders", valid_607950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607951: Call_GetListTagsForResource_607938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_607951.validator(path, query, header, formData, body)
  let scheme = call_607951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607951.url(scheme.get, call_607951.host, call_607951.base,
                         call_607951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607951, url, valid)

proc call*(call_607952: Call_GetListTagsForResource_607938; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## getListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_607953 = newJObject()
  add(query_607953, "Action", newJString(Action))
  add(query_607953, "ResourceARN", newJString(ResourceARN))
  add(query_607953, "Version", newJString(Version))
  result = call_607952.call(nil, query_607953, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_607938(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_607939, base: "/",
    url: url_GetListTagsForResource_607940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAnomalyDetector_607992 = ref object of OpenApiRestCall_606589
proc url_PostPutAnomalyDetector_607994(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutAnomalyDetector_607993(path: JsonNode; query: JsonNode;
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
  var valid_607995 = query.getOrDefault("Action")
  valid_607995 = validateParameter(valid_607995, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_607995 != nil:
    section.add "Action", valid_607995
  var valid_607996 = query.getOrDefault("Version")
  valid_607996 = validateParameter(valid_607996, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607996 != nil:
    section.add "Version", valid_607996
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
  var valid_607997 = header.getOrDefault("X-Amz-Signature")
  valid_607997 = validateParameter(valid_607997, JString, required = false,
                                 default = nil)
  if valid_607997 != nil:
    section.add "X-Amz-Signature", valid_607997
  var valid_607998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607998 = validateParameter(valid_607998, JString, required = false,
                                 default = nil)
  if valid_607998 != nil:
    section.add "X-Amz-Content-Sha256", valid_607998
  var valid_607999 = header.getOrDefault("X-Amz-Date")
  valid_607999 = validateParameter(valid_607999, JString, required = false,
                                 default = nil)
  if valid_607999 != nil:
    section.add "X-Amz-Date", valid_607999
  var valid_608000 = header.getOrDefault("X-Amz-Credential")
  valid_608000 = validateParameter(valid_608000, JString, required = false,
                                 default = nil)
  if valid_608000 != nil:
    section.add "X-Amz-Credential", valid_608000
  var valid_608001 = header.getOrDefault("X-Amz-Security-Token")
  valid_608001 = validateParameter(valid_608001, JString, required = false,
                                 default = nil)
  if valid_608001 != nil:
    section.add "X-Amz-Security-Token", valid_608001
  var valid_608002 = header.getOrDefault("X-Amz-Algorithm")
  valid_608002 = validateParameter(valid_608002, JString, required = false,
                                 default = nil)
  if valid_608002 != nil:
    section.add "X-Amz-Algorithm", valid_608002
  var valid_608003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608003 = validateParameter(valid_608003, JString, required = false,
                                 default = nil)
  if valid_608003 != nil:
    section.add "X-Amz-SignedHeaders", valid_608003
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
  var valid_608004 = formData.getOrDefault("Stat")
  valid_608004 = validateParameter(valid_608004, JString, required = true,
                                 default = nil)
  if valid_608004 != nil:
    section.add "Stat", valid_608004
  var valid_608005 = formData.getOrDefault("Configuration.MetricTimezone")
  valid_608005 = validateParameter(valid_608005, JString, required = false,
                                 default = nil)
  if valid_608005 != nil:
    section.add "Configuration.MetricTimezone", valid_608005
  var valid_608006 = formData.getOrDefault("MetricName")
  valid_608006 = validateParameter(valid_608006, JString, required = true,
                                 default = nil)
  if valid_608006 != nil:
    section.add "MetricName", valid_608006
  var valid_608007 = formData.getOrDefault("Dimensions")
  valid_608007 = validateParameter(valid_608007, JArray, required = false,
                                 default = nil)
  if valid_608007 != nil:
    section.add "Dimensions", valid_608007
  var valid_608008 = formData.getOrDefault("Namespace")
  valid_608008 = validateParameter(valid_608008, JString, required = true,
                                 default = nil)
  if valid_608008 != nil:
    section.add "Namespace", valid_608008
  var valid_608009 = formData.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_608009 = validateParameter(valid_608009, JArray, required = false,
                                 default = nil)
  if valid_608009 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_608009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608010: Call_PostPutAnomalyDetector_607992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_608010.validator(path, query, header, formData, body)
  let scheme = call_608010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608010.url(scheme.get, call_608010.host, call_608010.base,
                         call_608010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608010, url, valid)

proc call*(call_608011: Call_PostPutAnomalyDetector_607992; Stat: string;
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
  var query_608012 = newJObject()
  var formData_608013 = newJObject()
  add(formData_608013, "Stat", newJString(Stat))
  add(formData_608013, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  add(formData_608013, "MetricName", newJString(MetricName))
  add(query_608012, "Action", newJString(Action))
  if Dimensions != nil:
    formData_608013.add "Dimensions", Dimensions
  add(formData_608013, "Namespace", newJString(Namespace))
  if ConfigurationExcludedTimeRanges != nil:
    formData_608013.add "Configuration.ExcludedTimeRanges",
                       ConfigurationExcludedTimeRanges
  add(query_608012, "Version", newJString(Version))
  result = call_608011.call(nil, query_608012, nil, formData_608013, nil)

var postPutAnomalyDetector* = Call_PostPutAnomalyDetector_607992(
    name: "postPutAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_PostPutAnomalyDetector_607993, base: "/",
    url: url_PostPutAnomalyDetector_607994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAnomalyDetector_607971 = ref object of OpenApiRestCall_606589
proc url_GetPutAnomalyDetector_607973(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutAnomalyDetector_607972(path: JsonNode; query: JsonNode;
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
  var valid_607974 = query.getOrDefault("Namespace")
  valid_607974 = validateParameter(valid_607974, JString, required = true,
                                 default = nil)
  if valid_607974 != nil:
    section.add "Namespace", valid_607974
  var valid_607975 = query.getOrDefault("Configuration.MetricTimezone")
  valid_607975 = validateParameter(valid_607975, JString, required = false,
                                 default = nil)
  if valid_607975 != nil:
    section.add "Configuration.MetricTimezone", valid_607975
  var valid_607976 = query.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_607976 = validateParameter(valid_607976, JArray, required = false,
                                 default = nil)
  if valid_607976 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_607976
  var valid_607977 = query.getOrDefault("Dimensions")
  valid_607977 = validateParameter(valid_607977, JArray, required = false,
                                 default = nil)
  if valid_607977 != nil:
    section.add "Dimensions", valid_607977
  var valid_607978 = query.getOrDefault("Action")
  valid_607978 = validateParameter(valid_607978, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_607978 != nil:
    section.add "Action", valid_607978
  var valid_607979 = query.getOrDefault("Version")
  valid_607979 = validateParameter(valid_607979, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_607979 != nil:
    section.add "Version", valid_607979
  var valid_607980 = query.getOrDefault("MetricName")
  valid_607980 = validateParameter(valid_607980, JString, required = true,
                                 default = nil)
  if valid_607980 != nil:
    section.add "MetricName", valid_607980
  var valid_607981 = query.getOrDefault("Stat")
  valid_607981 = validateParameter(valid_607981, JString, required = true,
                                 default = nil)
  if valid_607981 != nil:
    section.add "Stat", valid_607981
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
  var valid_607982 = header.getOrDefault("X-Amz-Signature")
  valid_607982 = validateParameter(valid_607982, JString, required = false,
                                 default = nil)
  if valid_607982 != nil:
    section.add "X-Amz-Signature", valid_607982
  var valid_607983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607983 = validateParameter(valid_607983, JString, required = false,
                                 default = nil)
  if valid_607983 != nil:
    section.add "X-Amz-Content-Sha256", valid_607983
  var valid_607984 = header.getOrDefault("X-Amz-Date")
  valid_607984 = validateParameter(valid_607984, JString, required = false,
                                 default = nil)
  if valid_607984 != nil:
    section.add "X-Amz-Date", valid_607984
  var valid_607985 = header.getOrDefault("X-Amz-Credential")
  valid_607985 = validateParameter(valid_607985, JString, required = false,
                                 default = nil)
  if valid_607985 != nil:
    section.add "X-Amz-Credential", valid_607985
  var valid_607986 = header.getOrDefault("X-Amz-Security-Token")
  valid_607986 = validateParameter(valid_607986, JString, required = false,
                                 default = nil)
  if valid_607986 != nil:
    section.add "X-Amz-Security-Token", valid_607986
  var valid_607987 = header.getOrDefault("X-Amz-Algorithm")
  valid_607987 = validateParameter(valid_607987, JString, required = false,
                                 default = nil)
  if valid_607987 != nil:
    section.add "X-Amz-Algorithm", valid_607987
  var valid_607988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607988 = validateParameter(valid_607988, JString, required = false,
                                 default = nil)
  if valid_607988 != nil:
    section.add "X-Amz-SignedHeaders", valid_607988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607989: Call_GetPutAnomalyDetector_607971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_607989.validator(path, query, header, formData, body)
  let scheme = call_607989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607989.url(scheme.get, call_607989.host, call_607989.base,
                         call_607989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607989, url, valid)

proc call*(call_607990: Call_GetPutAnomalyDetector_607971; Namespace: string;
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
  var query_607991 = newJObject()
  add(query_607991, "Namespace", newJString(Namespace))
  add(query_607991, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  if ConfigurationExcludedTimeRanges != nil:
    query_607991.add "Configuration.ExcludedTimeRanges",
                    ConfigurationExcludedTimeRanges
  if Dimensions != nil:
    query_607991.add "Dimensions", Dimensions
  add(query_607991, "Action", newJString(Action))
  add(query_607991, "Version", newJString(Version))
  add(query_607991, "MetricName", newJString(MetricName))
  add(query_607991, "Stat", newJString(Stat))
  result = call_607990.call(nil, query_607991, nil, nil, nil)

var getPutAnomalyDetector* = Call_GetPutAnomalyDetector_607971(
    name: "getPutAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_GetPutAnomalyDetector_607972, base: "/",
    url: url_GetPutAnomalyDetector_607973, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutDashboard_608031 = ref object of OpenApiRestCall_606589
proc url_PostPutDashboard_608033(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutDashboard_608032(path: JsonNode; query: JsonNode;
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
  var valid_608034 = query.getOrDefault("Action")
  valid_608034 = validateParameter(valid_608034, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_608034 != nil:
    section.add "Action", valid_608034
  var valid_608035 = query.getOrDefault("Version")
  valid_608035 = validateParameter(valid_608035, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608035 != nil:
    section.add "Version", valid_608035
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
  var valid_608036 = header.getOrDefault("X-Amz-Signature")
  valid_608036 = validateParameter(valid_608036, JString, required = false,
                                 default = nil)
  if valid_608036 != nil:
    section.add "X-Amz-Signature", valid_608036
  var valid_608037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608037 = validateParameter(valid_608037, JString, required = false,
                                 default = nil)
  if valid_608037 != nil:
    section.add "X-Amz-Content-Sha256", valid_608037
  var valid_608038 = header.getOrDefault("X-Amz-Date")
  valid_608038 = validateParameter(valid_608038, JString, required = false,
                                 default = nil)
  if valid_608038 != nil:
    section.add "X-Amz-Date", valid_608038
  var valid_608039 = header.getOrDefault("X-Amz-Credential")
  valid_608039 = validateParameter(valid_608039, JString, required = false,
                                 default = nil)
  if valid_608039 != nil:
    section.add "X-Amz-Credential", valid_608039
  var valid_608040 = header.getOrDefault("X-Amz-Security-Token")
  valid_608040 = validateParameter(valid_608040, JString, required = false,
                                 default = nil)
  if valid_608040 != nil:
    section.add "X-Amz-Security-Token", valid_608040
  var valid_608041 = header.getOrDefault("X-Amz-Algorithm")
  valid_608041 = validateParameter(valid_608041, JString, required = false,
                                 default = nil)
  if valid_608041 != nil:
    section.add "X-Amz-Algorithm", valid_608041
  var valid_608042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608042 = validateParameter(valid_608042, JString, required = false,
                                 default = nil)
  if valid_608042 != nil:
    section.add "X-Amz-SignedHeaders", valid_608042
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_608043 = formData.getOrDefault("DashboardName")
  valid_608043 = validateParameter(valid_608043, JString, required = true,
                                 default = nil)
  if valid_608043 != nil:
    section.add "DashboardName", valid_608043
  var valid_608044 = formData.getOrDefault("DashboardBody")
  valid_608044 = validateParameter(valid_608044, JString, required = true,
                                 default = nil)
  if valid_608044 != nil:
    section.add "DashboardBody", valid_608044
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608045: Call_PostPutDashboard_608031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_608045.validator(path, query, header, formData, body)
  let scheme = call_608045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608045.url(scheme.get, call_608045.host, call_608045.base,
                         call_608045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608045, url, valid)

proc call*(call_608046: Call_PostPutDashboard_608031; DashboardName: string;
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
  var query_608047 = newJObject()
  var formData_608048 = newJObject()
  add(formData_608048, "DashboardName", newJString(DashboardName))
  add(query_608047, "Action", newJString(Action))
  add(formData_608048, "DashboardBody", newJString(DashboardBody))
  add(query_608047, "Version", newJString(Version))
  result = call_608046.call(nil, query_608047, nil, formData_608048, nil)

var postPutDashboard* = Call_PostPutDashboard_608031(name: "postPutDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_PostPutDashboard_608032,
    base: "/", url: url_PostPutDashboard_608033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutDashboard_608014 = ref object of OpenApiRestCall_606589
proc url_GetPutDashboard_608016(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutDashboard_608015(path: JsonNode; query: JsonNode;
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
  var valid_608017 = query.getOrDefault("DashboardBody")
  valid_608017 = validateParameter(valid_608017, JString, required = true,
                                 default = nil)
  if valid_608017 != nil:
    section.add "DashboardBody", valid_608017
  var valid_608018 = query.getOrDefault("Action")
  valid_608018 = validateParameter(valid_608018, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_608018 != nil:
    section.add "Action", valid_608018
  var valid_608019 = query.getOrDefault("DashboardName")
  valid_608019 = validateParameter(valid_608019, JString, required = true,
                                 default = nil)
  if valid_608019 != nil:
    section.add "DashboardName", valid_608019
  var valid_608020 = query.getOrDefault("Version")
  valid_608020 = validateParameter(valid_608020, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608020 != nil:
    section.add "Version", valid_608020
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
  var valid_608021 = header.getOrDefault("X-Amz-Signature")
  valid_608021 = validateParameter(valid_608021, JString, required = false,
                                 default = nil)
  if valid_608021 != nil:
    section.add "X-Amz-Signature", valid_608021
  var valid_608022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608022 = validateParameter(valid_608022, JString, required = false,
                                 default = nil)
  if valid_608022 != nil:
    section.add "X-Amz-Content-Sha256", valid_608022
  var valid_608023 = header.getOrDefault("X-Amz-Date")
  valid_608023 = validateParameter(valid_608023, JString, required = false,
                                 default = nil)
  if valid_608023 != nil:
    section.add "X-Amz-Date", valid_608023
  var valid_608024 = header.getOrDefault("X-Amz-Credential")
  valid_608024 = validateParameter(valid_608024, JString, required = false,
                                 default = nil)
  if valid_608024 != nil:
    section.add "X-Amz-Credential", valid_608024
  var valid_608025 = header.getOrDefault("X-Amz-Security-Token")
  valid_608025 = validateParameter(valid_608025, JString, required = false,
                                 default = nil)
  if valid_608025 != nil:
    section.add "X-Amz-Security-Token", valid_608025
  var valid_608026 = header.getOrDefault("X-Amz-Algorithm")
  valid_608026 = validateParameter(valid_608026, JString, required = false,
                                 default = nil)
  if valid_608026 != nil:
    section.add "X-Amz-Algorithm", valid_608026
  var valid_608027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608027 = validateParameter(valid_608027, JString, required = false,
                                 default = nil)
  if valid_608027 != nil:
    section.add "X-Amz-SignedHeaders", valid_608027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608028: Call_GetPutDashboard_608014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_608028.validator(path, query, header, formData, body)
  let scheme = call_608028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608028.url(scheme.get, call_608028.host, call_608028.base,
                         call_608028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608028, url, valid)

proc call*(call_608029: Call_GetPutDashboard_608014; DashboardBody: string;
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
  var query_608030 = newJObject()
  add(query_608030, "DashboardBody", newJString(DashboardBody))
  add(query_608030, "Action", newJString(Action))
  add(query_608030, "DashboardName", newJString(DashboardName))
  add(query_608030, "Version", newJString(Version))
  result = call_608029.call(nil, query_608030, nil, nil, nil)

var getPutDashboard* = Call_GetPutDashboard_608014(name: "getPutDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_GetPutDashboard_608015,
    base: "/", url: url_GetPutDashboard_608016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutInsightRule_608067 = ref object of OpenApiRestCall_606589
proc url_PostPutInsightRule_608069(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutInsightRule_608068(path: JsonNode; query: JsonNode;
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
  var valid_608070 = query.getOrDefault("Action")
  valid_608070 = validateParameter(valid_608070, JString, required = true,
                                 default = newJString("PutInsightRule"))
  if valid_608070 != nil:
    section.add "Action", valid_608070
  var valid_608071 = query.getOrDefault("Version")
  valid_608071 = validateParameter(valid_608071, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608071 != nil:
    section.add "Version", valid_608071
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
  var valid_608072 = header.getOrDefault("X-Amz-Signature")
  valid_608072 = validateParameter(valid_608072, JString, required = false,
                                 default = nil)
  if valid_608072 != nil:
    section.add "X-Amz-Signature", valid_608072
  var valid_608073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608073 = validateParameter(valid_608073, JString, required = false,
                                 default = nil)
  if valid_608073 != nil:
    section.add "X-Amz-Content-Sha256", valid_608073
  var valid_608074 = header.getOrDefault("X-Amz-Date")
  valid_608074 = validateParameter(valid_608074, JString, required = false,
                                 default = nil)
  if valid_608074 != nil:
    section.add "X-Amz-Date", valid_608074
  var valid_608075 = header.getOrDefault("X-Amz-Credential")
  valid_608075 = validateParameter(valid_608075, JString, required = false,
                                 default = nil)
  if valid_608075 != nil:
    section.add "X-Amz-Credential", valid_608075
  var valid_608076 = header.getOrDefault("X-Amz-Security-Token")
  valid_608076 = validateParameter(valid_608076, JString, required = false,
                                 default = nil)
  if valid_608076 != nil:
    section.add "X-Amz-Security-Token", valid_608076
  var valid_608077 = header.getOrDefault("X-Amz-Algorithm")
  valid_608077 = validateParameter(valid_608077, JString, required = false,
                                 default = nil)
  if valid_608077 != nil:
    section.add "X-Amz-Algorithm", valid_608077
  var valid_608078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608078 = validateParameter(valid_608078, JString, required = false,
                                 default = nil)
  if valid_608078 != nil:
    section.add "X-Amz-SignedHeaders", valid_608078
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
  var valid_608079 = formData.getOrDefault("RuleName")
  valid_608079 = validateParameter(valid_608079, JString, required = true,
                                 default = nil)
  if valid_608079 != nil:
    section.add "RuleName", valid_608079
  var valid_608080 = formData.getOrDefault("RuleState")
  valid_608080 = validateParameter(valid_608080, JString, required = false,
                                 default = nil)
  if valid_608080 != nil:
    section.add "RuleState", valid_608080
  var valid_608081 = formData.getOrDefault("RuleDefinition")
  valid_608081 = validateParameter(valid_608081, JString, required = true,
                                 default = nil)
  if valid_608081 != nil:
    section.add "RuleDefinition", valid_608081
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608082: Call_PostPutInsightRule_608067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_608082.validator(path, query, header, formData, body)
  let scheme = call_608082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608082.url(scheme.get, call_608082.host, call_608082.base,
                         call_608082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608082, url, valid)

proc call*(call_608083: Call_PostPutInsightRule_608067; RuleName: string;
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
  var query_608084 = newJObject()
  var formData_608085 = newJObject()
  add(formData_608085, "RuleName", newJString(RuleName))
  add(formData_608085, "RuleState", newJString(RuleState))
  add(query_608084, "Action", newJString(Action))
  add(query_608084, "Version", newJString(Version))
  add(formData_608085, "RuleDefinition", newJString(RuleDefinition))
  result = call_608083.call(nil, query_608084, nil, formData_608085, nil)

var postPutInsightRule* = Call_PostPutInsightRule_608067(
    name: "postPutInsightRule", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutInsightRule",
    validator: validate_PostPutInsightRule_608068, base: "/",
    url: url_PostPutInsightRule_608069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutInsightRule_608049 = ref object of OpenApiRestCall_606589
proc url_GetPutInsightRule_608051(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutInsightRule_608050(path: JsonNode; query: JsonNode;
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
  var valid_608052 = query.getOrDefault("RuleName")
  valid_608052 = validateParameter(valid_608052, JString, required = true,
                                 default = nil)
  if valid_608052 != nil:
    section.add "RuleName", valid_608052
  var valid_608053 = query.getOrDefault("RuleDefinition")
  valid_608053 = validateParameter(valid_608053, JString, required = true,
                                 default = nil)
  if valid_608053 != nil:
    section.add "RuleDefinition", valid_608053
  var valid_608054 = query.getOrDefault("Action")
  valid_608054 = validateParameter(valid_608054, JString, required = true,
                                 default = newJString("PutInsightRule"))
  if valid_608054 != nil:
    section.add "Action", valid_608054
  var valid_608055 = query.getOrDefault("Version")
  valid_608055 = validateParameter(valid_608055, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608055 != nil:
    section.add "Version", valid_608055
  var valid_608056 = query.getOrDefault("RuleState")
  valid_608056 = validateParameter(valid_608056, JString, required = false,
                                 default = nil)
  if valid_608056 != nil:
    section.add "RuleState", valid_608056
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
  var valid_608057 = header.getOrDefault("X-Amz-Signature")
  valid_608057 = validateParameter(valid_608057, JString, required = false,
                                 default = nil)
  if valid_608057 != nil:
    section.add "X-Amz-Signature", valid_608057
  var valid_608058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608058 = validateParameter(valid_608058, JString, required = false,
                                 default = nil)
  if valid_608058 != nil:
    section.add "X-Amz-Content-Sha256", valid_608058
  var valid_608059 = header.getOrDefault("X-Amz-Date")
  valid_608059 = validateParameter(valid_608059, JString, required = false,
                                 default = nil)
  if valid_608059 != nil:
    section.add "X-Amz-Date", valid_608059
  var valid_608060 = header.getOrDefault("X-Amz-Credential")
  valid_608060 = validateParameter(valid_608060, JString, required = false,
                                 default = nil)
  if valid_608060 != nil:
    section.add "X-Amz-Credential", valid_608060
  var valid_608061 = header.getOrDefault("X-Amz-Security-Token")
  valid_608061 = validateParameter(valid_608061, JString, required = false,
                                 default = nil)
  if valid_608061 != nil:
    section.add "X-Amz-Security-Token", valid_608061
  var valid_608062 = header.getOrDefault("X-Amz-Algorithm")
  valid_608062 = validateParameter(valid_608062, JString, required = false,
                                 default = nil)
  if valid_608062 != nil:
    section.add "X-Amz-Algorithm", valid_608062
  var valid_608063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608063 = validateParameter(valid_608063, JString, required = false,
                                 default = nil)
  if valid_608063 != nil:
    section.add "X-Amz-SignedHeaders", valid_608063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608064: Call_GetPutInsightRule_608049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_608064.validator(path, query, header, formData, body)
  let scheme = call_608064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608064.url(scheme.get, call_608064.host, call_608064.base,
                         call_608064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608064, url, valid)

proc call*(call_608065: Call_GetPutInsightRule_608049; RuleName: string;
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
  var query_608066 = newJObject()
  add(query_608066, "RuleName", newJString(RuleName))
  add(query_608066, "RuleDefinition", newJString(RuleDefinition))
  add(query_608066, "Action", newJString(Action))
  add(query_608066, "Version", newJString(Version))
  add(query_608066, "RuleState", newJString(RuleState))
  result = call_608065.call(nil, query_608066, nil, nil, nil)

var getPutInsightRule* = Call_GetPutInsightRule_608049(name: "getPutInsightRule",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutInsightRule", validator: validate_GetPutInsightRule_608050,
    base: "/", url: url_GetPutInsightRule_608051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricAlarm_608123 = ref object of OpenApiRestCall_606589
proc url_PostPutMetricAlarm_608125(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutMetricAlarm_608124(path: JsonNode; query: JsonNode;
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
  var valid_608126 = query.getOrDefault("Action")
  valid_608126 = validateParameter(valid_608126, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_608126 != nil:
    section.add "Action", valid_608126
  var valid_608127 = query.getOrDefault("Version")
  valid_608127 = validateParameter(valid_608127, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608127 != nil:
    section.add "Version", valid_608127
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
  var valid_608128 = header.getOrDefault("X-Amz-Signature")
  valid_608128 = validateParameter(valid_608128, JString, required = false,
                                 default = nil)
  if valid_608128 != nil:
    section.add "X-Amz-Signature", valid_608128
  var valid_608129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608129 = validateParameter(valid_608129, JString, required = false,
                                 default = nil)
  if valid_608129 != nil:
    section.add "X-Amz-Content-Sha256", valid_608129
  var valid_608130 = header.getOrDefault("X-Amz-Date")
  valid_608130 = validateParameter(valid_608130, JString, required = false,
                                 default = nil)
  if valid_608130 != nil:
    section.add "X-Amz-Date", valid_608130
  var valid_608131 = header.getOrDefault("X-Amz-Credential")
  valid_608131 = validateParameter(valid_608131, JString, required = false,
                                 default = nil)
  if valid_608131 != nil:
    section.add "X-Amz-Credential", valid_608131
  var valid_608132 = header.getOrDefault("X-Amz-Security-Token")
  valid_608132 = validateParameter(valid_608132, JString, required = false,
                                 default = nil)
  if valid_608132 != nil:
    section.add "X-Amz-Security-Token", valid_608132
  var valid_608133 = header.getOrDefault("X-Amz-Algorithm")
  valid_608133 = validateParameter(valid_608133, JString, required = false,
                                 default = nil)
  if valid_608133 != nil:
    section.add "X-Amz-Algorithm", valid_608133
  var valid_608134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608134 = validateParameter(valid_608134, JString, required = false,
                                 default = nil)
  if valid_608134 != nil:
    section.add "X-Amz-SignedHeaders", valid_608134
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
  var valid_608135 = formData.getOrDefault("ActionsEnabled")
  valid_608135 = validateParameter(valid_608135, JBool, required = false, default = nil)
  if valid_608135 != nil:
    section.add "ActionsEnabled", valid_608135
  var valid_608136 = formData.getOrDefault("AlarmDescription")
  valid_608136 = validateParameter(valid_608136, JString, required = false,
                                 default = nil)
  if valid_608136 != nil:
    section.add "AlarmDescription", valid_608136
  assert formData != nil,
        "formData argument is necessary due to required `AlarmName` field"
  var valid_608137 = formData.getOrDefault("AlarmName")
  valid_608137 = validateParameter(valid_608137, JString, required = true,
                                 default = nil)
  if valid_608137 != nil:
    section.add "AlarmName", valid_608137
  var valid_608138 = formData.getOrDefault("ThresholdMetricId")
  valid_608138 = validateParameter(valid_608138, JString, required = false,
                                 default = nil)
  if valid_608138 != nil:
    section.add "ThresholdMetricId", valid_608138
  var valid_608139 = formData.getOrDefault("Unit")
  valid_608139 = validateParameter(valid_608139, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_608139 != nil:
    section.add "Unit", valid_608139
  var valid_608140 = formData.getOrDefault("Period")
  valid_608140 = validateParameter(valid_608140, JInt, required = false, default = nil)
  if valid_608140 != nil:
    section.add "Period", valid_608140
  var valid_608141 = formData.getOrDefault("AlarmActions")
  valid_608141 = validateParameter(valid_608141, JArray, required = false,
                                 default = nil)
  if valid_608141 != nil:
    section.add "AlarmActions", valid_608141
  var valid_608142 = formData.getOrDefault("ComparisonOperator")
  valid_608142 = validateParameter(valid_608142, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_608142 != nil:
    section.add "ComparisonOperator", valid_608142
  var valid_608143 = formData.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_608143 = validateParameter(valid_608143, JString, required = false,
                                 default = nil)
  if valid_608143 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_608143
  var valid_608144 = formData.getOrDefault("OKActions")
  valid_608144 = validateParameter(valid_608144, JArray, required = false,
                                 default = nil)
  if valid_608144 != nil:
    section.add "OKActions", valid_608144
  var valid_608145 = formData.getOrDefault("Statistic")
  valid_608145 = validateParameter(valid_608145, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_608145 != nil:
    section.add "Statistic", valid_608145
  var valid_608146 = formData.getOrDefault("TreatMissingData")
  valid_608146 = validateParameter(valid_608146, JString, required = false,
                                 default = nil)
  if valid_608146 != nil:
    section.add "TreatMissingData", valid_608146
  var valid_608147 = formData.getOrDefault("InsufficientDataActions")
  valid_608147 = validateParameter(valid_608147, JArray, required = false,
                                 default = nil)
  if valid_608147 != nil:
    section.add "InsufficientDataActions", valid_608147
  var valid_608148 = formData.getOrDefault("DatapointsToAlarm")
  valid_608148 = validateParameter(valid_608148, JInt, required = false, default = nil)
  if valid_608148 != nil:
    section.add "DatapointsToAlarm", valid_608148
  var valid_608149 = formData.getOrDefault("MetricName")
  valid_608149 = validateParameter(valid_608149, JString, required = false,
                                 default = nil)
  if valid_608149 != nil:
    section.add "MetricName", valid_608149
  var valid_608150 = formData.getOrDefault("Dimensions")
  valid_608150 = validateParameter(valid_608150, JArray, required = false,
                                 default = nil)
  if valid_608150 != nil:
    section.add "Dimensions", valid_608150
  var valid_608151 = formData.getOrDefault("Tags")
  valid_608151 = validateParameter(valid_608151, JArray, required = false,
                                 default = nil)
  if valid_608151 != nil:
    section.add "Tags", valid_608151
  var valid_608152 = formData.getOrDefault("Namespace")
  valid_608152 = validateParameter(valid_608152, JString, required = false,
                                 default = nil)
  if valid_608152 != nil:
    section.add "Namespace", valid_608152
  var valid_608153 = formData.getOrDefault("ExtendedStatistic")
  valid_608153 = validateParameter(valid_608153, JString, required = false,
                                 default = nil)
  if valid_608153 != nil:
    section.add "ExtendedStatistic", valid_608153
  var valid_608154 = formData.getOrDefault("EvaluationPeriods")
  valid_608154 = validateParameter(valid_608154, JInt, required = true, default = nil)
  if valid_608154 != nil:
    section.add "EvaluationPeriods", valid_608154
  var valid_608155 = formData.getOrDefault("Threshold")
  valid_608155 = validateParameter(valid_608155, JFloat, required = false,
                                 default = nil)
  if valid_608155 != nil:
    section.add "Threshold", valid_608155
  var valid_608156 = formData.getOrDefault("Metrics")
  valid_608156 = validateParameter(valid_608156, JArray, required = false,
                                 default = nil)
  if valid_608156 != nil:
    section.add "Metrics", valid_608156
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608157: Call_PostPutMetricAlarm_608123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_608157.validator(path, query, header, formData, body)
  let scheme = call_608157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608157.url(scheme.get, call_608157.host, call_608157.base,
                         call_608157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608157, url, valid)

proc call*(call_608158: Call_PostPutMetricAlarm_608123; AlarmName: string;
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
  var query_608159 = newJObject()
  var formData_608160 = newJObject()
  add(formData_608160, "ActionsEnabled", newJBool(ActionsEnabled))
  add(formData_608160, "AlarmDescription", newJString(AlarmDescription))
  add(formData_608160, "AlarmName", newJString(AlarmName))
  add(formData_608160, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(formData_608160, "Unit", newJString(Unit))
  add(formData_608160, "Period", newJInt(Period))
  if AlarmActions != nil:
    formData_608160.add "AlarmActions", AlarmActions
  add(formData_608160, "ComparisonOperator", newJString(ComparisonOperator))
  add(formData_608160, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  if OKActions != nil:
    formData_608160.add "OKActions", OKActions
  add(formData_608160, "Statistic", newJString(Statistic))
  add(formData_608160, "TreatMissingData", newJString(TreatMissingData))
  if InsufficientDataActions != nil:
    formData_608160.add "InsufficientDataActions", InsufficientDataActions
  add(formData_608160, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(formData_608160, "MetricName", newJString(MetricName))
  add(query_608159, "Action", newJString(Action))
  if Dimensions != nil:
    formData_608160.add "Dimensions", Dimensions
  if Tags != nil:
    formData_608160.add "Tags", Tags
  add(formData_608160, "Namespace", newJString(Namespace))
  add(formData_608160, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_608159, "Version", newJString(Version))
  add(formData_608160, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(formData_608160, "Threshold", newJFloat(Threshold))
  if Metrics != nil:
    formData_608160.add "Metrics", Metrics
  result = call_608158.call(nil, query_608159, nil, formData_608160, nil)

var postPutMetricAlarm* = Call_PostPutMetricAlarm_608123(
    name: "postPutMetricAlarm", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutMetricAlarm",
    validator: validate_PostPutMetricAlarm_608124, base: "/",
    url: url_PostPutMetricAlarm_608125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricAlarm_608086 = ref object of OpenApiRestCall_606589
proc url_GetPutMetricAlarm_608088(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutMetricAlarm_608087(path: JsonNode; query: JsonNode;
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
  var valid_608089 = query.getOrDefault("InsufficientDataActions")
  valid_608089 = validateParameter(valid_608089, JArray, required = false,
                                 default = nil)
  if valid_608089 != nil:
    section.add "InsufficientDataActions", valid_608089
  var valid_608090 = query.getOrDefault("Statistic")
  valid_608090 = validateParameter(valid_608090, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_608090 != nil:
    section.add "Statistic", valid_608090
  var valid_608091 = query.getOrDefault("AlarmDescription")
  valid_608091 = validateParameter(valid_608091, JString, required = false,
                                 default = nil)
  if valid_608091 != nil:
    section.add "AlarmDescription", valid_608091
  var valid_608092 = query.getOrDefault("Unit")
  valid_608092 = validateParameter(valid_608092, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_608092 != nil:
    section.add "Unit", valid_608092
  var valid_608093 = query.getOrDefault("DatapointsToAlarm")
  valid_608093 = validateParameter(valid_608093, JInt, required = false, default = nil)
  if valid_608093 != nil:
    section.add "DatapointsToAlarm", valid_608093
  var valid_608094 = query.getOrDefault("Threshold")
  valid_608094 = validateParameter(valid_608094, JFloat, required = false,
                                 default = nil)
  if valid_608094 != nil:
    section.add "Threshold", valid_608094
  var valid_608095 = query.getOrDefault("Tags")
  valid_608095 = validateParameter(valid_608095, JArray, required = false,
                                 default = nil)
  if valid_608095 != nil:
    section.add "Tags", valid_608095
  var valid_608096 = query.getOrDefault("ThresholdMetricId")
  valid_608096 = validateParameter(valid_608096, JString, required = false,
                                 default = nil)
  if valid_608096 != nil:
    section.add "ThresholdMetricId", valid_608096
  var valid_608097 = query.getOrDefault("Namespace")
  valid_608097 = validateParameter(valid_608097, JString, required = false,
                                 default = nil)
  if valid_608097 != nil:
    section.add "Namespace", valid_608097
  var valid_608098 = query.getOrDefault("TreatMissingData")
  valid_608098 = validateParameter(valid_608098, JString, required = false,
                                 default = nil)
  if valid_608098 != nil:
    section.add "TreatMissingData", valid_608098
  var valid_608099 = query.getOrDefault("ExtendedStatistic")
  valid_608099 = validateParameter(valid_608099, JString, required = false,
                                 default = nil)
  if valid_608099 != nil:
    section.add "ExtendedStatistic", valid_608099
  var valid_608100 = query.getOrDefault("OKActions")
  valid_608100 = validateParameter(valid_608100, JArray, required = false,
                                 default = nil)
  if valid_608100 != nil:
    section.add "OKActions", valid_608100
  var valid_608101 = query.getOrDefault("Dimensions")
  valid_608101 = validateParameter(valid_608101, JArray, required = false,
                                 default = nil)
  if valid_608101 != nil:
    section.add "Dimensions", valid_608101
  var valid_608102 = query.getOrDefault("Period")
  valid_608102 = validateParameter(valid_608102, JInt, required = false, default = nil)
  if valid_608102 != nil:
    section.add "Period", valid_608102
  assert query != nil,
        "query argument is necessary due to required `AlarmName` field"
  var valid_608103 = query.getOrDefault("AlarmName")
  valid_608103 = validateParameter(valid_608103, JString, required = true,
                                 default = nil)
  if valid_608103 != nil:
    section.add "AlarmName", valid_608103
  var valid_608104 = query.getOrDefault("Action")
  valid_608104 = validateParameter(valid_608104, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_608104 != nil:
    section.add "Action", valid_608104
  var valid_608105 = query.getOrDefault("EvaluationPeriods")
  valid_608105 = validateParameter(valid_608105, JInt, required = true, default = nil)
  if valid_608105 != nil:
    section.add "EvaluationPeriods", valid_608105
  var valid_608106 = query.getOrDefault("ActionsEnabled")
  valid_608106 = validateParameter(valid_608106, JBool, required = false, default = nil)
  if valid_608106 != nil:
    section.add "ActionsEnabled", valid_608106
  var valid_608107 = query.getOrDefault("ComparisonOperator")
  valid_608107 = validateParameter(valid_608107, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_608107 != nil:
    section.add "ComparisonOperator", valid_608107
  var valid_608108 = query.getOrDefault("AlarmActions")
  valid_608108 = validateParameter(valid_608108, JArray, required = false,
                                 default = nil)
  if valid_608108 != nil:
    section.add "AlarmActions", valid_608108
  var valid_608109 = query.getOrDefault("Metrics")
  valid_608109 = validateParameter(valid_608109, JArray, required = false,
                                 default = nil)
  if valid_608109 != nil:
    section.add "Metrics", valid_608109
  var valid_608110 = query.getOrDefault("Version")
  valid_608110 = validateParameter(valid_608110, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608110 != nil:
    section.add "Version", valid_608110
  var valid_608111 = query.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_608111 = validateParameter(valid_608111, JString, required = false,
                                 default = nil)
  if valid_608111 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_608111
  var valid_608112 = query.getOrDefault("MetricName")
  valid_608112 = validateParameter(valid_608112, JString, required = false,
                                 default = nil)
  if valid_608112 != nil:
    section.add "MetricName", valid_608112
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
  var valid_608113 = header.getOrDefault("X-Amz-Signature")
  valid_608113 = validateParameter(valid_608113, JString, required = false,
                                 default = nil)
  if valid_608113 != nil:
    section.add "X-Amz-Signature", valid_608113
  var valid_608114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608114 = validateParameter(valid_608114, JString, required = false,
                                 default = nil)
  if valid_608114 != nil:
    section.add "X-Amz-Content-Sha256", valid_608114
  var valid_608115 = header.getOrDefault("X-Amz-Date")
  valid_608115 = validateParameter(valid_608115, JString, required = false,
                                 default = nil)
  if valid_608115 != nil:
    section.add "X-Amz-Date", valid_608115
  var valid_608116 = header.getOrDefault("X-Amz-Credential")
  valid_608116 = validateParameter(valid_608116, JString, required = false,
                                 default = nil)
  if valid_608116 != nil:
    section.add "X-Amz-Credential", valid_608116
  var valid_608117 = header.getOrDefault("X-Amz-Security-Token")
  valid_608117 = validateParameter(valid_608117, JString, required = false,
                                 default = nil)
  if valid_608117 != nil:
    section.add "X-Amz-Security-Token", valid_608117
  var valid_608118 = header.getOrDefault("X-Amz-Algorithm")
  valid_608118 = validateParameter(valid_608118, JString, required = false,
                                 default = nil)
  if valid_608118 != nil:
    section.add "X-Amz-Algorithm", valid_608118
  var valid_608119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608119 = validateParameter(valid_608119, JString, required = false,
                                 default = nil)
  if valid_608119 != nil:
    section.add "X-Amz-SignedHeaders", valid_608119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608120: Call_GetPutMetricAlarm_608086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_608120.validator(path, query, header, formData, body)
  let scheme = call_608120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608120.url(scheme.get, call_608120.host, call_608120.base,
                         call_608120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608120, url, valid)

proc call*(call_608121: Call_GetPutMetricAlarm_608086; AlarmName: string;
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
  var query_608122 = newJObject()
  if InsufficientDataActions != nil:
    query_608122.add "InsufficientDataActions", InsufficientDataActions
  add(query_608122, "Statistic", newJString(Statistic))
  add(query_608122, "AlarmDescription", newJString(AlarmDescription))
  add(query_608122, "Unit", newJString(Unit))
  add(query_608122, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(query_608122, "Threshold", newJFloat(Threshold))
  if Tags != nil:
    query_608122.add "Tags", Tags
  add(query_608122, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_608122, "Namespace", newJString(Namespace))
  add(query_608122, "TreatMissingData", newJString(TreatMissingData))
  add(query_608122, "ExtendedStatistic", newJString(ExtendedStatistic))
  if OKActions != nil:
    query_608122.add "OKActions", OKActions
  if Dimensions != nil:
    query_608122.add "Dimensions", Dimensions
  add(query_608122, "Period", newJInt(Period))
  add(query_608122, "AlarmName", newJString(AlarmName))
  add(query_608122, "Action", newJString(Action))
  add(query_608122, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(query_608122, "ActionsEnabled", newJBool(ActionsEnabled))
  add(query_608122, "ComparisonOperator", newJString(ComparisonOperator))
  if AlarmActions != nil:
    query_608122.add "AlarmActions", AlarmActions
  if Metrics != nil:
    query_608122.add "Metrics", Metrics
  add(query_608122, "Version", newJString(Version))
  add(query_608122, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  add(query_608122, "MetricName", newJString(MetricName))
  result = call_608121.call(nil, query_608122, nil, nil, nil)

var getPutMetricAlarm* = Call_GetPutMetricAlarm_608086(name: "getPutMetricAlarm",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricAlarm", validator: validate_GetPutMetricAlarm_608087,
    base: "/", url: url_GetPutMetricAlarm_608088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricData_608178 = ref object of OpenApiRestCall_606589
proc url_PostPutMetricData_608180(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutMetricData_608179(path: JsonNode; query: JsonNode;
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
  var valid_608181 = query.getOrDefault("Action")
  valid_608181 = validateParameter(valid_608181, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_608181 != nil:
    section.add "Action", valid_608181
  var valid_608182 = query.getOrDefault("Version")
  valid_608182 = validateParameter(valid_608182, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608182 != nil:
    section.add "Version", valid_608182
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
  var valid_608183 = header.getOrDefault("X-Amz-Signature")
  valid_608183 = validateParameter(valid_608183, JString, required = false,
                                 default = nil)
  if valid_608183 != nil:
    section.add "X-Amz-Signature", valid_608183
  var valid_608184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608184 = validateParameter(valid_608184, JString, required = false,
                                 default = nil)
  if valid_608184 != nil:
    section.add "X-Amz-Content-Sha256", valid_608184
  var valid_608185 = header.getOrDefault("X-Amz-Date")
  valid_608185 = validateParameter(valid_608185, JString, required = false,
                                 default = nil)
  if valid_608185 != nil:
    section.add "X-Amz-Date", valid_608185
  var valid_608186 = header.getOrDefault("X-Amz-Credential")
  valid_608186 = validateParameter(valid_608186, JString, required = false,
                                 default = nil)
  if valid_608186 != nil:
    section.add "X-Amz-Credential", valid_608186
  var valid_608187 = header.getOrDefault("X-Amz-Security-Token")
  valid_608187 = validateParameter(valid_608187, JString, required = false,
                                 default = nil)
  if valid_608187 != nil:
    section.add "X-Amz-Security-Token", valid_608187
  var valid_608188 = header.getOrDefault("X-Amz-Algorithm")
  valid_608188 = validateParameter(valid_608188, JString, required = false,
                                 default = nil)
  if valid_608188 != nil:
    section.add "X-Amz-Algorithm", valid_608188
  var valid_608189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608189 = validateParameter(valid_608189, JString, required = false,
                                 default = nil)
  if valid_608189 != nil:
    section.add "X-Amz-SignedHeaders", valid_608189
  result.add "header", section
  ## parameters in `formData` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Namespace` field"
  var valid_608190 = formData.getOrDefault("Namespace")
  valid_608190 = validateParameter(valid_608190, JString, required = true,
                                 default = nil)
  if valid_608190 != nil:
    section.add "Namespace", valid_608190
  var valid_608191 = formData.getOrDefault("MetricData")
  valid_608191 = validateParameter(valid_608191, JArray, required = true, default = nil)
  if valid_608191 != nil:
    section.add "MetricData", valid_608191
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608192: Call_PostPutMetricData_608178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_608192.validator(path, query, header, formData, body)
  let scheme = call_608192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608192.url(scheme.get, call_608192.host, call_608192.base,
                         call_608192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608192, url, valid)

proc call*(call_608193: Call_PostPutMetricData_608178; Namespace: string;
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
  var query_608194 = newJObject()
  var formData_608195 = newJObject()
  add(query_608194, "Action", newJString(Action))
  add(formData_608195, "Namespace", newJString(Namespace))
  if MetricData != nil:
    formData_608195.add "MetricData", MetricData
  add(query_608194, "Version", newJString(Version))
  result = call_608193.call(nil, query_608194, nil, formData_608195, nil)

var postPutMetricData* = Call_PostPutMetricData_608178(name: "postPutMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_PostPutMetricData_608179,
    base: "/", url: url_PostPutMetricData_608180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricData_608161 = ref object of OpenApiRestCall_606589
proc url_GetPutMetricData_608163(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutMetricData_608162(path: JsonNode; query: JsonNode;
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
  var valid_608164 = query.getOrDefault("Namespace")
  valid_608164 = validateParameter(valid_608164, JString, required = true,
                                 default = nil)
  if valid_608164 != nil:
    section.add "Namespace", valid_608164
  var valid_608165 = query.getOrDefault("Action")
  valid_608165 = validateParameter(valid_608165, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_608165 != nil:
    section.add "Action", valid_608165
  var valid_608166 = query.getOrDefault("Version")
  valid_608166 = validateParameter(valid_608166, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608166 != nil:
    section.add "Version", valid_608166
  var valid_608167 = query.getOrDefault("MetricData")
  valid_608167 = validateParameter(valid_608167, JArray, required = true, default = nil)
  if valid_608167 != nil:
    section.add "MetricData", valid_608167
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
  var valid_608168 = header.getOrDefault("X-Amz-Signature")
  valid_608168 = validateParameter(valid_608168, JString, required = false,
                                 default = nil)
  if valid_608168 != nil:
    section.add "X-Amz-Signature", valid_608168
  var valid_608169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608169 = validateParameter(valid_608169, JString, required = false,
                                 default = nil)
  if valid_608169 != nil:
    section.add "X-Amz-Content-Sha256", valid_608169
  var valid_608170 = header.getOrDefault("X-Amz-Date")
  valid_608170 = validateParameter(valid_608170, JString, required = false,
                                 default = nil)
  if valid_608170 != nil:
    section.add "X-Amz-Date", valid_608170
  var valid_608171 = header.getOrDefault("X-Amz-Credential")
  valid_608171 = validateParameter(valid_608171, JString, required = false,
                                 default = nil)
  if valid_608171 != nil:
    section.add "X-Amz-Credential", valid_608171
  var valid_608172 = header.getOrDefault("X-Amz-Security-Token")
  valid_608172 = validateParameter(valid_608172, JString, required = false,
                                 default = nil)
  if valid_608172 != nil:
    section.add "X-Amz-Security-Token", valid_608172
  var valid_608173 = header.getOrDefault("X-Amz-Algorithm")
  valid_608173 = validateParameter(valid_608173, JString, required = false,
                                 default = nil)
  if valid_608173 != nil:
    section.add "X-Amz-Algorithm", valid_608173
  var valid_608174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608174 = validateParameter(valid_608174, JString, required = false,
                                 default = nil)
  if valid_608174 != nil:
    section.add "X-Amz-SignedHeaders", valid_608174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608175: Call_GetPutMetricData_608161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_608175.validator(path, query, header, formData, body)
  let scheme = call_608175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608175.url(scheme.get, call_608175.host, call_608175.base,
                         call_608175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608175, url, valid)

proc call*(call_608176: Call_GetPutMetricData_608161; Namespace: string;
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
  var query_608177 = newJObject()
  add(query_608177, "Namespace", newJString(Namespace))
  add(query_608177, "Action", newJString(Action))
  add(query_608177, "Version", newJString(Version))
  if MetricData != nil:
    query_608177.add "MetricData", MetricData
  result = call_608176.call(nil, query_608177, nil, nil, nil)

var getPutMetricData* = Call_GetPutMetricData_608161(name: "getPutMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_GetPutMetricData_608162,
    base: "/", url: url_GetPutMetricData_608163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetAlarmState_608215 = ref object of OpenApiRestCall_606589
proc url_PostSetAlarmState_608217(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetAlarmState_608216(path: JsonNode; query: JsonNode;
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
  var valid_608218 = query.getOrDefault("Action")
  valid_608218 = validateParameter(valid_608218, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_608218 != nil:
    section.add "Action", valid_608218
  var valid_608219 = query.getOrDefault("Version")
  valid_608219 = validateParameter(valid_608219, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608219 != nil:
    section.add "Version", valid_608219
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
  var valid_608220 = header.getOrDefault("X-Amz-Signature")
  valid_608220 = validateParameter(valid_608220, JString, required = false,
                                 default = nil)
  if valid_608220 != nil:
    section.add "X-Amz-Signature", valid_608220
  var valid_608221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608221 = validateParameter(valid_608221, JString, required = false,
                                 default = nil)
  if valid_608221 != nil:
    section.add "X-Amz-Content-Sha256", valid_608221
  var valid_608222 = header.getOrDefault("X-Amz-Date")
  valid_608222 = validateParameter(valid_608222, JString, required = false,
                                 default = nil)
  if valid_608222 != nil:
    section.add "X-Amz-Date", valid_608222
  var valid_608223 = header.getOrDefault("X-Amz-Credential")
  valid_608223 = validateParameter(valid_608223, JString, required = false,
                                 default = nil)
  if valid_608223 != nil:
    section.add "X-Amz-Credential", valid_608223
  var valid_608224 = header.getOrDefault("X-Amz-Security-Token")
  valid_608224 = validateParameter(valid_608224, JString, required = false,
                                 default = nil)
  if valid_608224 != nil:
    section.add "X-Amz-Security-Token", valid_608224
  var valid_608225 = header.getOrDefault("X-Amz-Algorithm")
  valid_608225 = validateParameter(valid_608225, JString, required = false,
                                 default = nil)
  if valid_608225 != nil:
    section.add "X-Amz-Algorithm", valid_608225
  var valid_608226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608226 = validateParameter(valid_608226, JString, required = false,
                                 default = nil)
  if valid_608226 != nil:
    section.add "X-Amz-SignedHeaders", valid_608226
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
  var valid_608227 = formData.getOrDefault("AlarmName")
  valid_608227 = validateParameter(valid_608227, JString, required = true,
                                 default = nil)
  if valid_608227 != nil:
    section.add "AlarmName", valid_608227
  var valid_608228 = formData.getOrDefault("StateValue")
  valid_608228 = validateParameter(valid_608228, JString, required = true,
                                 default = newJString("OK"))
  if valid_608228 != nil:
    section.add "StateValue", valid_608228
  var valid_608229 = formData.getOrDefault("StateReason")
  valid_608229 = validateParameter(valid_608229, JString, required = true,
                                 default = nil)
  if valid_608229 != nil:
    section.add "StateReason", valid_608229
  var valid_608230 = formData.getOrDefault("StateReasonData")
  valid_608230 = validateParameter(valid_608230, JString, required = false,
                                 default = nil)
  if valid_608230 != nil:
    section.add "StateReasonData", valid_608230
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608231: Call_PostSetAlarmState_608215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_608231.validator(path, query, header, formData, body)
  let scheme = call_608231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608231.url(scheme.get, call_608231.host, call_608231.base,
                         call_608231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608231, url, valid)

proc call*(call_608232: Call_PostSetAlarmState_608215; AlarmName: string;
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
  var query_608233 = newJObject()
  var formData_608234 = newJObject()
  add(formData_608234, "AlarmName", newJString(AlarmName))
  add(formData_608234, "StateValue", newJString(StateValue))
  add(formData_608234, "StateReason", newJString(StateReason))
  add(formData_608234, "StateReasonData", newJString(StateReasonData))
  add(query_608233, "Action", newJString(Action))
  add(query_608233, "Version", newJString(Version))
  result = call_608232.call(nil, query_608233, nil, formData_608234, nil)

var postSetAlarmState* = Call_PostSetAlarmState_608215(name: "postSetAlarmState",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_PostSetAlarmState_608216,
    base: "/", url: url_PostSetAlarmState_608217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetAlarmState_608196 = ref object of OpenApiRestCall_606589
proc url_GetSetAlarmState_608198(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetAlarmState_608197(path: JsonNode; query: JsonNode;
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
  var valid_608199 = query.getOrDefault("StateReason")
  valid_608199 = validateParameter(valid_608199, JString, required = true,
                                 default = nil)
  if valid_608199 != nil:
    section.add "StateReason", valid_608199
  var valid_608200 = query.getOrDefault("StateValue")
  valid_608200 = validateParameter(valid_608200, JString, required = true,
                                 default = newJString("OK"))
  if valid_608200 != nil:
    section.add "StateValue", valid_608200
  var valid_608201 = query.getOrDefault("Action")
  valid_608201 = validateParameter(valid_608201, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_608201 != nil:
    section.add "Action", valid_608201
  var valid_608202 = query.getOrDefault("AlarmName")
  valid_608202 = validateParameter(valid_608202, JString, required = true,
                                 default = nil)
  if valid_608202 != nil:
    section.add "AlarmName", valid_608202
  var valid_608203 = query.getOrDefault("StateReasonData")
  valid_608203 = validateParameter(valid_608203, JString, required = false,
                                 default = nil)
  if valid_608203 != nil:
    section.add "StateReasonData", valid_608203
  var valid_608204 = query.getOrDefault("Version")
  valid_608204 = validateParameter(valid_608204, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608204 != nil:
    section.add "Version", valid_608204
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
  var valid_608205 = header.getOrDefault("X-Amz-Signature")
  valid_608205 = validateParameter(valid_608205, JString, required = false,
                                 default = nil)
  if valid_608205 != nil:
    section.add "X-Amz-Signature", valid_608205
  var valid_608206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608206 = validateParameter(valid_608206, JString, required = false,
                                 default = nil)
  if valid_608206 != nil:
    section.add "X-Amz-Content-Sha256", valid_608206
  var valid_608207 = header.getOrDefault("X-Amz-Date")
  valid_608207 = validateParameter(valid_608207, JString, required = false,
                                 default = nil)
  if valid_608207 != nil:
    section.add "X-Amz-Date", valid_608207
  var valid_608208 = header.getOrDefault("X-Amz-Credential")
  valid_608208 = validateParameter(valid_608208, JString, required = false,
                                 default = nil)
  if valid_608208 != nil:
    section.add "X-Amz-Credential", valid_608208
  var valid_608209 = header.getOrDefault("X-Amz-Security-Token")
  valid_608209 = validateParameter(valid_608209, JString, required = false,
                                 default = nil)
  if valid_608209 != nil:
    section.add "X-Amz-Security-Token", valid_608209
  var valid_608210 = header.getOrDefault("X-Amz-Algorithm")
  valid_608210 = validateParameter(valid_608210, JString, required = false,
                                 default = nil)
  if valid_608210 != nil:
    section.add "X-Amz-Algorithm", valid_608210
  var valid_608211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608211 = validateParameter(valid_608211, JString, required = false,
                                 default = nil)
  if valid_608211 != nil:
    section.add "X-Amz-SignedHeaders", valid_608211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608212: Call_GetSetAlarmState_608196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_608212.validator(path, query, header, formData, body)
  let scheme = call_608212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608212.url(scheme.get, call_608212.host, call_608212.base,
                         call_608212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608212, url, valid)

proc call*(call_608213: Call_GetSetAlarmState_608196; StateReason: string;
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
  var query_608214 = newJObject()
  add(query_608214, "StateReason", newJString(StateReason))
  add(query_608214, "StateValue", newJString(StateValue))
  add(query_608214, "Action", newJString(Action))
  add(query_608214, "AlarmName", newJString(AlarmName))
  add(query_608214, "StateReasonData", newJString(StateReasonData))
  add(query_608214, "Version", newJString(Version))
  result = call_608213.call(nil, query_608214, nil, nil, nil)

var getSetAlarmState* = Call_GetSetAlarmState_608196(name: "getSetAlarmState",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_GetSetAlarmState_608197,
    base: "/", url: url_GetSetAlarmState_608198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_608252 = ref object of OpenApiRestCall_606589
proc url_PostTagResource_608254(protocol: Scheme; host: string; base: string;
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

proc validate_PostTagResource_608253(path: JsonNode; query: JsonNode;
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
  var valid_608255 = query.getOrDefault("Action")
  valid_608255 = validateParameter(valid_608255, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_608255 != nil:
    section.add "Action", valid_608255
  var valid_608256 = query.getOrDefault("Version")
  valid_608256 = validateParameter(valid_608256, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608256 != nil:
    section.add "Version", valid_608256
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
  var valid_608257 = header.getOrDefault("X-Amz-Signature")
  valid_608257 = validateParameter(valid_608257, JString, required = false,
                                 default = nil)
  if valid_608257 != nil:
    section.add "X-Amz-Signature", valid_608257
  var valid_608258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608258 = validateParameter(valid_608258, JString, required = false,
                                 default = nil)
  if valid_608258 != nil:
    section.add "X-Amz-Content-Sha256", valid_608258
  var valid_608259 = header.getOrDefault("X-Amz-Date")
  valid_608259 = validateParameter(valid_608259, JString, required = false,
                                 default = nil)
  if valid_608259 != nil:
    section.add "X-Amz-Date", valid_608259
  var valid_608260 = header.getOrDefault("X-Amz-Credential")
  valid_608260 = validateParameter(valid_608260, JString, required = false,
                                 default = nil)
  if valid_608260 != nil:
    section.add "X-Amz-Credential", valid_608260
  var valid_608261 = header.getOrDefault("X-Amz-Security-Token")
  valid_608261 = validateParameter(valid_608261, JString, required = false,
                                 default = nil)
  if valid_608261 != nil:
    section.add "X-Amz-Security-Token", valid_608261
  var valid_608262 = header.getOrDefault("X-Amz-Algorithm")
  valid_608262 = validateParameter(valid_608262, JString, required = false,
                                 default = nil)
  if valid_608262 != nil:
    section.add "X-Amz-Algorithm", valid_608262
  var valid_608263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608263 = validateParameter(valid_608263, JString, required = false,
                                 default = nil)
  if valid_608263 != nil:
    section.add "X-Amz-SignedHeaders", valid_608263
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
  var valid_608264 = formData.getOrDefault("Tags")
  valid_608264 = validateParameter(valid_608264, JArray, required = true, default = nil)
  if valid_608264 != nil:
    section.add "Tags", valid_608264
  var valid_608265 = formData.getOrDefault("ResourceARN")
  valid_608265 = validateParameter(valid_608265, JString, required = true,
                                 default = nil)
  if valid_608265 != nil:
    section.add "ResourceARN", valid_608265
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608266: Call_PostTagResource_608252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_608266.validator(path, query, header, formData, body)
  let scheme = call_608266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608266.url(scheme.get, call_608266.host, call_608266.base,
                         call_608266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608266, url, valid)

proc call*(call_608267: Call_PostTagResource_608252; Tags: JsonNode;
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
  var query_608268 = newJObject()
  var formData_608269 = newJObject()
  add(query_608268, "Action", newJString(Action))
  if Tags != nil:
    formData_608269.add "Tags", Tags
  add(query_608268, "Version", newJString(Version))
  add(formData_608269, "ResourceARN", newJString(ResourceARN))
  result = call_608267.call(nil, query_608268, nil, formData_608269, nil)

var postTagResource* = Call_PostTagResource_608252(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_608253,
    base: "/", url: url_PostTagResource_608254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_608235 = ref object of OpenApiRestCall_606589
proc url_GetTagResource_608237(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagResource_608236(path: JsonNode; query: JsonNode;
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
  var valid_608238 = query.getOrDefault("Tags")
  valid_608238 = validateParameter(valid_608238, JArray, required = true, default = nil)
  if valid_608238 != nil:
    section.add "Tags", valid_608238
  var valid_608239 = query.getOrDefault("Action")
  valid_608239 = validateParameter(valid_608239, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_608239 != nil:
    section.add "Action", valid_608239
  var valid_608240 = query.getOrDefault("ResourceARN")
  valid_608240 = validateParameter(valid_608240, JString, required = true,
                                 default = nil)
  if valid_608240 != nil:
    section.add "ResourceARN", valid_608240
  var valid_608241 = query.getOrDefault("Version")
  valid_608241 = validateParameter(valid_608241, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608241 != nil:
    section.add "Version", valid_608241
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
  var valid_608242 = header.getOrDefault("X-Amz-Signature")
  valid_608242 = validateParameter(valid_608242, JString, required = false,
                                 default = nil)
  if valid_608242 != nil:
    section.add "X-Amz-Signature", valid_608242
  var valid_608243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608243 = validateParameter(valid_608243, JString, required = false,
                                 default = nil)
  if valid_608243 != nil:
    section.add "X-Amz-Content-Sha256", valid_608243
  var valid_608244 = header.getOrDefault("X-Amz-Date")
  valid_608244 = validateParameter(valid_608244, JString, required = false,
                                 default = nil)
  if valid_608244 != nil:
    section.add "X-Amz-Date", valid_608244
  var valid_608245 = header.getOrDefault("X-Amz-Credential")
  valid_608245 = validateParameter(valid_608245, JString, required = false,
                                 default = nil)
  if valid_608245 != nil:
    section.add "X-Amz-Credential", valid_608245
  var valid_608246 = header.getOrDefault("X-Amz-Security-Token")
  valid_608246 = validateParameter(valid_608246, JString, required = false,
                                 default = nil)
  if valid_608246 != nil:
    section.add "X-Amz-Security-Token", valid_608246
  var valid_608247 = header.getOrDefault("X-Amz-Algorithm")
  valid_608247 = validateParameter(valid_608247, JString, required = false,
                                 default = nil)
  if valid_608247 != nil:
    section.add "X-Amz-Algorithm", valid_608247
  var valid_608248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608248 = validateParameter(valid_608248, JString, required = false,
                                 default = nil)
  if valid_608248 != nil:
    section.add "X-Amz-SignedHeaders", valid_608248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608249: Call_GetTagResource_608235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_608249.validator(path, query, header, formData, body)
  let scheme = call_608249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608249.url(scheme.get, call_608249.host, call_608249.base,
                         call_608249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608249, url, valid)

proc call*(call_608250: Call_GetTagResource_608235; Tags: JsonNode;
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
  var query_608251 = newJObject()
  if Tags != nil:
    query_608251.add "Tags", Tags
  add(query_608251, "Action", newJString(Action))
  add(query_608251, "ResourceARN", newJString(ResourceARN))
  add(query_608251, "Version", newJString(Version))
  result = call_608250.call(nil, query_608251, nil, nil, nil)

var getTagResource* = Call_GetTagResource_608235(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_608236,
    base: "/", url: url_GetTagResource_608237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_608287 = ref object of OpenApiRestCall_606589
proc url_PostUntagResource_608289(protocol: Scheme; host: string; base: string;
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

proc validate_PostUntagResource_608288(path: JsonNode; query: JsonNode;
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
  var valid_608290 = query.getOrDefault("Action")
  valid_608290 = validateParameter(valid_608290, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_608290 != nil:
    section.add "Action", valid_608290
  var valid_608291 = query.getOrDefault("Version")
  valid_608291 = validateParameter(valid_608291, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608291 != nil:
    section.add "Version", valid_608291
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
  var valid_608292 = header.getOrDefault("X-Amz-Signature")
  valid_608292 = validateParameter(valid_608292, JString, required = false,
                                 default = nil)
  if valid_608292 != nil:
    section.add "X-Amz-Signature", valid_608292
  var valid_608293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608293 = validateParameter(valid_608293, JString, required = false,
                                 default = nil)
  if valid_608293 != nil:
    section.add "X-Amz-Content-Sha256", valid_608293
  var valid_608294 = header.getOrDefault("X-Amz-Date")
  valid_608294 = validateParameter(valid_608294, JString, required = false,
                                 default = nil)
  if valid_608294 != nil:
    section.add "X-Amz-Date", valid_608294
  var valid_608295 = header.getOrDefault("X-Amz-Credential")
  valid_608295 = validateParameter(valid_608295, JString, required = false,
                                 default = nil)
  if valid_608295 != nil:
    section.add "X-Amz-Credential", valid_608295
  var valid_608296 = header.getOrDefault("X-Amz-Security-Token")
  valid_608296 = validateParameter(valid_608296, JString, required = false,
                                 default = nil)
  if valid_608296 != nil:
    section.add "X-Amz-Security-Token", valid_608296
  var valid_608297 = header.getOrDefault("X-Amz-Algorithm")
  valid_608297 = validateParameter(valid_608297, JString, required = false,
                                 default = nil)
  if valid_608297 != nil:
    section.add "X-Amz-Algorithm", valid_608297
  var valid_608298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608298 = validateParameter(valid_608298, JString, required = false,
                                 default = nil)
  if valid_608298 != nil:
    section.add "X-Amz-SignedHeaders", valid_608298
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
  var valid_608299 = formData.getOrDefault("TagKeys")
  valid_608299 = validateParameter(valid_608299, JArray, required = true, default = nil)
  if valid_608299 != nil:
    section.add "TagKeys", valid_608299
  var valid_608300 = formData.getOrDefault("ResourceARN")
  valid_608300 = validateParameter(valid_608300, JString, required = true,
                                 default = nil)
  if valid_608300 != nil:
    section.add "ResourceARN", valid_608300
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608301: Call_PostUntagResource_608287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_608301.validator(path, query, header, formData, body)
  let scheme = call_608301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608301.url(scheme.get, call_608301.host, call_608301.base,
                         call_608301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608301, url, valid)

proc call*(call_608302: Call_PostUntagResource_608287; TagKeys: JsonNode;
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
  var query_608303 = newJObject()
  var formData_608304 = newJObject()
  if TagKeys != nil:
    formData_608304.add "TagKeys", TagKeys
  add(query_608303, "Action", newJString(Action))
  add(query_608303, "Version", newJString(Version))
  add(formData_608304, "ResourceARN", newJString(ResourceARN))
  result = call_608302.call(nil, query_608303, nil, formData_608304, nil)

var postUntagResource* = Call_PostUntagResource_608287(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_608288,
    base: "/", url: url_PostUntagResource_608289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_608270 = ref object of OpenApiRestCall_606589
proc url_GetUntagResource_608272(protocol: Scheme; host: string; base: string;
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

proc validate_GetUntagResource_608271(path: JsonNode; query: JsonNode;
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
  var valid_608273 = query.getOrDefault("TagKeys")
  valid_608273 = validateParameter(valid_608273, JArray, required = true, default = nil)
  if valid_608273 != nil:
    section.add "TagKeys", valid_608273
  var valid_608274 = query.getOrDefault("Action")
  valid_608274 = validateParameter(valid_608274, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_608274 != nil:
    section.add "Action", valid_608274
  var valid_608275 = query.getOrDefault("ResourceARN")
  valid_608275 = validateParameter(valid_608275, JString, required = true,
                                 default = nil)
  if valid_608275 != nil:
    section.add "ResourceARN", valid_608275
  var valid_608276 = query.getOrDefault("Version")
  valid_608276 = validateParameter(valid_608276, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_608276 != nil:
    section.add "Version", valid_608276
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
  var valid_608277 = header.getOrDefault("X-Amz-Signature")
  valid_608277 = validateParameter(valid_608277, JString, required = false,
                                 default = nil)
  if valid_608277 != nil:
    section.add "X-Amz-Signature", valid_608277
  var valid_608278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608278 = validateParameter(valid_608278, JString, required = false,
                                 default = nil)
  if valid_608278 != nil:
    section.add "X-Amz-Content-Sha256", valid_608278
  var valid_608279 = header.getOrDefault("X-Amz-Date")
  valid_608279 = validateParameter(valid_608279, JString, required = false,
                                 default = nil)
  if valid_608279 != nil:
    section.add "X-Amz-Date", valid_608279
  var valid_608280 = header.getOrDefault("X-Amz-Credential")
  valid_608280 = validateParameter(valid_608280, JString, required = false,
                                 default = nil)
  if valid_608280 != nil:
    section.add "X-Amz-Credential", valid_608280
  var valid_608281 = header.getOrDefault("X-Amz-Security-Token")
  valid_608281 = validateParameter(valid_608281, JString, required = false,
                                 default = nil)
  if valid_608281 != nil:
    section.add "X-Amz-Security-Token", valid_608281
  var valid_608282 = header.getOrDefault("X-Amz-Algorithm")
  valid_608282 = validateParameter(valid_608282, JString, required = false,
                                 default = nil)
  if valid_608282 != nil:
    section.add "X-Amz-Algorithm", valid_608282
  var valid_608283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608283 = validateParameter(valid_608283, JString, required = false,
                                 default = nil)
  if valid_608283 != nil:
    section.add "X-Amz-SignedHeaders", valid_608283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608284: Call_GetUntagResource_608270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_608284.validator(path, query, header, formData, body)
  let scheme = call_608284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608284.url(scheme.get, call_608284.host, call_608284.base,
                         call_608284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608284, url, valid)

proc call*(call_608285: Call_GetUntagResource_608270; TagKeys: JsonNode;
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
  var query_608286 = newJObject()
  if TagKeys != nil:
    query_608286.add "TagKeys", TagKeys
  add(query_608286, "Action", newJString(Action))
  add(query_608286, "ResourceARN", newJString(ResourceARN))
  add(query_608286, "Version", newJString(Version))
  result = call_608285.call(nil, query_608286, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_608270(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_608271,
    base: "/", url: url_GetUntagResource_608272,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
