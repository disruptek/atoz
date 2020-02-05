
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_PostDeleteAlarms_613267 = ref object of OpenApiRestCall_612658
proc url_PostDeleteAlarms_613269(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteAlarms_613268(path: JsonNode; query: JsonNode;
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
  var valid_613270 = query.getOrDefault("Action")
  valid_613270 = validateParameter(valid_613270, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_613270 != nil:
    section.add "Action", valid_613270
  var valid_613271 = query.getOrDefault("Version")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613271 != nil:
    section.add "Version", valid_613271
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
  var valid_613272 = header.getOrDefault("X-Amz-Signature")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Signature", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Content-Sha256", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Date")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Date", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Credential")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Credential", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Security-Token")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Security-Token", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Algorithm")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Algorithm", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-SignedHeaders", valid_613278
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_613279 = formData.getOrDefault("AlarmNames")
  valid_613279 = validateParameter(valid_613279, JArray, required = true, default = nil)
  if valid_613279 != nil:
    section.add "AlarmNames", valid_613279
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613280: Call_PostDeleteAlarms_613267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_613280.validator(path, query, header, formData, body)
  let scheme = call_613280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613280.url(scheme.get, call_613280.host, call_613280.base,
                         call_613280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613280, url, valid)

proc call*(call_613281: Call_PostDeleteAlarms_613267; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  var query_613282 = newJObject()
  var formData_613283 = newJObject()
  add(query_613282, "Action", newJString(Action))
  add(query_613282, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_613283.add "AlarmNames", AlarmNames
  result = call_613281.call(nil, query_613282, nil, formData_613283, nil)

var postDeleteAlarms* = Call_PostDeleteAlarms_613267(name: "postDeleteAlarms",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_PostDeleteAlarms_613268,
    base: "/", url: url_PostDeleteAlarms_613269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAlarms_612996 = ref object of OpenApiRestCall_612658
proc url_GetDeleteAlarms_612998(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteAlarms_612997(path: JsonNode; query: JsonNode;
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
  var valid_613110 = query.getOrDefault("AlarmNames")
  valid_613110 = validateParameter(valid_613110, JArray, required = true, default = nil)
  if valid_613110 != nil:
    section.add "AlarmNames", valid_613110
  var valid_613124 = query.getOrDefault("Action")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_613124 != nil:
    section.add "Action", valid_613124
  var valid_613125 = query.getOrDefault("Version")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613125 != nil:
    section.add "Version", valid_613125
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
  var valid_613126 = header.getOrDefault("X-Amz-Signature")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Signature", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Content-Sha256", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Date")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Date", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Credential")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Credential", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Security-Token")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Security-Token", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Algorithm")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Algorithm", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-SignedHeaders", valid_613132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613155: Call_GetDeleteAlarms_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_613155.validator(path, query, header, formData, body)
  let scheme = call_613155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613155.url(scheme.get, call_613155.host, call_613155.base,
                         call_613155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613155, url, valid)

proc call*(call_613226: Call_GetDeleteAlarms_612996; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613227 = newJObject()
  if AlarmNames != nil:
    query_613227.add "AlarmNames", AlarmNames
  add(query_613227, "Action", newJString(Action))
  add(query_613227, "Version", newJString(Version))
  result = call_613226.call(nil, query_613227, nil, nil, nil)

var getDeleteAlarms* = Call_GetDeleteAlarms_612996(name: "getDeleteAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_GetDeleteAlarms_612997,
    base: "/", url: url_GetDeleteAlarms_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnomalyDetector_613303 = ref object of OpenApiRestCall_612658
proc url_PostDeleteAnomalyDetector_613305(protocol: Scheme; host: string;
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

proc validate_PostDeleteAnomalyDetector_613304(path: JsonNode; query: JsonNode;
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
  var valid_613306 = query.getOrDefault("Action")
  valid_613306 = validateParameter(valid_613306, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_613306 != nil:
    section.add "Action", valid_613306
  var valid_613307 = query.getOrDefault("Version")
  valid_613307 = validateParameter(valid_613307, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613307 != nil:
    section.add "Version", valid_613307
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
  var valid_613308 = header.getOrDefault("X-Amz-Signature")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Signature", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Content-Sha256", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Date")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Date", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Credential")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Credential", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Security-Token")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Security-Token", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Algorithm")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Algorithm", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-SignedHeaders", valid_613314
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
  var valid_613315 = formData.getOrDefault("Stat")
  valid_613315 = validateParameter(valid_613315, JString, required = true,
                                 default = nil)
  if valid_613315 != nil:
    section.add "Stat", valid_613315
  var valid_613316 = formData.getOrDefault("MetricName")
  valid_613316 = validateParameter(valid_613316, JString, required = true,
                                 default = nil)
  if valid_613316 != nil:
    section.add "MetricName", valid_613316
  var valid_613317 = formData.getOrDefault("Dimensions")
  valid_613317 = validateParameter(valid_613317, JArray, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "Dimensions", valid_613317
  var valid_613318 = formData.getOrDefault("Namespace")
  valid_613318 = validateParameter(valid_613318, JString, required = true,
                                 default = nil)
  if valid_613318 != nil:
    section.add "Namespace", valid_613318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613319: Call_PostDeleteAnomalyDetector_613303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_613319.validator(path, query, header, formData, body)
  let scheme = call_613319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613319.url(scheme.get, call_613319.host, call_613319.base,
                         call_613319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613319, url, valid)

proc call*(call_613320: Call_PostDeleteAnomalyDetector_613303; Stat: string;
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
  var query_613321 = newJObject()
  var formData_613322 = newJObject()
  add(formData_613322, "Stat", newJString(Stat))
  add(formData_613322, "MetricName", newJString(MetricName))
  add(query_613321, "Action", newJString(Action))
  if Dimensions != nil:
    formData_613322.add "Dimensions", Dimensions
  add(formData_613322, "Namespace", newJString(Namespace))
  add(query_613321, "Version", newJString(Version))
  result = call_613320.call(nil, query_613321, nil, formData_613322, nil)

var postDeleteAnomalyDetector* = Call_PostDeleteAnomalyDetector_613303(
    name: "postDeleteAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_PostDeleteAnomalyDetector_613304, base: "/",
    url: url_PostDeleteAnomalyDetector_613305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnomalyDetector_613284 = ref object of OpenApiRestCall_612658
proc url_GetDeleteAnomalyDetector_613286(protocol: Scheme; host: string;
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

proc validate_GetDeleteAnomalyDetector_613285(path: JsonNode; query: JsonNode;
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
  var valid_613287 = query.getOrDefault("Namespace")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = nil)
  if valid_613287 != nil:
    section.add "Namespace", valid_613287
  var valid_613288 = query.getOrDefault("Dimensions")
  valid_613288 = validateParameter(valid_613288, JArray, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "Dimensions", valid_613288
  var valid_613289 = query.getOrDefault("Action")
  valid_613289 = validateParameter(valid_613289, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_613289 != nil:
    section.add "Action", valid_613289
  var valid_613290 = query.getOrDefault("Version")
  valid_613290 = validateParameter(valid_613290, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613290 != nil:
    section.add "Version", valid_613290
  var valid_613291 = query.getOrDefault("MetricName")
  valid_613291 = validateParameter(valid_613291, JString, required = true,
                                 default = nil)
  if valid_613291 != nil:
    section.add "MetricName", valid_613291
  var valid_613292 = query.getOrDefault("Stat")
  valid_613292 = validateParameter(valid_613292, JString, required = true,
                                 default = nil)
  if valid_613292 != nil:
    section.add "Stat", valid_613292
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
  var valid_613293 = header.getOrDefault("X-Amz-Signature")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Signature", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Content-Sha256", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Date")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Date", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Credential")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Credential", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Security-Token")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Security-Token", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Algorithm")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Algorithm", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-SignedHeaders", valid_613299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613300: Call_GetDeleteAnomalyDetector_613284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_613300.validator(path, query, header, formData, body)
  let scheme = call_613300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613300.url(scheme.get, call_613300.host, call_613300.base,
                         call_613300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613300, url, valid)

proc call*(call_613301: Call_GetDeleteAnomalyDetector_613284; Namespace: string;
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
  var query_613302 = newJObject()
  add(query_613302, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_613302.add "Dimensions", Dimensions
  add(query_613302, "Action", newJString(Action))
  add(query_613302, "Version", newJString(Version))
  add(query_613302, "MetricName", newJString(MetricName))
  add(query_613302, "Stat", newJString(Stat))
  result = call_613301.call(nil, query_613302, nil, nil, nil)

var getDeleteAnomalyDetector* = Call_GetDeleteAnomalyDetector_613284(
    name: "getDeleteAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_GetDeleteAnomalyDetector_613285, base: "/",
    url: url_GetDeleteAnomalyDetector_613286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDashboards_613339 = ref object of OpenApiRestCall_612658
proc url_PostDeleteDashboards_613341(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDashboards_613340(path: JsonNode; query: JsonNode;
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
  var valid_613342 = query.getOrDefault("Action")
  valid_613342 = validateParameter(valid_613342, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_613342 != nil:
    section.add "Action", valid_613342
  var valid_613343 = query.getOrDefault("Version")
  valid_613343 = validateParameter(valid_613343, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613343 != nil:
    section.add "Version", valid_613343
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
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardNames` field"
  var valid_613351 = formData.getOrDefault("DashboardNames")
  valid_613351 = validateParameter(valid_613351, JArray, required = true, default = nil)
  if valid_613351 != nil:
    section.add "DashboardNames", valid_613351
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_PostDeleteDashboards_613339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_PostDeleteDashboards_613339; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613354 = newJObject()
  var formData_613355 = newJObject()
  if DashboardNames != nil:
    formData_613355.add "DashboardNames", DashboardNames
  add(query_613354, "Action", newJString(Action))
  add(query_613354, "Version", newJString(Version))
  result = call_613353.call(nil, query_613354, nil, formData_613355, nil)

var postDeleteDashboards* = Call_PostDeleteDashboards_613339(
    name: "postDeleteDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_PostDeleteDashboards_613340, base: "/",
    url: url_PostDeleteDashboards_613341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDashboards_613323 = ref object of OpenApiRestCall_612658
proc url_GetDeleteDashboards_613325(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDashboards_613324(path: JsonNode; query: JsonNode;
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
  var valid_613326 = query.getOrDefault("DashboardNames")
  valid_613326 = validateParameter(valid_613326, JArray, required = true, default = nil)
  if valid_613326 != nil:
    section.add "DashboardNames", valid_613326
  var valid_613327 = query.getOrDefault("Action")
  valid_613327 = validateParameter(valid_613327, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_613327 != nil:
    section.add "Action", valid_613327
  var valid_613328 = query.getOrDefault("Version")
  valid_613328 = validateParameter(valid_613328, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613328 != nil:
    section.add "Version", valid_613328
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
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613336: Call_GetDeleteDashboards_613323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_613336.validator(path, query, header, formData, body)
  let scheme = call_613336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613336.url(scheme.get, call_613336.host, call_613336.base,
                         call_613336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613336, url, valid)

proc call*(call_613337: Call_GetDeleteDashboards_613323; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613338 = newJObject()
  if DashboardNames != nil:
    query_613338.add "DashboardNames", DashboardNames
  add(query_613338, "Action", newJString(Action))
  add(query_613338, "Version", newJString(Version))
  result = call_613337.call(nil, query_613338, nil, nil, nil)

var getDeleteDashboards* = Call_GetDeleteDashboards_613323(
    name: "getDeleteDashboards", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_GetDeleteDashboards_613324, base: "/",
    url: url_GetDeleteDashboards_613325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteInsightRules_613372 = ref object of OpenApiRestCall_612658
proc url_PostDeleteInsightRules_613374(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteInsightRules_613373(path: JsonNode; query: JsonNode;
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
  var valid_613375 = query.getOrDefault("Action")
  valid_613375 = validateParameter(valid_613375, JString, required = true,
                                 default = newJString("DeleteInsightRules"))
  if valid_613375 != nil:
    section.add "Action", valid_613375
  var valid_613376 = query.getOrDefault("Version")
  valid_613376 = validateParameter(valid_613376, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613376 != nil:
    section.add "Version", valid_613376
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
  var valid_613377 = header.getOrDefault("X-Amz-Signature")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Signature", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Content-Sha256", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Date")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Date", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Credential")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Credential", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Security-Token")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Security-Token", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Algorithm")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Algorithm", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-SignedHeaders", valid_613383
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_613384 = formData.getOrDefault("RuleNames")
  valid_613384 = validateParameter(valid_613384, JArray, required = true, default = nil)
  if valid_613384 != nil:
    section.add "RuleNames", valid_613384
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613385: Call_PostDeleteInsightRules_613372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_613385.validator(path, query, header, formData, body)
  let scheme = call_613385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613385.url(scheme.get, call_613385.host, call_613385.base,
                         call_613385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613385, url, valid)

proc call*(call_613386: Call_PostDeleteInsightRules_613372; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613387 = newJObject()
  var formData_613388 = newJObject()
  if RuleNames != nil:
    formData_613388.add "RuleNames", RuleNames
  add(query_613387, "Action", newJString(Action))
  add(query_613387, "Version", newJString(Version))
  result = call_613386.call(nil, query_613387, nil, formData_613388, nil)

var postDeleteInsightRules* = Call_PostDeleteInsightRules_613372(
    name: "postDeleteInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_PostDeleteInsightRules_613373, base: "/",
    url: url_PostDeleteInsightRules_613374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteInsightRules_613356 = ref object of OpenApiRestCall_612658
proc url_GetDeleteInsightRules_613358(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteInsightRules_613357(path: JsonNode; query: JsonNode;
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
  var valid_613359 = query.getOrDefault("Action")
  valid_613359 = validateParameter(valid_613359, JString, required = true,
                                 default = newJString("DeleteInsightRules"))
  if valid_613359 != nil:
    section.add "Action", valid_613359
  var valid_613360 = query.getOrDefault("RuleNames")
  valid_613360 = validateParameter(valid_613360, JArray, required = true, default = nil)
  if valid_613360 != nil:
    section.add "RuleNames", valid_613360
  var valid_613361 = query.getOrDefault("Version")
  valid_613361 = validateParameter(valid_613361, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613361 != nil:
    section.add "Version", valid_613361
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
  var valid_613362 = header.getOrDefault("X-Amz-Signature")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Signature", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Content-Sha256", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Date")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Date", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Credential")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Credential", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Security-Token")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Security-Token", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Algorithm")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Algorithm", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-SignedHeaders", valid_613368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613369: Call_GetDeleteInsightRules_613356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_613369.validator(path, query, header, formData, body)
  let scheme = call_613369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613369.url(scheme.get, call_613369.host, call_613369.base,
                         call_613369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613369, url, valid)

proc call*(call_613370: Call_GetDeleteInsightRules_613356; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_613371 = newJObject()
  add(query_613371, "Action", newJString(Action))
  if RuleNames != nil:
    query_613371.add "RuleNames", RuleNames
  add(query_613371, "Version", newJString(Version))
  result = call_613370.call(nil, query_613371, nil, nil, nil)

var getDeleteInsightRules* = Call_GetDeleteInsightRules_613356(
    name: "getDeleteInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_GetDeleteInsightRules_613357, base: "/",
    url: url_GetDeleteInsightRules_613358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmHistory_613410 = ref object of OpenApiRestCall_612658
proc url_PostDescribeAlarmHistory_613412(protocol: Scheme; host: string;
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

proc validate_PostDescribeAlarmHistory_613411(path: JsonNode; query: JsonNode;
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
  var valid_613413 = query.getOrDefault("Action")
  valid_613413 = validateParameter(valid_613413, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_613413 != nil:
    section.add "Action", valid_613413
  var valid_613414 = query.getOrDefault("Version")
  valid_613414 = validateParameter(valid_613414, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613414 != nil:
    section.add "Version", valid_613414
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
  var valid_613415 = header.getOrDefault("X-Amz-Signature")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Signature", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Content-Sha256", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Date")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Date", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Credential")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Credential", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Security-Token")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Security-Token", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Algorithm")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Algorithm", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-SignedHeaders", valid_613421
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
  var valid_613422 = formData.getOrDefault("AlarmName")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "AlarmName", valid_613422
  var valid_613423 = formData.getOrDefault("HistoryItemType")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_613423 != nil:
    section.add "HistoryItemType", valid_613423
  var valid_613424 = formData.getOrDefault("MaxRecords")
  valid_613424 = validateParameter(valid_613424, JInt, required = false, default = nil)
  if valid_613424 != nil:
    section.add "MaxRecords", valid_613424
  var valid_613425 = formData.getOrDefault("EndDate")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "EndDate", valid_613425
  var valid_613426 = formData.getOrDefault("NextToken")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "NextToken", valid_613426
  var valid_613427 = formData.getOrDefault("StartDate")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "StartDate", valid_613427
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613428: Call_PostDescribeAlarmHistory_613410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_613428.validator(path, query, header, formData, body)
  let scheme = call_613428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613428.url(scheme.get, call_613428.host, call_613428.base,
                         call_613428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613428, url, valid)

proc call*(call_613429: Call_PostDescribeAlarmHistory_613410;
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
  var query_613430 = newJObject()
  var formData_613431 = newJObject()
  add(formData_613431, "AlarmName", newJString(AlarmName))
  add(formData_613431, "HistoryItemType", newJString(HistoryItemType))
  add(formData_613431, "MaxRecords", newJInt(MaxRecords))
  add(formData_613431, "EndDate", newJString(EndDate))
  add(formData_613431, "NextToken", newJString(NextToken))
  add(formData_613431, "StartDate", newJString(StartDate))
  add(query_613430, "Action", newJString(Action))
  add(query_613430, "Version", newJString(Version))
  result = call_613429.call(nil, query_613430, nil, formData_613431, nil)

var postDescribeAlarmHistory* = Call_PostDescribeAlarmHistory_613410(
    name: "postDescribeAlarmHistory", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_PostDescribeAlarmHistory_613411, base: "/",
    url: url_PostDescribeAlarmHistory_613412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmHistory_613389 = ref object of OpenApiRestCall_612658
proc url_GetDescribeAlarmHistory_613391(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeAlarmHistory_613390(path: JsonNode; query: JsonNode;
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
  var valid_613392 = query.getOrDefault("EndDate")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "EndDate", valid_613392
  var valid_613393 = query.getOrDefault("NextToken")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "NextToken", valid_613393
  var valid_613394 = query.getOrDefault("HistoryItemType")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_613394 != nil:
    section.add "HistoryItemType", valid_613394
  var valid_613395 = query.getOrDefault("Action")
  valid_613395 = validateParameter(valid_613395, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_613395 != nil:
    section.add "Action", valid_613395
  var valid_613396 = query.getOrDefault("AlarmName")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "AlarmName", valid_613396
  var valid_613397 = query.getOrDefault("StartDate")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "StartDate", valid_613397
  var valid_613398 = query.getOrDefault("Version")
  valid_613398 = validateParameter(valid_613398, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613398 != nil:
    section.add "Version", valid_613398
  var valid_613399 = query.getOrDefault("MaxRecords")
  valid_613399 = validateParameter(valid_613399, JInt, required = false, default = nil)
  if valid_613399 != nil:
    section.add "MaxRecords", valid_613399
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
  var valid_613400 = header.getOrDefault("X-Amz-Signature")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Signature", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Content-Sha256", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Date")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Date", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Credential")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Credential", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Security-Token")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Security-Token", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Algorithm")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Algorithm", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-SignedHeaders", valid_613406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613407: Call_GetDescribeAlarmHistory_613389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_613407.validator(path, query, header, formData, body)
  let scheme = call_613407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613407.url(scheme.get, call_613407.host, call_613407.base,
                         call_613407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613407, url, valid)

proc call*(call_613408: Call_GetDescribeAlarmHistory_613389; EndDate: string = "";
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
  var query_613409 = newJObject()
  add(query_613409, "EndDate", newJString(EndDate))
  add(query_613409, "NextToken", newJString(NextToken))
  add(query_613409, "HistoryItemType", newJString(HistoryItemType))
  add(query_613409, "Action", newJString(Action))
  add(query_613409, "AlarmName", newJString(AlarmName))
  add(query_613409, "StartDate", newJString(StartDate))
  add(query_613409, "Version", newJString(Version))
  add(query_613409, "MaxRecords", newJInt(MaxRecords))
  result = call_613408.call(nil, query_613409, nil, nil, nil)

var getDescribeAlarmHistory* = Call_GetDescribeAlarmHistory_613389(
    name: "getDescribeAlarmHistory", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_GetDescribeAlarmHistory_613390, base: "/",
    url: url_GetDescribeAlarmHistory_613391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarms_613453 = ref object of OpenApiRestCall_612658
proc url_PostDescribeAlarms_613455(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeAlarms_613454(path: JsonNode; query: JsonNode;
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
  var valid_613456 = query.getOrDefault("Action")
  valid_613456 = validateParameter(valid_613456, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_613456 != nil:
    section.add "Action", valid_613456
  var valid_613457 = query.getOrDefault("Version")
  valid_613457 = validateParameter(valid_613457, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613457 != nil:
    section.add "Version", valid_613457
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
  var valid_613458 = header.getOrDefault("X-Amz-Signature")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Signature", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Content-Sha256", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Date")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Date", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Credential")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Credential", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Security-Token")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Security-Token", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Algorithm")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Algorithm", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-SignedHeaders", valid_613464
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
  var valid_613465 = formData.getOrDefault("AlarmNamePrefix")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "AlarmNamePrefix", valid_613465
  var valid_613466 = formData.getOrDefault("StateValue")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = newJString("OK"))
  if valid_613466 != nil:
    section.add "StateValue", valid_613466
  var valid_613467 = formData.getOrDefault("NextToken")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "NextToken", valid_613467
  var valid_613468 = formData.getOrDefault("MaxRecords")
  valid_613468 = validateParameter(valid_613468, JInt, required = false, default = nil)
  if valid_613468 != nil:
    section.add "MaxRecords", valid_613468
  var valid_613469 = formData.getOrDefault("ActionPrefix")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "ActionPrefix", valid_613469
  var valid_613470 = formData.getOrDefault("AlarmNames")
  valid_613470 = validateParameter(valid_613470, JArray, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "AlarmNames", valid_613470
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613471: Call_PostDescribeAlarms_613453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_613471.validator(path, query, header, formData, body)
  let scheme = call_613471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613471.url(scheme.get, call_613471.host, call_613471.base,
                         call_613471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613471, url, valid)

proc call*(call_613472: Call_PostDescribeAlarms_613453;
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
  var query_613473 = newJObject()
  var formData_613474 = newJObject()
  add(formData_613474, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(formData_613474, "StateValue", newJString(StateValue))
  add(formData_613474, "NextToken", newJString(NextToken))
  add(formData_613474, "MaxRecords", newJInt(MaxRecords))
  add(query_613473, "Action", newJString(Action))
  add(formData_613474, "ActionPrefix", newJString(ActionPrefix))
  add(query_613473, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_613474.add "AlarmNames", AlarmNames
  result = call_613472.call(nil, query_613473, nil, formData_613474, nil)

var postDescribeAlarms* = Call_PostDescribeAlarms_613453(
    name: "postDescribeAlarms", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarms",
    validator: validate_PostDescribeAlarms_613454, base: "/",
    url: url_PostDescribeAlarms_613455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarms_613432 = ref object of OpenApiRestCall_612658
proc url_GetDescribeAlarms_613434(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeAlarms_613433(path: JsonNode; query: JsonNode;
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
  var valid_613435 = query.getOrDefault("StateValue")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = newJString("OK"))
  if valid_613435 != nil:
    section.add "StateValue", valid_613435
  var valid_613436 = query.getOrDefault("ActionPrefix")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "ActionPrefix", valid_613436
  var valid_613437 = query.getOrDefault("NextToken")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "NextToken", valid_613437
  var valid_613438 = query.getOrDefault("AlarmNamePrefix")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "AlarmNamePrefix", valid_613438
  var valid_613439 = query.getOrDefault("AlarmNames")
  valid_613439 = validateParameter(valid_613439, JArray, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "AlarmNames", valid_613439
  var valid_613440 = query.getOrDefault("Action")
  valid_613440 = validateParameter(valid_613440, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_613440 != nil:
    section.add "Action", valid_613440
  var valid_613441 = query.getOrDefault("Version")
  valid_613441 = validateParameter(valid_613441, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613441 != nil:
    section.add "Version", valid_613441
  var valid_613442 = query.getOrDefault("MaxRecords")
  valid_613442 = validateParameter(valid_613442, JInt, required = false, default = nil)
  if valid_613442 != nil:
    section.add "MaxRecords", valid_613442
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
  var valid_613443 = header.getOrDefault("X-Amz-Signature")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Signature", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Content-Sha256", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Date")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Date", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Credential")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Credential", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Security-Token")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Security-Token", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Algorithm")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Algorithm", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-SignedHeaders", valid_613449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613450: Call_GetDescribeAlarms_613432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_613450.validator(path, query, header, formData, body)
  let scheme = call_613450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613450.url(scheme.get, call_613450.host, call_613450.base,
                         call_613450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613450, url, valid)

proc call*(call_613451: Call_GetDescribeAlarms_613432; StateValue: string = "OK";
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
  var query_613452 = newJObject()
  add(query_613452, "StateValue", newJString(StateValue))
  add(query_613452, "ActionPrefix", newJString(ActionPrefix))
  add(query_613452, "NextToken", newJString(NextToken))
  add(query_613452, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  if AlarmNames != nil:
    query_613452.add "AlarmNames", AlarmNames
  add(query_613452, "Action", newJString(Action))
  add(query_613452, "Version", newJString(Version))
  add(query_613452, "MaxRecords", newJInt(MaxRecords))
  result = call_613451.call(nil, query_613452, nil, nil, nil)

var getDescribeAlarms* = Call_GetDescribeAlarms_613432(name: "getDescribeAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DescribeAlarms", validator: validate_GetDescribeAlarms_613433,
    base: "/", url: url_GetDescribeAlarms_613434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmsForMetric_613497 = ref object of OpenApiRestCall_612658
proc url_PostDescribeAlarmsForMetric_613499(protocol: Scheme; host: string;
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

proc validate_PostDescribeAlarmsForMetric_613498(path: JsonNode; query: JsonNode;
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
  var valid_613500 = query.getOrDefault("Action")
  valid_613500 = validateParameter(valid_613500, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_613500 != nil:
    section.add "Action", valid_613500
  var valid_613501 = query.getOrDefault("Version")
  valid_613501 = validateParameter(valid_613501, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613501 != nil:
    section.add "Version", valid_613501
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
  var valid_613502 = header.getOrDefault("X-Amz-Signature")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Signature", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Content-Sha256", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Date")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Date", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Credential")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Credential", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Security-Token")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Security-Token", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Algorithm")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Algorithm", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-SignedHeaders", valid_613508
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
  var valid_613509 = formData.getOrDefault("Unit")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_613509 != nil:
    section.add "Unit", valid_613509
  var valid_613510 = formData.getOrDefault("Period")
  valid_613510 = validateParameter(valid_613510, JInt, required = false, default = nil)
  if valid_613510 != nil:
    section.add "Period", valid_613510
  var valid_613511 = formData.getOrDefault("Statistic")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_613511 != nil:
    section.add "Statistic", valid_613511
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_613512 = formData.getOrDefault("MetricName")
  valid_613512 = validateParameter(valid_613512, JString, required = true,
                                 default = nil)
  if valid_613512 != nil:
    section.add "MetricName", valid_613512
  var valid_613513 = formData.getOrDefault("Dimensions")
  valid_613513 = validateParameter(valid_613513, JArray, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "Dimensions", valid_613513
  var valid_613514 = formData.getOrDefault("Namespace")
  valid_613514 = validateParameter(valid_613514, JString, required = true,
                                 default = nil)
  if valid_613514 != nil:
    section.add "Namespace", valid_613514
  var valid_613515 = formData.getOrDefault("ExtendedStatistic")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "ExtendedStatistic", valid_613515
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613516: Call_PostDescribeAlarmsForMetric_613497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_613516.validator(path, query, header, formData, body)
  let scheme = call_613516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613516.url(scheme.get, call_613516.host, call_613516.base,
                         call_613516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613516, url, valid)

proc call*(call_613517: Call_PostDescribeAlarmsForMetric_613497;
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
  var query_613518 = newJObject()
  var formData_613519 = newJObject()
  add(formData_613519, "Unit", newJString(Unit))
  add(formData_613519, "Period", newJInt(Period))
  add(formData_613519, "Statistic", newJString(Statistic))
  add(formData_613519, "MetricName", newJString(MetricName))
  add(query_613518, "Action", newJString(Action))
  if Dimensions != nil:
    formData_613519.add "Dimensions", Dimensions
  add(formData_613519, "Namespace", newJString(Namespace))
  add(formData_613519, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_613518, "Version", newJString(Version))
  result = call_613517.call(nil, query_613518, nil, formData_613519, nil)

var postDescribeAlarmsForMetric* = Call_PostDescribeAlarmsForMetric_613497(
    name: "postDescribeAlarmsForMetric", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_PostDescribeAlarmsForMetric_613498, base: "/",
    url: url_PostDescribeAlarmsForMetric_613499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmsForMetric_613475 = ref object of OpenApiRestCall_612658
proc url_GetDescribeAlarmsForMetric_613477(protocol: Scheme; host: string;
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

proc validate_GetDescribeAlarmsForMetric_613476(path: JsonNode; query: JsonNode;
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
  var valid_613478 = query.getOrDefault("Statistic")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_613478 != nil:
    section.add "Statistic", valid_613478
  var valid_613479 = query.getOrDefault("Unit")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_613479 != nil:
    section.add "Unit", valid_613479
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_613480 = query.getOrDefault("Namespace")
  valid_613480 = validateParameter(valid_613480, JString, required = true,
                                 default = nil)
  if valid_613480 != nil:
    section.add "Namespace", valid_613480
  var valid_613481 = query.getOrDefault("ExtendedStatistic")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "ExtendedStatistic", valid_613481
  var valid_613482 = query.getOrDefault("Period")
  valid_613482 = validateParameter(valid_613482, JInt, required = false, default = nil)
  if valid_613482 != nil:
    section.add "Period", valid_613482
  var valid_613483 = query.getOrDefault("Dimensions")
  valid_613483 = validateParameter(valid_613483, JArray, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "Dimensions", valid_613483
  var valid_613484 = query.getOrDefault("Action")
  valid_613484 = validateParameter(valid_613484, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_613484 != nil:
    section.add "Action", valid_613484
  var valid_613485 = query.getOrDefault("Version")
  valid_613485 = validateParameter(valid_613485, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613485 != nil:
    section.add "Version", valid_613485
  var valid_613486 = query.getOrDefault("MetricName")
  valid_613486 = validateParameter(valid_613486, JString, required = true,
                                 default = nil)
  if valid_613486 != nil:
    section.add "MetricName", valid_613486
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
  var valid_613487 = header.getOrDefault("X-Amz-Signature")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Signature", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Content-Sha256", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Date")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Date", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Credential")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Credential", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Security-Token")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Security-Token", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Algorithm")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Algorithm", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-SignedHeaders", valid_613493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613494: Call_GetDescribeAlarmsForMetric_613475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_613494.validator(path, query, header, formData, body)
  let scheme = call_613494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613494.url(scheme.get, call_613494.host, call_613494.base,
                         call_613494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613494, url, valid)

proc call*(call_613495: Call_GetDescribeAlarmsForMetric_613475; Namespace: string;
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
  var query_613496 = newJObject()
  add(query_613496, "Statistic", newJString(Statistic))
  add(query_613496, "Unit", newJString(Unit))
  add(query_613496, "Namespace", newJString(Namespace))
  add(query_613496, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_613496, "Period", newJInt(Period))
  if Dimensions != nil:
    query_613496.add "Dimensions", Dimensions
  add(query_613496, "Action", newJString(Action))
  add(query_613496, "Version", newJString(Version))
  add(query_613496, "MetricName", newJString(MetricName))
  result = call_613495.call(nil, query_613496, nil, nil, nil)

var getDescribeAlarmsForMetric* = Call_GetDescribeAlarmsForMetric_613475(
    name: "getDescribeAlarmsForMetric", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_GetDescribeAlarmsForMetric_613476, base: "/",
    url: url_GetDescribeAlarmsForMetric_613477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnomalyDetectors_613540 = ref object of OpenApiRestCall_612658
proc url_PostDescribeAnomalyDetectors_613542(protocol: Scheme; host: string;
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

proc validate_PostDescribeAnomalyDetectors_613541(path: JsonNode; query: JsonNode;
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
  var valid_613543 = query.getOrDefault("Action")
  valid_613543 = validateParameter(valid_613543, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_613543 != nil:
    section.add "Action", valid_613543
  var valid_613544 = query.getOrDefault("Version")
  valid_613544 = validateParameter(valid_613544, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613544 != nil:
    section.add "Version", valid_613544
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
  var valid_613545 = header.getOrDefault("X-Amz-Signature")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Signature", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Content-Sha256", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Date")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Date", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Credential")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Credential", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Security-Token")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Security-Token", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Algorithm")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Algorithm", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-SignedHeaders", valid_613551
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
  var valid_613552 = formData.getOrDefault("NextToken")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "NextToken", valid_613552
  var valid_613553 = formData.getOrDefault("MetricName")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "MetricName", valid_613553
  var valid_613554 = formData.getOrDefault("Dimensions")
  valid_613554 = validateParameter(valid_613554, JArray, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "Dimensions", valid_613554
  var valid_613555 = formData.getOrDefault("Namespace")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "Namespace", valid_613555
  var valid_613556 = formData.getOrDefault("MaxResults")
  valid_613556 = validateParameter(valid_613556, JInt, required = false, default = nil)
  if valid_613556 != nil:
    section.add "MaxResults", valid_613556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613557: Call_PostDescribeAnomalyDetectors_613540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_613557.validator(path, query, header, formData, body)
  let scheme = call_613557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613557.url(scheme.get, call_613557.host, call_613557.base,
                         call_613557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613557, url, valid)

proc call*(call_613558: Call_PostDescribeAnomalyDetectors_613540;
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
  var query_613559 = newJObject()
  var formData_613560 = newJObject()
  add(formData_613560, "NextToken", newJString(NextToken))
  add(formData_613560, "MetricName", newJString(MetricName))
  add(query_613559, "Action", newJString(Action))
  if Dimensions != nil:
    formData_613560.add "Dimensions", Dimensions
  add(formData_613560, "Namespace", newJString(Namespace))
  add(query_613559, "Version", newJString(Version))
  add(formData_613560, "MaxResults", newJInt(MaxResults))
  result = call_613558.call(nil, query_613559, nil, formData_613560, nil)

var postDescribeAnomalyDetectors* = Call_PostDescribeAnomalyDetectors_613540(
    name: "postDescribeAnomalyDetectors", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_PostDescribeAnomalyDetectors_613541, base: "/",
    url: url_PostDescribeAnomalyDetectors_613542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnomalyDetectors_613520 = ref object of OpenApiRestCall_612658
proc url_GetDescribeAnomalyDetectors_613522(protocol: Scheme; host: string;
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

proc validate_GetDescribeAnomalyDetectors_613521(path: JsonNode; query: JsonNode;
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
  var valid_613523 = query.getOrDefault("MaxResults")
  valid_613523 = validateParameter(valid_613523, JInt, required = false, default = nil)
  if valid_613523 != nil:
    section.add "MaxResults", valid_613523
  var valid_613524 = query.getOrDefault("NextToken")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "NextToken", valid_613524
  var valid_613525 = query.getOrDefault("Namespace")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "Namespace", valid_613525
  var valid_613526 = query.getOrDefault("Dimensions")
  valid_613526 = validateParameter(valid_613526, JArray, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "Dimensions", valid_613526
  var valid_613527 = query.getOrDefault("Action")
  valid_613527 = validateParameter(valid_613527, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_613527 != nil:
    section.add "Action", valid_613527
  var valid_613528 = query.getOrDefault("Version")
  valid_613528 = validateParameter(valid_613528, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613528 != nil:
    section.add "Version", valid_613528
  var valid_613529 = query.getOrDefault("MetricName")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "MetricName", valid_613529
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
  var valid_613530 = header.getOrDefault("X-Amz-Signature")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Signature", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Content-Sha256", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Date")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Date", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Credential")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Credential", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Security-Token")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Security-Token", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Algorithm")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Algorithm", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-SignedHeaders", valid_613536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613537: Call_GetDescribeAnomalyDetectors_613520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_613537.validator(path, query, header, formData, body)
  let scheme = call_613537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613537.url(scheme.get, call_613537.host, call_613537.base,
                         call_613537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613537, url, valid)

proc call*(call_613538: Call_GetDescribeAnomalyDetectors_613520;
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
  var query_613539 = newJObject()
  add(query_613539, "MaxResults", newJInt(MaxResults))
  add(query_613539, "NextToken", newJString(NextToken))
  add(query_613539, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_613539.add "Dimensions", Dimensions
  add(query_613539, "Action", newJString(Action))
  add(query_613539, "Version", newJString(Version))
  add(query_613539, "MetricName", newJString(MetricName))
  result = call_613538.call(nil, query_613539, nil, nil, nil)

var getDescribeAnomalyDetectors* = Call_GetDescribeAnomalyDetectors_613520(
    name: "getDescribeAnomalyDetectors", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_GetDescribeAnomalyDetectors_613521, base: "/",
    url: url_GetDescribeAnomalyDetectors_613522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInsightRules_613578 = ref object of OpenApiRestCall_612658
proc url_PostDescribeInsightRules_613580(protocol: Scheme; host: string;
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

proc validate_PostDescribeInsightRules_613579(path: JsonNode; query: JsonNode;
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
  var valid_613581 = query.getOrDefault("Action")
  valid_613581 = validateParameter(valid_613581, JString, required = true,
                                 default = newJString("DescribeInsightRules"))
  if valid_613581 != nil:
    section.add "Action", valid_613581
  var valid_613582 = query.getOrDefault("Version")
  valid_613582 = validateParameter(valid_613582, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613582 != nil:
    section.add "Version", valid_613582
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
  var valid_613583 = header.getOrDefault("X-Amz-Signature")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Signature", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Content-Sha256", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Date")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Date", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Credential")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Credential", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Security-Token")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Security-Token", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Algorithm")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Algorithm", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-SignedHeaders", valid_613589
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Reserved for future use.
  ##   MaxResults: JInt
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  section = newJObject()
  var valid_613590 = formData.getOrDefault("NextToken")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "NextToken", valid_613590
  var valid_613591 = formData.getOrDefault("MaxResults")
  valid_613591 = validateParameter(valid_613591, JInt, required = false, default = nil)
  if valid_613591 != nil:
    section.add "MaxResults", valid_613591
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613592: Call_PostDescribeInsightRules_613578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_613592.validator(path, query, header, formData, body)
  let scheme = call_613592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613592.url(scheme.get, call_613592.host, call_613592.base,
                         call_613592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613592, url, valid)

proc call*(call_613593: Call_PostDescribeInsightRules_613578;
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
  var query_613594 = newJObject()
  var formData_613595 = newJObject()
  add(formData_613595, "NextToken", newJString(NextToken))
  add(query_613594, "Action", newJString(Action))
  add(query_613594, "Version", newJString(Version))
  add(formData_613595, "MaxResults", newJInt(MaxResults))
  result = call_613593.call(nil, query_613594, nil, formData_613595, nil)

var postDescribeInsightRules* = Call_PostDescribeInsightRules_613578(
    name: "postDescribeInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_PostDescribeInsightRules_613579, base: "/",
    url: url_PostDescribeInsightRules_613580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInsightRules_613561 = ref object of OpenApiRestCall_612658
proc url_GetDescribeInsightRules_613563(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeInsightRules_613562(path: JsonNode; query: JsonNode;
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
  var valid_613564 = query.getOrDefault("MaxResults")
  valid_613564 = validateParameter(valid_613564, JInt, required = false, default = nil)
  if valid_613564 != nil:
    section.add "MaxResults", valid_613564
  var valid_613565 = query.getOrDefault("NextToken")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "NextToken", valid_613565
  var valid_613566 = query.getOrDefault("Action")
  valid_613566 = validateParameter(valid_613566, JString, required = true,
                                 default = newJString("DescribeInsightRules"))
  if valid_613566 != nil:
    section.add "Action", valid_613566
  var valid_613567 = query.getOrDefault("Version")
  valid_613567 = validateParameter(valid_613567, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613567 != nil:
    section.add "Version", valid_613567
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
  var valid_613568 = header.getOrDefault("X-Amz-Signature")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Signature", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Content-Sha256", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Date")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Date", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Credential")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Credential", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Security-Token")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Security-Token", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Algorithm")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Algorithm", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-SignedHeaders", valid_613574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613575: Call_GetDescribeInsightRules_613561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_613575.validator(path, query, header, formData, body)
  let scheme = call_613575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613575.url(scheme.get, call_613575.host, call_613575.base,
                         call_613575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613575, url, valid)

proc call*(call_613576: Call_GetDescribeInsightRules_613561; MaxResults: int = 0;
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
  var query_613577 = newJObject()
  add(query_613577, "MaxResults", newJInt(MaxResults))
  add(query_613577, "NextToken", newJString(NextToken))
  add(query_613577, "Action", newJString(Action))
  add(query_613577, "Version", newJString(Version))
  result = call_613576.call(nil, query_613577, nil, nil, nil)

var getDescribeInsightRules* = Call_GetDescribeInsightRules_613561(
    name: "getDescribeInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_GetDescribeInsightRules_613562, base: "/",
    url: url_GetDescribeInsightRules_613563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAlarmActions_613612 = ref object of OpenApiRestCall_612658
proc url_PostDisableAlarmActions_613614(protocol: Scheme; host: string; base: string;
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

proc validate_PostDisableAlarmActions_613613(path: JsonNode; query: JsonNode;
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
  var valid_613615 = query.getOrDefault("Action")
  valid_613615 = validateParameter(valid_613615, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_613615 != nil:
    section.add "Action", valid_613615
  var valid_613616 = query.getOrDefault("Version")
  valid_613616 = validateParameter(valid_613616, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613616 != nil:
    section.add "Version", valid_613616
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
  var valid_613617 = header.getOrDefault("X-Amz-Signature")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Signature", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Content-Sha256", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Date")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Date", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Credential")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Credential", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Security-Token")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Security-Token", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Algorithm")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Algorithm", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-SignedHeaders", valid_613623
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_613624 = formData.getOrDefault("AlarmNames")
  valid_613624 = validateParameter(valid_613624, JArray, required = true, default = nil)
  if valid_613624 != nil:
    section.add "AlarmNames", valid_613624
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613625: Call_PostDisableAlarmActions_613612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_613625.validator(path, query, header, formData, body)
  let scheme = call_613625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613625.url(scheme.get, call_613625.host, call_613625.base,
                         call_613625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613625, url, valid)

proc call*(call_613626: Call_PostDisableAlarmActions_613612; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_613627 = newJObject()
  var formData_613628 = newJObject()
  add(query_613627, "Action", newJString(Action))
  add(query_613627, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_613628.add "AlarmNames", AlarmNames
  result = call_613626.call(nil, query_613627, nil, formData_613628, nil)

var postDisableAlarmActions* = Call_PostDisableAlarmActions_613612(
    name: "postDisableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_PostDisableAlarmActions_613613, base: "/",
    url: url_PostDisableAlarmActions_613614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAlarmActions_613596 = ref object of OpenApiRestCall_612658
proc url_GetDisableAlarmActions_613598(protocol: Scheme; host: string; base: string;
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

proc validate_GetDisableAlarmActions_613597(path: JsonNode; query: JsonNode;
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
  var valid_613599 = query.getOrDefault("AlarmNames")
  valid_613599 = validateParameter(valid_613599, JArray, required = true, default = nil)
  if valid_613599 != nil:
    section.add "AlarmNames", valid_613599
  var valid_613600 = query.getOrDefault("Action")
  valid_613600 = validateParameter(valid_613600, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_613600 != nil:
    section.add "Action", valid_613600
  var valid_613601 = query.getOrDefault("Version")
  valid_613601 = validateParameter(valid_613601, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613601 != nil:
    section.add "Version", valid_613601
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
  var valid_613602 = header.getOrDefault("X-Amz-Signature")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Signature", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Content-Sha256", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Date")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Date", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Credential")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Credential", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Security-Token")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Security-Token", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Algorithm")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Algorithm", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-SignedHeaders", valid_613608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613609: Call_GetDisableAlarmActions_613596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_613609.validator(path, query, header, formData, body)
  let scheme = call_613609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613609.url(scheme.get, call_613609.host, call_613609.base,
                         call_613609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613609, url, valid)

proc call*(call_613610: Call_GetDisableAlarmActions_613596; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613611 = newJObject()
  if AlarmNames != nil:
    query_613611.add "AlarmNames", AlarmNames
  add(query_613611, "Action", newJString(Action))
  add(query_613611, "Version", newJString(Version))
  result = call_613610.call(nil, query_613611, nil, nil, nil)

var getDisableAlarmActions* = Call_GetDisableAlarmActions_613596(
    name: "getDisableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_GetDisableAlarmActions_613597, base: "/",
    url: url_GetDisableAlarmActions_613598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableInsightRules_613645 = ref object of OpenApiRestCall_612658
proc url_PostDisableInsightRules_613647(protocol: Scheme; host: string; base: string;
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

proc validate_PostDisableInsightRules_613646(path: JsonNode; query: JsonNode;
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
  var valid_613648 = query.getOrDefault("Action")
  valid_613648 = validateParameter(valid_613648, JString, required = true,
                                 default = newJString("DisableInsightRules"))
  if valid_613648 != nil:
    section.add "Action", valid_613648
  var valid_613649 = query.getOrDefault("Version")
  valid_613649 = validateParameter(valid_613649, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613649 != nil:
    section.add "Version", valid_613649
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
  var valid_613650 = header.getOrDefault("X-Amz-Signature")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Signature", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Content-Sha256", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Date")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Date", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Credential")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Credential", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Security-Token")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Security-Token", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Algorithm")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Algorithm", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-SignedHeaders", valid_613656
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_613657 = formData.getOrDefault("RuleNames")
  valid_613657 = validateParameter(valid_613657, JArray, required = true, default = nil)
  if valid_613657 != nil:
    section.add "RuleNames", valid_613657
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613658: Call_PostDisableInsightRules_613645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_613658.validator(path, query, header, formData, body)
  let scheme = call_613658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613658.url(scheme.get, call_613658.host, call_613658.base,
                         call_613658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613658, url, valid)

proc call*(call_613659: Call_PostDisableInsightRules_613645; RuleNames: JsonNode;
          Action: string = "DisableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613660 = newJObject()
  var formData_613661 = newJObject()
  if RuleNames != nil:
    formData_613661.add "RuleNames", RuleNames
  add(query_613660, "Action", newJString(Action))
  add(query_613660, "Version", newJString(Version))
  result = call_613659.call(nil, query_613660, nil, formData_613661, nil)

var postDisableInsightRules* = Call_PostDisableInsightRules_613645(
    name: "postDisableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_PostDisableInsightRules_613646, base: "/",
    url: url_PostDisableInsightRules_613647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableInsightRules_613629 = ref object of OpenApiRestCall_612658
proc url_GetDisableInsightRules_613631(protocol: Scheme; host: string; base: string;
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

proc validate_GetDisableInsightRules_613630(path: JsonNode; query: JsonNode;
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
  var valid_613632 = query.getOrDefault("Action")
  valid_613632 = validateParameter(valid_613632, JString, required = true,
                                 default = newJString("DisableInsightRules"))
  if valid_613632 != nil:
    section.add "Action", valid_613632
  var valid_613633 = query.getOrDefault("RuleNames")
  valid_613633 = validateParameter(valid_613633, JArray, required = true, default = nil)
  if valid_613633 != nil:
    section.add "RuleNames", valid_613633
  var valid_613634 = query.getOrDefault("Version")
  valid_613634 = validateParameter(valid_613634, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613634 != nil:
    section.add "Version", valid_613634
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
  var valid_613635 = header.getOrDefault("X-Amz-Signature")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Signature", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Content-Sha256", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Date")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Date", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Credential")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Credential", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Security-Token")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Security-Token", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Algorithm")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Algorithm", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-SignedHeaders", valid_613641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613642: Call_GetDisableInsightRules_613629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_613642.validator(path, query, header, formData, body)
  let scheme = call_613642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613642.url(scheme.get, call_613642.host, call_613642.base,
                         call_613642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613642, url, valid)

proc call*(call_613643: Call_GetDisableInsightRules_613629; RuleNames: JsonNode;
          Action: string = "DisableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_613644 = newJObject()
  add(query_613644, "Action", newJString(Action))
  if RuleNames != nil:
    query_613644.add "RuleNames", RuleNames
  add(query_613644, "Version", newJString(Version))
  result = call_613643.call(nil, query_613644, nil, nil, nil)

var getDisableInsightRules* = Call_GetDisableInsightRules_613629(
    name: "getDisableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_GetDisableInsightRules_613630, base: "/",
    url: url_GetDisableInsightRules_613631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAlarmActions_613678 = ref object of OpenApiRestCall_612658
proc url_PostEnableAlarmActions_613680(protocol: Scheme; host: string; base: string;
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

proc validate_PostEnableAlarmActions_613679(path: JsonNode; query: JsonNode;
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
  var valid_613681 = query.getOrDefault("Action")
  valid_613681 = validateParameter(valid_613681, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_613681 != nil:
    section.add "Action", valid_613681
  var valid_613682 = query.getOrDefault("Version")
  valid_613682 = validateParameter(valid_613682, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613682 != nil:
    section.add "Version", valid_613682
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
  var valid_613683 = header.getOrDefault("X-Amz-Signature")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Signature", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Content-Sha256", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Date")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Date", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Credential")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Credential", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Security-Token")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Security-Token", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Algorithm")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Algorithm", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-SignedHeaders", valid_613689
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_613690 = formData.getOrDefault("AlarmNames")
  valid_613690 = validateParameter(valid_613690, JArray, required = true, default = nil)
  if valid_613690 != nil:
    section.add "AlarmNames", valid_613690
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613691: Call_PostEnableAlarmActions_613678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_613691.validator(path, query, header, formData, body)
  let scheme = call_613691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613691.url(scheme.get, call_613691.host, call_613691.base,
                         call_613691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613691, url, valid)

proc call*(call_613692: Call_PostEnableAlarmActions_613678; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_613693 = newJObject()
  var formData_613694 = newJObject()
  add(query_613693, "Action", newJString(Action))
  add(query_613693, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_613694.add "AlarmNames", AlarmNames
  result = call_613692.call(nil, query_613693, nil, formData_613694, nil)

var postEnableAlarmActions* = Call_PostEnableAlarmActions_613678(
    name: "postEnableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_PostEnableAlarmActions_613679, base: "/",
    url: url_PostEnableAlarmActions_613680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAlarmActions_613662 = ref object of OpenApiRestCall_612658
proc url_GetEnableAlarmActions_613664(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnableAlarmActions_613663(path: JsonNode; query: JsonNode;
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
  var valid_613665 = query.getOrDefault("AlarmNames")
  valid_613665 = validateParameter(valid_613665, JArray, required = true, default = nil)
  if valid_613665 != nil:
    section.add "AlarmNames", valid_613665
  var valid_613666 = query.getOrDefault("Action")
  valid_613666 = validateParameter(valid_613666, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_613666 != nil:
    section.add "Action", valid_613666
  var valid_613667 = query.getOrDefault("Version")
  valid_613667 = validateParameter(valid_613667, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613667 != nil:
    section.add "Version", valid_613667
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
  var valid_613668 = header.getOrDefault("X-Amz-Signature")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Signature", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Content-Sha256", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Date")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Date", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Credential")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Credential", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Security-Token")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Security-Token", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Algorithm")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Algorithm", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-SignedHeaders", valid_613674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613675: Call_GetEnableAlarmActions_613662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_613675.validator(path, query, header, formData, body)
  let scheme = call_613675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613675.url(scheme.get, call_613675.host, call_613675.base,
                         call_613675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613675, url, valid)

proc call*(call_613676: Call_GetEnableAlarmActions_613662; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613677 = newJObject()
  if AlarmNames != nil:
    query_613677.add "AlarmNames", AlarmNames
  add(query_613677, "Action", newJString(Action))
  add(query_613677, "Version", newJString(Version))
  result = call_613676.call(nil, query_613677, nil, nil, nil)

var getEnableAlarmActions* = Call_GetEnableAlarmActions_613662(
    name: "getEnableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_GetEnableAlarmActions_613663, base: "/",
    url: url_GetEnableAlarmActions_613664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableInsightRules_613711 = ref object of OpenApiRestCall_612658
proc url_PostEnableInsightRules_613713(protocol: Scheme; host: string; base: string;
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

proc validate_PostEnableInsightRules_613712(path: JsonNode; query: JsonNode;
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
  var valid_613714 = query.getOrDefault("Action")
  valid_613714 = validateParameter(valid_613714, JString, required = true,
                                 default = newJString("EnableInsightRules"))
  if valid_613714 != nil:
    section.add "Action", valid_613714
  var valid_613715 = query.getOrDefault("Version")
  valid_613715 = validateParameter(valid_613715, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613715 != nil:
    section.add "Version", valid_613715
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
  var valid_613716 = header.getOrDefault("X-Amz-Signature")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Signature", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Content-Sha256", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Date")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Date", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Credential")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Credential", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Security-Token")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Security-Token", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Algorithm")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Algorithm", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-SignedHeaders", valid_613722
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_613723 = formData.getOrDefault("RuleNames")
  valid_613723 = validateParameter(valid_613723, JArray, required = true, default = nil)
  if valid_613723 != nil:
    section.add "RuleNames", valid_613723
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613724: Call_PostEnableInsightRules_613711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_613724.validator(path, query, header, formData, body)
  let scheme = call_613724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613724.url(scheme.get, call_613724.host, call_613724.base,
                         call_613724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613724, url, valid)

proc call*(call_613725: Call_PostEnableInsightRules_613711; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613726 = newJObject()
  var formData_613727 = newJObject()
  if RuleNames != nil:
    formData_613727.add "RuleNames", RuleNames
  add(query_613726, "Action", newJString(Action))
  add(query_613726, "Version", newJString(Version))
  result = call_613725.call(nil, query_613726, nil, formData_613727, nil)

var postEnableInsightRules* = Call_PostEnableInsightRules_613711(
    name: "postEnableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_PostEnableInsightRules_613712, base: "/",
    url: url_PostEnableInsightRules_613713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableInsightRules_613695 = ref object of OpenApiRestCall_612658
proc url_GetEnableInsightRules_613697(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnableInsightRules_613696(path: JsonNode; query: JsonNode;
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
  var valid_613698 = query.getOrDefault("Action")
  valid_613698 = validateParameter(valid_613698, JString, required = true,
                                 default = newJString("EnableInsightRules"))
  if valid_613698 != nil:
    section.add "Action", valid_613698
  var valid_613699 = query.getOrDefault("RuleNames")
  valid_613699 = validateParameter(valid_613699, JArray, required = true, default = nil)
  if valid_613699 != nil:
    section.add "RuleNames", valid_613699
  var valid_613700 = query.getOrDefault("Version")
  valid_613700 = validateParameter(valid_613700, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613700 != nil:
    section.add "Version", valid_613700
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
  var valid_613701 = header.getOrDefault("X-Amz-Signature")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Signature", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Content-Sha256", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Date")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Date", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Credential")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Credential", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Security-Token")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Security-Token", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Algorithm")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Algorithm", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-SignedHeaders", valid_613707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613708: Call_GetEnableInsightRules_613695; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_613708.validator(path, query, header, formData, body)
  let scheme = call_613708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613708.url(scheme.get, call_613708.host, call_613708.base,
                         call_613708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613708, url, valid)

proc call*(call_613709: Call_GetEnableInsightRules_613695; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_613710 = newJObject()
  add(query_613710, "Action", newJString(Action))
  if RuleNames != nil:
    query_613710.add "RuleNames", RuleNames
  add(query_613710, "Version", newJString(Version))
  result = call_613709.call(nil, query_613710, nil, nil, nil)

var getEnableInsightRules* = Call_GetEnableInsightRules_613695(
    name: "getEnableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_GetEnableInsightRules_613696, base: "/",
    url: url_GetEnableInsightRules_613697, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetDashboard_613744 = ref object of OpenApiRestCall_612658
proc url_PostGetDashboard_613746(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetDashboard_613745(path: JsonNode; query: JsonNode;
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
  var valid_613747 = query.getOrDefault("Action")
  valid_613747 = validateParameter(valid_613747, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_613747 != nil:
    section.add "Action", valid_613747
  var valid_613748 = query.getOrDefault("Version")
  valid_613748 = validateParameter(valid_613748, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613748 != nil:
    section.add "Version", valid_613748
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
  var valid_613749 = header.getOrDefault("X-Amz-Signature")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Signature", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Content-Sha256", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Date")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Date", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Credential")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Credential", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Security-Token")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Security-Token", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Algorithm")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Algorithm", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-SignedHeaders", valid_613755
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_613756 = formData.getOrDefault("DashboardName")
  valid_613756 = validateParameter(valid_613756, JString, required = true,
                                 default = nil)
  if valid_613756 != nil:
    section.add "DashboardName", valid_613756
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613757: Call_PostGetDashboard_613744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_613757.validator(path, query, header, formData, body)
  let scheme = call_613757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613757.url(scheme.get, call_613757.host, call_613757.base,
                         call_613757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613757, url, valid)

proc call*(call_613758: Call_PostGetDashboard_613744; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## postGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613759 = newJObject()
  var formData_613760 = newJObject()
  add(formData_613760, "DashboardName", newJString(DashboardName))
  add(query_613759, "Action", newJString(Action))
  add(query_613759, "Version", newJString(Version))
  result = call_613758.call(nil, query_613759, nil, formData_613760, nil)

var postGetDashboard* = Call_PostGetDashboard_613744(name: "postGetDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_PostGetDashboard_613745,
    base: "/", url: url_PostGetDashboard_613746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetDashboard_613728 = ref object of OpenApiRestCall_612658
proc url_GetGetDashboard_613730(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetDashboard_613729(path: JsonNode; query: JsonNode;
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
  var valid_613731 = query.getOrDefault("Action")
  valid_613731 = validateParameter(valid_613731, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_613731 != nil:
    section.add "Action", valid_613731
  var valid_613732 = query.getOrDefault("DashboardName")
  valid_613732 = validateParameter(valid_613732, JString, required = true,
                                 default = nil)
  if valid_613732 != nil:
    section.add "DashboardName", valid_613732
  var valid_613733 = query.getOrDefault("Version")
  valid_613733 = validateParameter(valid_613733, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613733 != nil:
    section.add "Version", valid_613733
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
  var valid_613734 = header.getOrDefault("X-Amz-Signature")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Signature", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Content-Sha256", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Date")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Date", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Credential")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Credential", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Security-Token")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Security-Token", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Algorithm")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Algorithm", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-SignedHeaders", valid_613740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613741: Call_GetGetDashboard_613728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_613741.validator(path, query, header, formData, body)
  let scheme = call_613741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613741.url(scheme.get, call_613741.host, call_613741.base,
                         call_613741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613741, url, valid)

proc call*(call_613742: Call_GetGetDashboard_613728; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## getGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Version: string (required)
  var query_613743 = newJObject()
  add(query_613743, "Action", newJString(Action))
  add(query_613743, "DashboardName", newJString(DashboardName))
  add(query_613743, "Version", newJString(Version))
  result = call_613742.call(nil, query_613743, nil, nil, nil)

var getGetDashboard* = Call_GetGetDashboard_613728(name: "getGetDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_GetGetDashboard_613729,
    base: "/", url: url_GetGetDashboard_613730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetInsightRuleReport_613783 = ref object of OpenApiRestCall_612658
proc url_PostGetInsightRuleReport_613785(protocol: Scheme; host: string;
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

proc validate_PostGetInsightRuleReport_613784(path: JsonNode; query: JsonNode;
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
  var valid_613786 = query.getOrDefault("Action")
  valid_613786 = validateParameter(valid_613786, JString, required = true,
                                 default = newJString("GetInsightRuleReport"))
  if valid_613786 != nil:
    section.add "Action", valid_613786
  var valid_613787 = query.getOrDefault("Version")
  valid_613787 = validateParameter(valid_613787, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613787 != nil:
    section.add "Version", valid_613787
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
  var valid_613788 = header.getOrDefault("X-Amz-Signature")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Signature", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Content-Sha256", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-Date")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Date", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Credential")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Credential", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Security-Token")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Security-Token", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Algorithm")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Algorithm", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-SignedHeaders", valid_613794
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
  var valid_613795 = formData.getOrDefault("RuleName")
  valid_613795 = validateParameter(valid_613795, JString, required = true,
                                 default = nil)
  if valid_613795 != nil:
    section.add "RuleName", valid_613795
  var valid_613796 = formData.getOrDefault("Period")
  valid_613796 = validateParameter(valid_613796, JInt, required = true, default = nil)
  if valid_613796 != nil:
    section.add "Period", valid_613796
  var valid_613797 = formData.getOrDefault("OrderBy")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "OrderBy", valid_613797
  var valid_613798 = formData.getOrDefault("EndTime")
  valid_613798 = validateParameter(valid_613798, JString, required = true,
                                 default = nil)
  if valid_613798 != nil:
    section.add "EndTime", valid_613798
  var valid_613799 = formData.getOrDefault("StartTime")
  valid_613799 = validateParameter(valid_613799, JString, required = true,
                                 default = nil)
  if valid_613799 != nil:
    section.add "StartTime", valid_613799
  var valid_613800 = formData.getOrDefault("MaxContributorCount")
  valid_613800 = validateParameter(valid_613800, JInt, required = false, default = nil)
  if valid_613800 != nil:
    section.add "MaxContributorCount", valid_613800
  var valid_613801 = formData.getOrDefault("Metrics")
  valid_613801 = validateParameter(valid_613801, JArray, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "Metrics", valid_613801
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613802: Call_PostGetInsightRuleReport_613783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_613802.validator(path, query, header, formData, body)
  let scheme = call_613802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613802.url(scheme.get, call_613802.host, call_613802.base,
                         call_613802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613802, url, valid)

proc call*(call_613803: Call_PostGetInsightRuleReport_613783; RuleName: string;
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
  var query_613804 = newJObject()
  var formData_613805 = newJObject()
  add(formData_613805, "RuleName", newJString(RuleName))
  add(formData_613805, "Period", newJInt(Period))
  add(formData_613805, "OrderBy", newJString(OrderBy))
  add(formData_613805, "EndTime", newJString(EndTime))
  add(formData_613805, "StartTime", newJString(StartTime))
  add(query_613804, "Action", newJString(Action))
  add(query_613804, "Version", newJString(Version))
  add(formData_613805, "MaxContributorCount", newJInt(MaxContributorCount))
  if Metrics != nil:
    formData_613805.add "Metrics", Metrics
  result = call_613803.call(nil, query_613804, nil, formData_613805, nil)

var postGetInsightRuleReport* = Call_PostGetInsightRuleReport_613783(
    name: "postGetInsightRuleReport", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_PostGetInsightRuleReport_613784, base: "/",
    url: url_PostGetInsightRuleReport_613785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetInsightRuleReport_613761 = ref object of OpenApiRestCall_612658
proc url_GetGetInsightRuleReport_613763(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetInsightRuleReport_613762(path: JsonNode; query: JsonNode;
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
  var valid_613764 = query.getOrDefault("RuleName")
  valid_613764 = validateParameter(valid_613764, JString, required = true,
                                 default = nil)
  if valid_613764 != nil:
    section.add "RuleName", valid_613764
  var valid_613765 = query.getOrDefault("MaxContributorCount")
  valid_613765 = validateParameter(valid_613765, JInt, required = false, default = nil)
  if valid_613765 != nil:
    section.add "MaxContributorCount", valid_613765
  var valid_613766 = query.getOrDefault("OrderBy")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "OrderBy", valid_613766
  var valid_613767 = query.getOrDefault("Period")
  valid_613767 = validateParameter(valid_613767, JInt, required = true, default = nil)
  if valid_613767 != nil:
    section.add "Period", valid_613767
  var valid_613768 = query.getOrDefault("Action")
  valid_613768 = validateParameter(valid_613768, JString, required = true,
                                 default = newJString("GetInsightRuleReport"))
  if valid_613768 != nil:
    section.add "Action", valid_613768
  var valid_613769 = query.getOrDefault("StartTime")
  valid_613769 = validateParameter(valid_613769, JString, required = true,
                                 default = nil)
  if valid_613769 != nil:
    section.add "StartTime", valid_613769
  var valid_613770 = query.getOrDefault("EndTime")
  valid_613770 = validateParameter(valid_613770, JString, required = true,
                                 default = nil)
  if valid_613770 != nil:
    section.add "EndTime", valid_613770
  var valid_613771 = query.getOrDefault("Metrics")
  valid_613771 = validateParameter(valid_613771, JArray, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "Metrics", valid_613771
  var valid_613772 = query.getOrDefault("Version")
  valid_613772 = validateParameter(valid_613772, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613772 != nil:
    section.add "Version", valid_613772
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
  var valid_613773 = header.getOrDefault("X-Amz-Signature")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Signature", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Content-Sha256", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Date")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Date", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Credential")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Credential", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Security-Token")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Security-Token", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Algorithm")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Algorithm", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-SignedHeaders", valid_613779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613780: Call_GetGetInsightRuleReport_613761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_613780.validator(path, query, header, formData, body)
  let scheme = call_613780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613780.url(scheme.get, call_613780.host, call_613780.base,
                         call_613780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613780, url, valid)

proc call*(call_613781: Call_GetGetInsightRuleReport_613761; RuleName: string;
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
  var query_613782 = newJObject()
  add(query_613782, "RuleName", newJString(RuleName))
  add(query_613782, "MaxContributorCount", newJInt(MaxContributorCount))
  add(query_613782, "OrderBy", newJString(OrderBy))
  add(query_613782, "Period", newJInt(Period))
  add(query_613782, "Action", newJString(Action))
  add(query_613782, "StartTime", newJString(StartTime))
  add(query_613782, "EndTime", newJString(EndTime))
  if Metrics != nil:
    query_613782.add "Metrics", Metrics
  add(query_613782, "Version", newJString(Version))
  result = call_613781.call(nil, query_613782, nil, nil, nil)

var getGetInsightRuleReport* = Call_GetGetInsightRuleReport_613761(
    name: "getGetInsightRuleReport", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_GetGetInsightRuleReport_613762, base: "/",
    url: url_GetGetInsightRuleReport_613763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricData_613827 = ref object of OpenApiRestCall_612658
proc url_PostGetMetricData_613829(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetMetricData_613828(path: JsonNode; query: JsonNode;
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
  var valid_613830 = query.getOrDefault("Action")
  valid_613830 = validateParameter(valid_613830, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_613830 != nil:
    section.add "Action", valid_613830
  var valid_613831 = query.getOrDefault("Version")
  valid_613831 = validateParameter(valid_613831, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613831 != nil:
    section.add "Version", valid_613831
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
  var valid_613832 = header.getOrDefault("X-Amz-Signature")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Signature", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Content-Sha256", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Date")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Date", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Credential")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Credential", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Security-Token")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Security-Token", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Algorithm")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Algorithm", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-SignedHeaders", valid_613838
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
  var valid_613839 = formData.getOrDefault("NextToken")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "NextToken", valid_613839
  var valid_613840 = formData.getOrDefault("ScanBy")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_613840 != nil:
    section.add "ScanBy", valid_613840
  assert formData != nil,
        "formData argument is necessary due to required `EndTime` field"
  var valid_613841 = formData.getOrDefault("EndTime")
  valid_613841 = validateParameter(valid_613841, JString, required = true,
                                 default = nil)
  if valid_613841 != nil:
    section.add "EndTime", valid_613841
  var valid_613842 = formData.getOrDefault("StartTime")
  valid_613842 = validateParameter(valid_613842, JString, required = true,
                                 default = nil)
  if valid_613842 != nil:
    section.add "StartTime", valid_613842
  var valid_613843 = formData.getOrDefault("MetricDataQueries")
  valid_613843 = validateParameter(valid_613843, JArray, required = true, default = nil)
  if valid_613843 != nil:
    section.add "MetricDataQueries", valid_613843
  var valid_613844 = formData.getOrDefault("MaxDatapoints")
  valid_613844 = validateParameter(valid_613844, JInt, required = false, default = nil)
  if valid_613844 != nil:
    section.add "MaxDatapoints", valid_613844
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613845: Call_PostGetMetricData_613827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_613845.validator(path, query, header, formData, body)
  let scheme = call_613845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613845.url(scheme.get, call_613845.host, call_613845.base,
                         call_613845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613845, url, valid)

proc call*(call_613846: Call_PostGetMetricData_613827; EndTime: string;
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
  var query_613847 = newJObject()
  var formData_613848 = newJObject()
  add(formData_613848, "NextToken", newJString(NextToken))
  add(formData_613848, "ScanBy", newJString(ScanBy))
  add(formData_613848, "EndTime", newJString(EndTime))
  add(formData_613848, "StartTime", newJString(StartTime))
  add(query_613847, "Action", newJString(Action))
  add(query_613847, "Version", newJString(Version))
  if MetricDataQueries != nil:
    formData_613848.add "MetricDataQueries", MetricDataQueries
  add(formData_613848, "MaxDatapoints", newJInt(MaxDatapoints))
  result = call_613846.call(nil, query_613847, nil, formData_613848, nil)

var postGetMetricData* = Call_PostGetMetricData_613827(name: "postGetMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_PostGetMetricData_613828,
    base: "/", url: url_PostGetMetricData_613829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricData_613806 = ref object of OpenApiRestCall_612658
proc url_GetGetMetricData_613808(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricData_613807(path: JsonNode; query: JsonNode;
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
  var valid_613809 = query.getOrDefault("NextToken")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "NextToken", valid_613809
  var valid_613810 = query.getOrDefault("MaxDatapoints")
  valid_613810 = validateParameter(valid_613810, JInt, required = false, default = nil)
  if valid_613810 != nil:
    section.add "MaxDatapoints", valid_613810
  var valid_613811 = query.getOrDefault("Action")
  valid_613811 = validateParameter(valid_613811, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_613811 != nil:
    section.add "Action", valid_613811
  var valid_613812 = query.getOrDefault("StartTime")
  valid_613812 = validateParameter(valid_613812, JString, required = true,
                                 default = nil)
  if valid_613812 != nil:
    section.add "StartTime", valid_613812
  var valid_613813 = query.getOrDefault("EndTime")
  valid_613813 = validateParameter(valid_613813, JString, required = true,
                                 default = nil)
  if valid_613813 != nil:
    section.add "EndTime", valid_613813
  var valid_613814 = query.getOrDefault("Version")
  valid_613814 = validateParameter(valid_613814, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613814 != nil:
    section.add "Version", valid_613814
  var valid_613815 = query.getOrDefault("MetricDataQueries")
  valid_613815 = validateParameter(valid_613815, JArray, required = true, default = nil)
  if valid_613815 != nil:
    section.add "MetricDataQueries", valid_613815
  var valid_613816 = query.getOrDefault("ScanBy")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_613816 != nil:
    section.add "ScanBy", valid_613816
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
  var valid_613817 = header.getOrDefault("X-Amz-Signature")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Signature", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Content-Sha256", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Date")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Date", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-Credential")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Credential", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-Security-Token")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-Security-Token", valid_613821
  var valid_613822 = header.getOrDefault("X-Amz-Algorithm")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-Algorithm", valid_613822
  var valid_613823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-SignedHeaders", valid_613823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613824: Call_GetGetMetricData_613806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_613824.validator(path, query, header, formData, body)
  let scheme = call_613824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613824.url(scheme.get, call_613824.host, call_613824.base,
                         call_613824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613824, url, valid)

proc call*(call_613825: Call_GetGetMetricData_613806; StartTime: string;
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
  var query_613826 = newJObject()
  add(query_613826, "NextToken", newJString(NextToken))
  add(query_613826, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_613826, "Action", newJString(Action))
  add(query_613826, "StartTime", newJString(StartTime))
  add(query_613826, "EndTime", newJString(EndTime))
  add(query_613826, "Version", newJString(Version))
  if MetricDataQueries != nil:
    query_613826.add "MetricDataQueries", MetricDataQueries
  add(query_613826, "ScanBy", newJString(ScanBy))
  result = call_613825.call(nil, query_613826, nil, nil, nil)

var getGetMetricData* = Call_GetGetMetricData_613806(name: "getGetMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_GetGetMetricData_613807,
    base: "/", url: url_GetGetMetricData_613808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricStatistics_613873 = ref object of OpenApiRestCall_612658
proc url_PostGetMetricStatistics_613875(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetMetricStatistics_613874(path: JsonNode; query: JsonNode;
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
  var valid_613876 = query.getOrDefault("Action")
  valid_613876 = validateParameter(valid_613876, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_613876 != nil:
    section.add "Action", valid_613876
  var valid_613877 = query.getOrDefault("Version")
  valid_613877 = validateParameter(valid_613877, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613877 != nil:
    section.add "Version", valid_613877
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
  var valid_613878 = header.getOrDefault("X-Amz-Signature")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Signature", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Content-Sha256", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Date")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Date", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Credential")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Credential", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Security-Token")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Security-Token", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Algorithm")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Algorithm", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-SignedHeaders", valid_613884
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
  var valid_613885 = formData.getOrDefault("Unit")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_613885 != nil:
    section.add "Unit", valid_613885
  assert formData != nil,
        "formData argument is necessary due to required `Period` field"
  var valid_613886 = formData.getOrDefault("Period")
  valid_613886 = validateParameter(valid_613886, JInt, required = true, default = nil)
  if valid_613886 != nil:
    section.add "Period", valid_613886
  var valid_613887 = formData.getOrDefault("Statistics")
  valid_613887 = validateParameter(valid_613887, JArray, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "Statistics", valid_613887
  var valid_613888 = formData.getOrDefault("ExtendedStatistics")
  valid_613888 = validateParameter(valid_613888, JArray, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "ExtendedStatistics", valid_613888
  var valid_613889 = formData.getOrDefault("EndTime")
  valid_613889 = validateParameter(valid_613889, JString, required = true,
                                 default = nil)
  if valid_613889 != nil:
    section.add "EndTime", valid_613889
  var valid_613890 = formData.getOrDefault("StartTime")
  valid_613890 = validateParameter(valid_613890, JString, required = true,
                                 default = nil)
  if valid_613890 != nil:
    section.add "StartTime", valid_613890
  var valid_613891 = formData.getOrDefault("MetricName")
  valid_613891 = validateParameter(valid_613891, JString, required = true,
                                 default = nil)
  if valid_613891 != nil:
    section.add "MetricName", valid_613891
  var valid_613892 = formData.getOrDefault("Dimensions")
  valid_613892 = validateParameter(valid_613892, JArray, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "Dimensions", valid_613892
  var valid_613893 = formData.getOrDefault("Namespace")
  valid_613893 = validateParameter(valid_613893, JString, required = true,
                                 default = nil)
  if valid_613893 != nil:
    section.add "Namespace", valid_613893
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613894: Call_PostGetMetricStatistics_613873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_613894.validator(path, query, header, formData, body)
  let scheme = call_613894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613894.url(scheme.get, call_613894.host, call_613894.base,
                         call_613894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613894, url, valid)

proc call*(call_613895: Call_PostGetMetricStatistics_613873; Period: int;
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
  var query_613896 = newJObject()
  var formData_613897 = newJObject()
  add(formData_613897, "Unit", newJString(Unit))
  add(formData_613897, "Period", newJInt(Period))
  if Statistics != nil:
    formData_613897.add "Statistics", Statistics
  if ExtendedStatistics != nil:
    formData_613897.add "ExtendedStatistics", ExtendedStatistics
  add(formData_613897, "EndTime", newJString(EndTime))
  add(formData_613897, "StartTime", newJString(StartTime))
  add(formData_613897, "MetricName", newJString(MetricName))
  add(query_613896, "Action", newJString(Action))
  if Dimensions != nil:
    formData_613897.add "Dimensions", Dimensions
  add(formData_613897, "Namespace", newJString(Namespace))
  add(query_613896, "Version", newJString(Version))
  result = call_613895.call(nil, query_613896, nil, formData_613897, nil)

var postGetMetricStatistics* = Call_PostGetMetricStatistics_613873(
    name: "postGetMetricStatistics", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_PostGetMetricStatistics_613874, base: "/",
    url: url_PostGetMetricStatistics_613875, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricStatistics_613849 = ref object of OpenApiRestCall_612658
proc url_GetGetMetricStatistics_613851(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricStatistics_613850(path: JsonNode; query: JsonNode;
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
  var valid_613852 = query.getOrDefault("Unit")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_613852 != nil:
    section.add "Unit", valid_613852
  var valid_613853 = query.getOrDefault("ExtendedStatistics")
  valid_613853 = validateParameter(valid_613853, JArray, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "ExtendedStatistics", valid_613853
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_613854 = query.getOrDefault("Namespace")
  valid_613854 = validateParameter(valid_613854, JString, required = true,
                                 default = nil)
  if valid_613854 != nil:
    section.add "Namespace", valid_613854
  var valid_613855 = query.getOrDefault("Statistics")
  valid_613855 = validateParameter(valid_613855, JArray, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "Statistics", valid_613855
  var valid_613856 = query.getOrDefault("Period")
  valid_613856 = validateParameter(valid_613856, JInt, required = true, default = nil)
  if valid_613856 != nil:
    section.add "Period", valid_613856
  var valid_613857 = query.getOrDefault("Dimensions")
  valid_613857 = validateParameter(valid_613857, JArray, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "Dimensions", valid_613857
  var valid_613858 = query.getOrDefault("Action")
  valid_613858 = validateParameter(valid_613858, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_613858 != nil:
    section.add "Action", valid_613858
  var valid_613859 = query.getOrDefault("StartTime")
  valid_613859 = validateParameter(valid_613859, JString, required = true,
                                 default = nil)
  if valid_613859 != nil:
    section.add "StartTime", valid_613859
  var valid_613860 = query.getOrDefault("EndTime")
  valid_613860 = validateParameter(valid_613860, JString, required = true,
                                 default = nil)
  if valid_613860 != nil:
    section.add "EndTime", valid_613860
  var valid_613861 = query.getOrDefault("Version")
  valid_613861 = validateParameter(valid_613861, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613861 != nil:
    section.add "Version", valid_613861
  var valid_613862 = query.getOrDefault("MetricName")
  valid_613862 = validateParameter(valid_613862, JString, required = true,
                                 default = nil)
  if valid_613862 != nil:
    section.add "MetricName", valid_613862
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
  var valid_613863 = header.getOrDefault("X-Amz-Signature")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Signature", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Content-Sha256", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Date")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Date", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Credential")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Credential", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Security-Token")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Security-Token", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Algorithm")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Algorithm", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-SignedHeaders", valid_613869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613870: Call_GetGetMetricStatistics_613849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_613870.validator(path, query, header, formData, body)
  let scheme = call_613870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613870.url(scheme.get, call_613870.host, call_613870.base,
                         call_613870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613870, url, valid)

proc call*(call_613871: Call_GetGetMetricStatistics_613849; Namespace: string;
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
  var query_613872 = newJObject()
  add(query_613872, "Unit", newJString(Unit))
  if ExtendedStatistics != nil:
    query_613872.add "ExtendedStatistics", ExtendedStatistics
  add(query_613872, "Namespace", newJString(Namespace))
  if Statistics != nil:
    query_613872.add "Statistics", Statistics
  add(query_613872, "Period", newJInt(Period))
  if Dimensions != nil:
    query_613872.add "Dimensions", Dimensions
  add(query_613872, "Action", newJString(Action))
  add(query_613872, "StartTime", newJString(StartTime))
  add(query_613872, "EndTime", newJString(EndTime))
  add(query_613872, "Version", newJString(Version))
  add(query_613872, "MetricName", newJString(MetricName))
  result = call_613871.call(nil, query_613872, nil, nil, nil)

var getGetMetricStatistics* = Call_GetGetMetricStatistics_613849(
    name: "getGetMetricStatistics", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_GetGetMetricStatistics_613850, base: "/",
    url: url_GetGetMetricStatistics_613851, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricWidgetImage_613915 = ref object of OpenApiRestCall_612658
proc url_PostGetMetricWidgetImage_613917(protocol: Scheme; host: string;
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

proc validate_PostGetMetricWidgetImage_613916(path: JsonNode; query: JsonNode;
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
  var valid_613918 = query.getOrDefault("Action")
  valid_613918 = validateParameter(valid_613918, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_613918 != nil:
    section.add "Action", valid_613918
  var valid_613919 = query.getOrDefault("Version")
  valid_613919 = validateParameter(valid_613919, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613919 != nil:
    section.add "Version", valid_613919
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
  var valid_613920 = header.getOrDefault("X-Amz-Signature")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-Signature", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-Content-Sha256", valid_613921
  var valid_613922 = header.getOrDefault("X-Amz-Date")
  valid_613922 = validateParameter(valid_613922, JString, required = false,
                                 default = nil)
  if valid_613922 != nil:
    section.add "X-Amz-Date", valid_613922
  var valid_613923 = header.getOrDefault("X-Amz-Credential")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "X-Amz-Credential", valid_613923
  var valid_613924 = header.getOrDefault("X-Amz-Security-Token")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-Security-Token", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Algorithm")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Algorithm", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-SignedHeaders", valid_613926
  result.add "header", section
  ## parameters in `formData` object:
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MetricWidget` field"
  var valid_613927 = formData.getOrDefault("MetricWidget")
  valid_613927 = validateParameter(valid_613927, JString, required = true,
                                 default = nil)
  if valid_613927 != nil:
    section.add "MetricWidget", valid_613927
  var valid_613928 = formData.getOrDefault("OutputFormat")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "OutputFormat", valid_613928
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613929: Call_PostGetMetricWidgetImage_613915; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_613929.validator(path, query, header, formData, body)
  let scheme = call_613929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613929.url(scheme.get, call_613929.host, call_613929.base,
                         call_613929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613929, url, valid)

proc call*(call_613930: Call_PostGetMetricWidgetImage_613915; MetricWidget: string;
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
  var query_613931 = newJObject()
  var formData_613932 = newJObject()
  add(formData_613932, "MetricWidget", newJString(MetricWidget))
  add(formData_613932, "OutputFormat", newJString(OutputFormat))
  add(query_613931, "Action", newJString(Action))
  add(query_613931, "Version", newJString(Version))
  result = call_613930.call(nil, query_613931, nil, formData_613932, nil)

var postGetMetricWidgetImage* = Call_PostGetMetricWidgetImage_613915(
    name: "postGetMetricWidgetImage", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_PostGetMetricWidgetImage_613916, base: "/",
    url: url_PostGetMetricWidgetImage_613917, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricWidgetImage_613898 = ref object of OpenApiRestCall_612658
proc url_GetGetMetricWidgetImage_613900(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricWidgetImage_613899(path: JsonNode; query: JsonNode;
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
  var valid_613901 = query.getOrDefault("OutputFormat")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "OutputFormat", valid_613901
  assert query != nil,
        "query argument is necessary due to required `MetricWidget` field"
  var valid_613902 = query.getOrDefault("MetricWidget")
  valid_613902 = validateParameter(valid_613902, JString, required = true,
                                 default = nil)
  if valid_613902 != nil:
    section.add "MetricWidget", valid_613902
  var valid_613903 = query.getOrDefault("Action")
  valid_613903 = validateParameter(valid_613903, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_613903 != nil:
    section.add "Action", valid_613903
  var valid_613904 = query.getOrDefault("Version")
  valid_613904 = validateParameter(valid_613904, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613904 != nil:
    section.add "Version", valid_613904
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
  var valid_613905 = header.getOrDefault("X-Amz-Signature")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-Signature", valid_613905
  var valid_613906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613906 = validateParameter(valid_613906, JString, required = false,
                                 default = nil)
  if valid_613906 != nil:
    section.add "X-Amz-Content-Sha256", valid_613906
  var valid_613907 = header.getOrDefault("X-Amz-Date")
  valid_613907 = validateParameter(valid_613907, JString, required = false,
                                 default = nil)
  if valid_613907 != nil:
    section.add "X-Amz-Date", valid_613907
  var valid_613908 = header.getOrDefault("X-Amz-Credential")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "X-Amz-Credential", valid_613908
  var valid_613909 = header.getOrDefault("X-Amz-Security-Token")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Security-Token", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Algorithm")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Algorithm", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-SignedHeaders", valid_613911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613912: Call_GetGetMetricWidgetImage_613898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_613912.validator(path, query, header, formData, body)
  let scheme = call_613912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613912.url(scheme.get, call_613912.host, call_613912.base,
                         call_613912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613912, url, valid)

proc call*(call_613913: Call_GetGetMetricWidgetImage_613898; MetricWidget: string;
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
  var query_613914 = newJObject()
  add(query_613914, "OutputFormat", newJString(OutputFormat))
  add(query_613914, "MetricWidget", newJString(MetricWidget))
  add(query_613914, "Action", newJString(Action))
  add(query_613914, "Version", newJString(Version))
  result = call_613913.call(nil, query_613914, nil, nil, nil)

var getGetMetricWidgetImage* = Call_GetGetMetricWidgetImage_613898(
    name: "getGetMetricWidgetImage", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_GetGetMetricWidgetImage_613899, base: "/",
    url: url_GetGetMetricWidgetImage_613900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDashboards_613950 = ref object of OpenApiRestCall_612658
proc url_PostListDashboards_613952(protocol: Scheme; host: string; base: string;
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

proc validate_PostListDashboards_613951(path: JsonNode; query: JsonNode;
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
  var valid_613953 = query.getOrDefault("Action")
  valid_613953 = validateParameter(valid_613953, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_613953 != nil:
    section.add "Action", valid_613953
  var valid_613954 = query.getOrDefault("Version")
  valid_613954 = validateParameter(valid_613954, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613954 != nil:
    section.add "Version", valid_613954
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
  var valid_613955 = header.getOrDefault("X-Amz-Signature")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Signature", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-Content-Sha256", valid_613956
  var valid_613957 = header.getOrDefault("X-Amz-Date")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-Date", valid_613957
  var valid_613958 = header.getOrDefault("X-Amz-Credential")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-Credential", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Security-Token")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Security-Token", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Algorithm")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Algorithm", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-SignedHeaders", valid_613961
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   DashboardNamePrefix: JString
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  section = newJObject()
  var valid_613962 = formData.getOrDefault("NextToken")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "NextToken", valid_613962
  var valid_613963 = formData.getOrDefault("DashboardNamePrefix")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "DashboardNamePrefix", valid_613963
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613964: Call_PostListDashboards_613950; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_613964.validator(path, query, header, formData, body)
  let scheme = call_613964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613964.url(scheme.get, call_613964.host, call_613964.base,
                         call_613964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613964, url, valid)

proc call*(call_613965: Call_PostListDashboards_613950; NextToken: string = "";
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
  var query_613966 = newJObject()
  var formData_613967 = newJObject()
  add(formData_613967, "NextToken", newJString(NextToken))
  add(formData_613967, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_613966, "Action", newJString(Action))
  add(query_613966, "Version", newJString(Version))
  result = call_613965.call(nil, query_613966, nil, formData_613967, nil)

var postListDashboards* = Call_PostListDashboards_613950(
    name: "postListDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListDashboards",
    validator: validate_PostListDashboards_613951, base: "/",
    url: url_PostListDashboards_613952, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDashboards_613933 = ref object of OpenApiRestCall_612658
proc url_GetListDashboards_613935(protocol: Scheme; host: string; base: string;
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

proc validate_GetListDashboards_613934(path: JsonNode; query: JsonNode;
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
  var valid_613936 = query.getOrDefault("DashboardNamePrefix")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "DashboardNamePrefix", valid_613936
  var valid_613937 = query.getOrDefault("NextToken")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "NextToken", valid_613937
  var valid_613938 = query.getOrDefault("Action")
  valid_613938 = validateParameter(valid_613938, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_613938 != nil:
    section.add "Action", valid_613938
  var valid_613939 = query.getOrDefault("Version")
  valid_613939 = validateParameter(valid_613939, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613939 != nil:
    section.add "Version", valid_613939
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
  var valid_613940 = header.getOrDefault("X-Amz-Signature")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "X-Amz-Signature", valid_613940
  var valid_613941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "X-Amz-Content-Sha256", valid_613941
  var valid_613942 = header.getOrDefault("X-Amz-Date")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-Date", valid_613942
  var valid_613943 = header.getOrDefault("X-Amz-Credential")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Credential", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Security-Token")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Security-Token", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Algorithm")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Algorithm", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-SignedHeaders", valid_613946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613947: Call_GetListDashboards_613933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_613947.validator(path, query, header, formData, body)
  let scheme = call_613947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613947.url(scheme.get, call_613947.host, call_613947.base,
                         call_613947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613947, url, valid)

proc call*(call_613948: Call_GetListDashboards_613933;
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
  var query_613949 = newJObject()
  add(query_613949, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_613949, "NextToken", newJString(NextToken))
  add(query_613949, "Action", newJString(Action))
  add(query_613949, "Version", newJString(Version))
  result = call_613948.call(nil, query_613949, nil, nil, nil)

var getListDashboards* = Call_GetListDashboards_613933(name: "getListDashboards",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListDashboards", validator: validate_GetListDashboards_613934,
    base: "/", url: url_GetListDashboards_613935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListMetrics_613987 = ref object of OpenApiRestCall_612658
proc url_PostListMetrics_613989(protocol: Scheme; host: string; base: string;
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

proc validate_PostListMetrics_613988(path: JsonNode; query: JsonNode;
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
  var valid_613990 = query.getOrDefault("Action")
  valid_613990 = validateParameter(valid_613990, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_613990 != nil:
    section.add "Action", valid_613990
  var valid_613991 = query.getOrDefault("Version")
  valid_613991 = validateParameter(valid_613991, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613991 != nil:
    section.add "Version", valid_613991
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
  var valid_613992 = header.getOrDefault("X-Amz-Signature")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Signature", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Content-Sha256", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Date")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Date", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Credential")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Credential", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-Security-Token")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-Security-Token", valid_613996
  var valid_613997 = header.getOrDefault("X-Amz-Algorithm")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Algorithm", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-SignedHeaders", valid_613998
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
  var valid_613999 = formData.getOrDefault("NextToken")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "NextToken", valid_613999
  var valid_614000 = formData.getOrDefault("MetricName")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "MetricName", valid_614000
  var valid_614001 = formData.getOrDefault("Dimensions")
  valid_614001 = validateParameter(valid_614001, JArray, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "Dimensions", valid_614001
  var valid_614002 = formData.getOrDefault("Namespace")
  valid_614002 = validateParameter(valid_614002, JString, required = false,
                                 default = nil)
  if valid_614002 != nil:
    section.add "Namespace", valid_614002
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614003: Call_PostListMetrics_613987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_614003.validator(path, query, header, formData, body)
  let scheme = call_614003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614003.url(scheme.get, call_614003.host, call_614003.base,
                         call_614003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614003, url, valid)

proc call*(call_614004: Call_PostListMetrics_613987; NextToken: string = "";
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
  var query_614005 = newJObject()
  var formData_614006 = newJObject()
  add(formData_614006, "NextToken", newJString(NextToken))
  add(formData_614006, "MetricName", newJString(MetricName))
  add(query_614005, "Action", newJString(Action))
  if Dimensions != nil:
    formData_614006.add "Dimensions", Dimensions
  add(formData_614006, "Namespace", newJString(Namespace))
  add(query_614005, "Version", newJString(Version))
  result = call_614004.call(nil, query_614005, nil, formData_614006, nil)

var postListMetrics* = Call_PostListMetrics_613987(name: "postListMetrics",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_PostListMetrics_613988,
    base: "/", url: url_PostListMetrics_613989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListMetrics_613968 = ref object of OpenApiRestCall_612658
proc url_GetListMetrics_613970(protocol: Scheme; host: string; base: string;
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

proc validate_GetListMetrics_613969(path: JsonNode; query: JsonNode;
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
  var valid_613971 = query.getOrDefault("NextToken")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "NextToken", valid_613971
  var valid_613972 = query.getOrDefault("Namespace")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "Namespace", valid_613972
  var valid_613973 = query.getOrDefault("Dimensions")
  valid_613973 = validateParameter(valid_613973, JArray, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "Dimensions", valid_613973
  var valid_613974 = query.getOrDefault("Action")
  valid_613974 = validateParameter(valid_613974, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_613974 != nil:
    section.add "Action", valid_613974
  var valid_613975 = query.getOrDefault("Version")
  valid_613975 = validateParameter(valid_613975, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_613975 != nil:
    section.add "Version", valid_613975
  var valid_613976 = query.getOrDefault("MetricName")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "MetricName", valid_613976
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
  var valid_613977 = header.getOrDefault("X-Amz-Signature")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Signature", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Content-Sha256", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Date")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Date", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-Credential")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Credential", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-Security-Token")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-Security-Token", valid_613981
  var valid_613982 = header.getOrDefault("X-Amz-Algorithm")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-Algorithm", valid_613982
  var valid_613983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-SignedHeaders", valid_613983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613984: Call_GetListMetrics_613968; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_613984.validator(path, query, header, formData, body)
  let scheme = call_613984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613984.url(scheme.get, call_613984.host, call_613984.base,
                         call_613984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613984, url, valid)

proc call*(call_613985: Call_GetListMetrics_613968; NextToken: string = "";
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
  var query_613986 = newJObject()
  add(query_613986, "NextToken", newJString(NextToken))
  add(query_613986, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_613986.add "Dimensions", Dimensions
  add(query_613986, "Action", newJString(Action))
  add(query_613986, "Version", newJString(Version))
  add(query_613986, "MetricName", newJString(MetricName))
  result = call_613985.call(nil, query_613986, nil, nil, nil)

var getListMetrics* = Call_GetListMetrics_613968(name: "getListMetrics",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_GetListMetrics_613969,
    base: "/", url: url_GetListMetrics_613970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_614023 = ref object of OpenApiRestCall_612658
proc url_PostListTagsForResource_614025(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_614024(path: JsonNode; query: JsonNode;
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
  var valid_614026 = query.getOrDefault("Action")
  valid_614026 = validateParameter(valid_614026, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614026 != nil:
    section.add "Action", valid_614026
  var valid_614027 = query.getOrDefault("Version")
  valid_614027 = validateParameter(valid_614027, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614027 != nil:
    section.add "Version", valid_614027
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
  var valid_614028 = header.getOrDefault("X-Amz-Signature")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Signature", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Content-Sha256", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-Date")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Date", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-Credential")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-Credential", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-Security-Token")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-Security-Token", valid_614032
  var valid_614033 = header.getOrDefault("X-Amz-Algorithm")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "X-Amz-Algorithm", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-SignedHeaders", valid_614034
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceARN` field"
  var valid_614035 = formData.getOrDefault("ResourceARN")
  valid_614035 = validateParameter(valid_614035, JString, required = true,
                                 default = nil)
  if valid_614035 != nil:
    section.add "ResourceARN", valid_614035
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614036: Call_PostListTagsForResource_614023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_614036.validator(path, query, header, formData, body)
  let scheme = call_614036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614036.url(scheme.get, call_614036.host, call_614036.base,
                         call_614036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614036, url, valid)

proc call*(call_614037: Call_PostListTagsForResource_614023; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## postListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  var query_614038 = newJObject()
  var formData_614039 = newJObject()
  add(query_614038, "Action", newJString(Action))
  add(query_614038, "Version", newJString(Version))
  add(formData_614039, "ResourceARN", newJString(ResourceARN))
  result = call_614037.call(nil, query_614038, nil, formData_614039, nil)

var postListTagsForResource* = Call_PostListTagsForResource_614023(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_614024, base: "/",
    url: url_PostListTagsForResource_614025, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_614007 = ref object of OpenApiRestCall_612658
proc url_GetListTagsForResource_614009(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_614008(path: JsonNode; query: JsonNode;
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
  var valid_614010 = query.getOrDefault("Action")
  valid_614010 = validateParameter(valid_614010, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614010 != nil:
    section.add "Action", valid_614010
  var valid_614011 = query.getOrDefault("ResourceARN")
  valid_614011 = validateParameter(valid_614011, JString, required = true,
                                 default = nil)
  if valid_614011 != nil:
    section.add "ResourceARN", valid_614011
  var valid_614012 = query.getOrDefault("Version")
  valid_614012 = validateParameter(valid_614012, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614012 != nil:
    section.add "Version", valid_614012
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
  var valid_614013 = header.getOrDefault("X-Amz-Signature")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Signature", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Content-Sha256", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-Date")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-Date", valid_614015
  var valid_614016 = header.getOrDefault("X-Amz-Credential")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-Credential", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-Security-Token")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-Security-Token", valid_614017
  var valid_614018 = header.getOrDefault("X-Amz-Algorithm")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "X-Amz-Algorithm", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-SignedHeaders", valid_614019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614020: Call_GetListTagsForResource_614007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_614020.validator(path, query, header, formData, body)
  let scheme = call_614020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614020.url(scheme.get, call_614020.host, call_614020.base,
                         call_614020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614020, url, valid)

proc call*(call_614021: Call_GetListTagsForResource_614007; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## getListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_614022 = newJObject()
  add(query_614022, "Action", newJString(Action))
  add(query_614022, "ResourceARN", newJString(ResourceARN))
  add(query_614022, "Version", newJString(Version))
  result = call_614021.call(nil, query_614022, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_614007(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_614008, base: "/",
    url: url_GetListTagsForResource_614009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAnomalyDetector_614061 = ref object of OpenApiRestCall_612658
proc url_PostPutAnomalyDetector_614063(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutAnomalyDetector_614062(path: JsonNode; query: JsonNode;
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
  var valid_614064 = query.getOrDefault("Action")
  valid_614064 = validateParameter(valid_614064, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_614064 != nil:
    section.add "Action", valid_614064
  var valid_614065 = query.getOrDefault("Version")
  valid_614065 = validateParameter(valid_614065, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614065 != nil:
    section.add "Version", valid_614065
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
  var valid_614066 = header.getOrDefault("X-Amz-Signature")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Signature", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Content-Sha256", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Date")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Date", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Credential")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Credential", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-Security-Token")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-Security-Token", valid_614070
  var valid_614071 = header.getOrDefault("X-Amz-Algorithm")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "X-Amz-Algorithm", valid_614071
  var valid_614072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614072 = validateParameter(valid_614072, JString, required = false,
                                 default = nil)
  if valid_614072 != nil:
    section.add "X-Amz-SignedHeaders", valid_614072
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
  var valid_614073 = formData.getOrDefault("Stat")
  valid_614073 = validateParameter(valid_614073, JString, required = true,
                                 default = nil)
  if valid_614073 != nil:
    section.add "Stat", valid_614073
  var valid_614074 = formData.getOrDefault("Configuration.MetricTimezone")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "Configuration.MetricTimezone", valid_614074
  var valid_614075 = formData.getOrDefault("MetricName")
  valid_614075 = validateParameter(valid_614075, JString, required = true,
                                 default = nil)
  if valid_614075 != nil:
    section.add "MetricName", valid_614075
  var valid_614076 = formData.getOrDefault("Dimensions")
  valid_614076 = validateParameter(valid_614076, JArray, required = false,
                                 default = nil)
  if valid_614076 != nil:
    section.add "Dimensions", valid_614076
  var valid_614077 = formData.getOrDefault("Namespace")
  valid_614077 = validateParameter(valid_614077, JString, required = true,
                                 default = nil)
  if valid_614077 != nil:
    section.add "Namespace", valid_614077
  var valid_614078 = formData.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_614078 = validateParameter(valid_614078, JArray, required = false,
                                 default = nil)
  if valid_614078 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_614078
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614079: Call_PostPutAnomalyDetector_614061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_614079.validator(path, query, header, formData, body)
  let scheme = call_614079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614079.url(scheme.get, call_614079.host, call_614079.base,
                         call_614079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614079, url, valid)

proc call*(call_614080: Call_PostPutAnomalyDetector_614061; Stat: string;
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
  var query_614081 = newJObject()
  var formData_614082 = newJObject()
  add(formData_614082, "Stat", newJString(Stat))
  add(formData_614082, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  add(formData_614082, "MetricName", newJString(MetricName))
  add(query_614081, "Action", newJString(Action))
  if Dimensions != nil:
    formData_614082.add "Dimensions", Dimensions
  add(formData_614082, "Namespace", newJString(Namespace))
  if ConfigurationExcludedTimeRanges != nil:
    formData_614082.add "Configuration.ExcludedTimeRanges",
                       ConfigurationExcludedTimeRanges
  add(query_614081, "Version", newJString(Version))
  result = call_614080.call(nil, query_614081, nil, formData_614082, nil)

var postPutAnomalyDetector* = Call_PostPutAnomalyDetector_614061(
    name: "postPutAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_PostPutAnomalyDetector_614062, base: "/",
    url: url_PostPutAnomalyDetector_614063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAnomalyDetector_614040 = ref object of OpenApiRestCall_612658
proc url_GetPutAnomalyDetector_614042(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutAnomalyDetector_614041(path: JsonNode; query: JsonNode;
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
  var valid_614043 = query.getOrDefault("Namespace")
  valid_614043 = validateParameter(valid_614043, JString, required = true,
                                 default = nil)
  if valid_614043 != nil:
    section.add "Namespace", valid_614043
  var valid_614044 = query.getOrDefault("Configuration.MetricTimezone")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "Configuration.MetricTimezone", valid_614044
  var valid_614045 = query.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_614045 = validateParameter(valid_614045, JArray, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_614045
  var valid_614046 = query.getOrDefault("Dimensions")
  valid_614046 = validateParameter(valid_614046, JArray, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "Dimensions", valid_614046
  var valid_614047 = query.getOrDefault("Action")
  valid_614047 = validateParameter(valid_614047, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_614047 != nil:
    section.add "Action", valid_614047
  var valid_614048 = query.getOrDefault("Version")
  valid_614048 = validateParameter(valid_614048, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614048 != nil:
    section.add "Version", valid_614048
  var valid_614049 = query.getOrDefault("MetricName")
  valid_614049 = validateParameter(valid_614049, JString, required = true,
                                 default = nil)
  if valid_614049 != nil:
    section.add "MetricName", valid_614049
  var valid_614050 = query.getOrDefault("Stat")
  valid_614050 = validateParameter(valid_614050, JString, required = true,
                                 default = nil)
  if valid_614050 != nil:
    section.add "Stat", valid_614050
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
  var valid_614051 = header.getOrDefault("X-Amz-Signature")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "X-Amz-Signature", valid_614051
  var valid_614052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Content-Sha256", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Date")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Date", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Credential")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Credential", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-Security-Token")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-Security-Token", valid_614055
  var valid_614056 = header.getOrDefault("X-Amz-Algorithm")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-Algorithm", valid_614056
  var valid_614057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614057 = validateParameter(valid_614057, JString, required = false,
                                 default = nil)
  if valid_614057 != nil:
    section.add "X-Amz-SignedHeaders", valid_614057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614058: Call_GetPutAnomalyDetector_614040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_614058.validator(path, query, header, formData, body)
  let scheme = call_614058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614058.url(scheme.get, call_614058.host, call_614058.base,
                         call_614058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614058, url, valid)

proc call*(call_614059: Call_GetPutAnomalyDetector_614040; Namespace: string;
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
  var query_614060 = newJObject()
  add(query_614060, "Namespace", newJString(Namespace))
  add(query_614060, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  if ConfigurationExcludedTimeRanges != nil:
    query_614060.add "Configuration.ExcludedTimeRanges",
                    ConfigurationExcludedTimeRanges
  if Dimensions != nil:
    query_614060.add "Dimensions", Dimensions
  add(query_614060, "Action", newJString(Action))
  add(query_614060, "Version", newJString(Version))
  add(query_614060, "MetricName", newJString(MetricName))
  add(query_614060, "Stat", newJString(Stat))
  result = call_614059.call(nil, query_614060, nil, nil, nil)

var getPutAnomalyDetector* = Call_GetPutAnomalyDetector_614040(
    name: "getPutAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_GetPutAnomalyDetector_614041, base: "/",
    url: url_GetPutAnomalyDetector_614042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutDashboard_614100 = ref object of OpenApiRestCall_612658
proc url_PostPutDashboard_614102(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutDashboard_614101(path: JsonNode; query: JsonNode;
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
  var valid_614103 = query.getOrDefault("Action")
  valid_614103 = validateParameter(valid_614103, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_614103 != nil:
    section.add "Action", valid_614103
  var valid_614104 = query.getOrDefault("Version")
  valid_614104 = validateParameter(valid_614104, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614104 != nil:
    section.add "Version", valid_614104
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
  var valid_614105 = header.getOrDefault("X-Amz-Signature")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Signature", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Content-Sha256", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Date")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Date", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-Credential")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-Credential", valid_614108
  var valid_614109 = header.getOrDefault("X-Amz-Security-Token")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "X-Amz-Security-Token", valid_614109
  var valid_614110 = header.getOrDefault("X-Amz-Algorithm")
  valid_614110 = validateParameter(valid_614110, JString, required = false,
                                 default = nil)
  if valid_614110 != nil:
    section.add "X-Amz-Algorithm", valid_614110
  var valid_614111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "X-Amz-SignedHeaders", valid_614111
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_614112 = formData.getOrDefault("DashboardName")
  valid_614112 = validateParameter(valid_614112, JString, required = true,
                                 default = nil)
  if valid_614112 != nil:
    section.add "DashboardName", valid_614112
  var valid_614113 = formData.getOrDefault("DashboardBody")
  valid_614113 = validateParameter(valid_614113, JString, required = true,
                                 default = nil)
  if valid_614113 != nil:
    section.add "DashboardBody", valid_614113
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614114: Call_PostPutDashboard_614100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_614114.validator(path, query, header, formData, body)
  let scheme = call_614114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614114.url(scheme.get, call_614114.host, call_614114.base,
                         call_614114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614114, url, valid)

proc call*(call_614115: Call_PostPutDashboard_614100; DashboardName: string;
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
  var query_614116 = newJObject()
  var formData_614117 = newJObject()
  add(formData_614117, "DashboardName", newJString(DashboardName))
  add(query_614116, "Action", newJString(Action))
  add(formData_614117, "DashboardBody", newJString(DashboardBody))
  add(query_614116, "Version", newJString(Version))
  result = call_614115.call(nil, query_614116, nil, formData_614117, nil)

var postPutDashboard* = Call_PostPutDashboard_614100(name: "postPutDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_PostPutDashboard_614101,
    base: "/", url: url_PostPutDashboard_614102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutDashboard_614083 = ref object of OpenApiRestCall_612658
proc url_GetPutDashboard_614085(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutDashboard_614084(path: JsonNode; query: JsonNode;
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
  var valid_614086 = query.getOrDefault("DashboardBody")
  valid_614086 = validateParameter(valid_614086, JString, required = true,
                                 default = nil)
  if valid_614086 != nil:
    section.add "DashboardBody", valid_614086
  var valid_614087 = query.getOrDefault("Action")
  valid_614087 = validateParameter(valid_614087, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_614087 != nil:
    section.add "Action", valid_614087
  var valid_614088 = query.getOrDefault("DashboardName")
  valid_614088 = validateParameter(valid_614088, JString, required = true,
                                 default = nil)
  if valid_614088 != nil:
    section.add "DashboardName", valid_614088
  var valid_614089 = query.getOrDefault("Version")
  valid_614089 = validateParameter(valid_614089, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614089 != nil:
    section.add "Version", valid_614089
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
  var valid_614090 = header.getOrDefault("X-Amz-Signature")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Signature", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Content-Sha256", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Date")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Date", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-Credential")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Credential", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-Security-Token")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-Security-Token", valid_614094
  var valid_614095 = header.getOrDefault("X-Amz-Algorithm")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "X-Amz-Algorithm", valid_614095
  var valid_614096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614096 = validateParameter(valid_614096, JString, required = false,
                                 default = nil)
  if valid_614096 != nil:
    section.add "X-Amz-SignedHeaders", valid_614096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614097: Call_GetPutDashboard_614083; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_614097.validator(path, query, header, formData, body)
  let scheme = call_614097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614097.url(scheme.get, call_614097.host, call_614097.base,
                         call_614097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614097, url, valid)

proc call*(call_614098: Call_GetPutDashboard_614083; DashboardBody: string;
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
  var query_614099 = newJObject()
  add(query_614099, "DashboardBody", newJString(DashboardBody))
  add(query_614099, "Action", newJString(Action))
  add(query_614099, "DashboardName", newJString(DashboardName))
  add(query_614099, "Version", newJString(Version))
  result = call_614098.call(nil, query_614099, nil, nil, nil)

var getPutDashboard* = Call_GetPutDashboard_614083(name: "getPutDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_GetPutDashboard_614084,
    base: "/", url: url_GetPutDashboard_614085, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutInsightRule_614136 = ref object of OpenApiRestCall_612658
proc url_PostPutInsightRule_614138(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutInsightRule_614137(path: JsonNode; query: JsonNode;
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
  var valid_614139 = query.getOrDefault("Action")
  valid_614139 = validateParameter(valid_614139, JString, required = true,
                                 default = newJString("PutInsightRule"))
  if valid_614139 != nil:
    section.add "Action", valid_614139
  var valid_614140 = query.getOrDefault("Version")
  valid_614140 = validateParameter(valid_614140, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614140 != nil:
    section.add "Version", valid_614140
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
  var valid_614141 = header.getOrDefault("X-Amz-Signature")
  valid_614141 = validateParameter(valid_614141, JString, required = false,
                                 default = nil)
  if valid_614141 != nil:
    section.add "X-Amz-Signature", valid_614141
  var valid_614142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Content-Sha256", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-Date")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Date", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Credential")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Credential", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-Security-Token")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-Security-Token", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-Algorithm")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Algorithm", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-SignedHeaders", valid_614147
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
  var valid_614148 = formData.getOrDefault("RuleName")
  valid_614148 = validateParameter(valid_614148, JString, required = true,
                                 default = nil)
  if valid_614148 != nil:
    section.add "RuleName", valid_614148
  var valid_614149 = formData.getOrDefault("RuleState")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "RuleState", valid_614149
  var valid_614150 = formData.getOrDefault("RuleDefinition")
  valid_614150 = validateParameter(valid_614150, JString, required = true,
                                 default = nil)
  if valid_614150 != nil:
    section.add "RuleDefinition", valid_614150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614151: Call_PostPutInsightRule_614136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_614151.validator(path, query, header, formData, body)
  let scheme = call_614151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614151.url(scheme.get, call_614151.host, call_614151.base,
                         call_614151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614151, url, valid)

proc call*(call_614152: Call_PostPutInsightRule_614136; RuleName: string;
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
  var query_614153 = newJObject()
  var formData_614154 = newJObject()
  add(formData_614154, "RuleName", newJString(RuleName))
  add(formData_614154, "RuleState", newJString(RuleState))
  add(query_614153, "Action", newJString(Action))
  add(query_614153, "Version", newJString(Version))
  add(formData_614154, "RuleDefinition", newJString(RuleDefinition))
  result = call_614152.call(nil, query_614153, nil, formData_614154, nil)

var postPutInsightRule* = Call_PostPutInsightRule_614136(
    name: "postPutInsightRule", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutInsightRule",
    validator: validate_PostPutInsightRule_614137, base: "/",
    url: url_PostPutInsightRule_614138, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutInsightRule_614118 = ref object of OpenApiRestCall_612658
proc url_GetPutInsightRule_614120(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutInsightRule_614119(path: JsonNode; query: JsonNode;
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
  var valid_614121 = query.getOrDefault("RuleName")
  valid_614121 = validateParameter(valid_614121, JString, required = true,
                                 default = nil)
  if valid_614121 != nil:
    section.add "RuleName", valid_614121
  var valid_614122 = query.getOrDefault("RuleDefinition")
  valid_614122 = validateParameter(valid_614122, JString, required = true,
                                 default = nil)
  if valid_614122 != nil:
    section.add "RuleDefinition", valid_614122
  var valid_614123 = query.getOrDefault("Action")
  valid_614123 = validateParameter(valid_614123, JString, required = true,
                                 default = newJString("PutInsightRule"))
  if valid_614123 != nil:
    section.add "Action", valid_614123
  var valid_614124 = query.getOrDefault("Version")
  valid_614124 = validateParameter(valid_614124, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614124 != nil:
    section.add "Version", valid_614124
  var valid_614125 = query.getOrDefault("RuleState")
  valid_614125 = validateParameter(valid_614125, JString, required = false,
                                 default = nil)
  if valid_614125 != nil:
    section.add "RuleState", valid_614125
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
  var valid_614126 = header.getOrDefault("X-Amz-Signature")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "X-Amz-Signature", valid_614126
  var valid_614127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "X-Amz-Content-Sha256", valid_614127
  var valid_614128 = header.getOrDefault("X-Amz-Date")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "X-Amz-Date", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Credential")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Credential", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-Security-Token")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Security-Token", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-Algorithm")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Algorithm", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-SignedHeaders", valid_614132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614133: Call_GetPutInsightRule_614118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_614133.validator(path, query, header, formData, body)
  let scheme = call_614133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614133.url(scheme.get, call_614133.host, call_614133.base,
                         call_614133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614133, url, valid)

proc call*(call_614134: Call_GetPutInsightRule_614118; RuleName: string;
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
  var query_614135 = newJObject()
  add(query_614135, "RuleName", newJString(RuleName))
  add(query_614135, "RuleDefinition", newJString(RuleDefinition))
  add(query_614135, "Action", newJString(Action))
  add(query_614135, "Version", newJString(Version))
  add(query_614135, "RuleState", newJString(RuleState))
  result = call_614134.call(nil, query_614135, nil, nil, nil)

var getPutInsightRule* = Call_GetPutInsightRule_614118(name: "getPutInsightRule",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutInsightRule", validator: validate_GetPutInsightRule_614119,
    base: "/", url: url_GetPutInsightRule_614120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricAlarm_614192 = ref object of OpenApiRestCall_612658
proc url_PostPutMetricAlarm_614194(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutMetricAlarm_614193(path: JsonNode; query: JsonNode;
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
  var valid_614195 = query.getOrDefault("Action")
  valid_614195 = validateParameter(valid_614195, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_614195 != nil:
    section.add "Action", valid_614195
  var valid_614196 = query.getOrDefault("Version")
  valid_614196 = validateParameter(valid_614196, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614196 != nil:
    section.add "Version", valid_614196
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
  var valid_614197 = header.getOrDefault("X-Amz-Signature")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "X-Amz-Signature", valid_614197
  var valid_614198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "X-Amz-Content-Sha256", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Date")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Date", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-Credential")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-Credential", valid_614200
  var valid_614201 = header.getOrDefault("X-Amz-Security-Token")
  valid_614201 = validateParameter(valid_614201, JString, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "X-Amz-Security-Token", valid_614201
  var valid_614202 = header.getOrDefault("X-Amz-Algorithm")
  valid_614202 = validateParameter(valid_614202, JString, required = false,
                                 default = nil)
  if valid_614202 != nil:
    section.add "X-Amz-Algorithm", valid_614202
  var valid_614203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614203 = validateParameter(valid_614203, JString, required = false,
                                 default = nil)
  if valid_614203 != nil:
    section.add "X-Amz-SignedHeaders", valid_614203
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
  var valid_614204 = formData.getOrDefault("ActionsEnabled")
  valid_614204 = validateParameter(valid_614204, JBool, required = false, default = nil)
  if valid_614204 != nil:
    section.add "ActionsEnabled", valid_614204
  var valid_614205 = formData.getOrDefault("AlarmDescription")
  valid_614205 = validateParameter(valid_614205, JString, required = false,
                                 default = nil)
  if valid_614205 != nil:
    section.add "AlarmDescription", valid_614205
  assert formData != nil,
        "formData argument is necessary due to required `AlarmName` field"
  var valid_614206 = formData.getOrDefault("AlarmName")
  valid_614206 = validateParameter(valid_614206, JString, required = true,
                                 default = nil)
  if valid_614206 != nil:
    section.add "AlarmName", valid_614206
  var valid_614207 = formData.getOrDefault("ThresholdMetricId")
  valid_614207 = validateParameter(valid_614207, JString, required = false,
                                 default = nil)
  if valid_614207 != nil:
    section.add "ThresholdMetricId", valid_614207
  var valid_614208 = formData.getOrDefault("Unit")
  valid_614208 = validateParameter(valid_614208, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_614208 != nil:
    section.add "Unit", valid_614208
  var valid_614209 = formData.getOrDefault("Period")
  valid_614209 = validateParameter(valid_614209, JInt, required = false, default = nil)
  if valid_614209 != nil:
    section.add "Period", valid_614209
  var valid_614210 = formData.getOrDefault("AlarmActions")
  valid_614210 = validateParameter(valid_614210, JArray, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "AlarmActions", valid_614210
  var valid_614211 = formData.getOrDefault("ComparisonOperator")
  valid_614211 = validateParameter(valid_614211, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_614211 != nil:
    section.add "ComparisonOperator", valid_614211
  var valid_614212 = formData.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_614212
  var valid_614213 = formData.getOrDefault("OKActions")
  valid_614213 = validateParameter(valid_614213, JArray, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "OKActions", valid_614213
  var valid_614214 = formData.getOrDefault("Statistic")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_614214 != nil:
    section.add "Statistic", valid_614214
  var valid_614215 = formData.getOrDefault("TreatMissingData")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "TreatMissingData", valid_614215
  var valid_614216 = formData.getOrDefault("InsufficientDataActions")
  valid_614216 = validateParameter(valid_614216, JArray, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "InsufficientDataActions", valid_614216
  var valid_614217 = formData.getOrDefault("DatapointsToAlarm")
  valid_614217 = validateParameter(valid_614217, JInt, required = false, default = nil)
  if valid_614217 != nil:
    section.add "DatapointsToAlarm", valid_614217
  var valid_614218 = formData.getOrDefault("MetricName")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "MetricName", valid_614218
  var valid_614219 = formData.getOrDefault("Dimensions")
  valid_614219 = validateParameter(valid_614219, JArray, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "Dimensions", valid_614219
  var valid_614220 = formData.getOrDefault("Tags")
  valid_614220 = validateParameter(valid_614220, JArray, required = false,
                                 default = nil)
  if valid_614220 != nil:
    section.add "Tags", valid_614220
  var valid_614221 = formData.getOrDefault("Namespace")
  valid_614221 = validateParameter(valid_614221, JString, required = false,
                                 default = nil)
  if valid_614221 != nil:
    section.add "Namespace", valid_614221
  var valid_614222 = formData.getOrDefault("ExtendedStatistic")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "ExtendedStatistic", valid_614222
  var valid_614223 = formData.getOrDefault("EvaluationPeriods")
  valid_614223 = validateParameter(valid_614223, JInt, required = true, default = nil)
  if valid_614223 != nil:
    section.add "EvaluationPeriods", valid_614223
  var valid_614224 = formData.getOrDefault("Threshold")
  valid_614224 = validateParameter(valid_614224, JFloat, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "Threshold", valid_614224
  var valid_614225 = formData.getOrDefault("Metrics")
  valid_614225 = validateParameter(valid_614225, JArray, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "Metrics", valid_614225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614226: Call_PostPutMetricAlarm_614192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_614226.validator(path, query, header, formData, body)
  let scheme = call_614226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614226.url(scheme.get, call_614226.host, call_614226.base,
                         call_614226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614226, url, valid)

proc call*(call_614227: Call_PostPutMetricAlarm_614192; AlarmName: string;
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
  var query_614228 = newJObject()
  var formData_614229 = newJObject()
  add(formData_614229, "ActionsEnabled", newJBool(ActionsEnabled))
  add(formData_614229, "AlarmDescription", newJString(AlarmDescription))
  add(formData_614229, "AlarmName", newJString(AlarmName))
  add(formData_614229, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(formData_614229, "Unit", newJString(Unit))
  add(formData_614229, "Period", newJInt(Period))
  if AlarmActions != nil:
    formData_614229.add "AlarmActions", AlarmActions
  add(formData_614229, "ComparisonOperator", newJString(ComparisonOperator))
  add(formData_614229, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  if OKActions != nil:
    formData_614229.add "OKActions", OKActions
  add(formData_614229, "Statistic", newJString(Statistic))
  add(formData_614229, "TreatMissingData", newJString(TreatMissingData))
  if InsufficientDataActions != nil:
    formData_614229.add "InsufficientDataActions", InsufficientDataActions
  add(formData_614229, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(formData_614229, "MetricName", newJString(MetricName))
  add(query_614228, "Action", newJString(Action))
  if Dimensions != nil:
    formData_614229.add "Dimensions", Dimensions
  if Tags != nil:
    formData_614229.add "Tags", Tags
  add(formData_614229, "Namespace", newJString(Namespace))
  add(formData_614229, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_614228, "Version", newJString(Version))
  add(formData_614229, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(formData_614229, "Threshold", newJFloat(Threshold))
  if Metrics != nil:
    formData_614229.add "Metrics", Metrics
  result = call_614227.call(nil, query_614228, nil, formData_614229, nil)

var postPutMetricAlarm* = Call_PostPutMetricAlarm_614192(
    name: "postPutMetricAlarm", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutMetricAlarm",
    validator: validate_PostPutMetricAlarm_614193, base: "/",
    url: url_PostPutMetricAlarm_614194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricAlarm_614155 = ref object of OpenApiRestCall_612658
proc url_GetPutMetricAlarm_614157(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutMetricAlarm_614156(path: JsonNode; query: JsonNode;
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
  var valid_614158 = query.getOrDefault("InsufficientDataActions")
  valid_614158 = validateParameter(valid_614158, JArray, required = false,
                                 default = nil)
  if valid_614158 != nil:
    section.add "InsufficientDataActions", valid_614158
  var valid_614159 = query.getOrDefault("Statistic")
  valid_614159 = validateParameter(valid_614159, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_614159 != nil:
    section.add "Statistic", valid_614159
  var valid_614160 = query.getOrDefault("AlarmDescription")
  valid_614160 = validateParameter(valid_614160, JString, required = false,
                                 default = nil)
  if valid_614160 != nil:
    section.add "AlarmDescription", valid_614160
  var valid_614161 = query.getOrDefault("Unit")
  valid_614161 = validateParameter(valid_614161, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_614161 != nil:
    section.add "Unit", valid_614161
  var valid_614162 = query.getOrDefault("DatapointsToAlarm")
  valid_614162 = validateParameter(valid_614162, JInt, required = false, default = nil)
  if valid_614162 != nil:
    section.add "DatapointsToAlarm", valid_614162
  var valid_614163 = query.getOrDefault("Threshold")
  valid_614163 = validateParameter(valid_614163, JFloat, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "Threshold", valid_614163
  var valid_614164 = query.getOrDefault("Tags")
  valid_614164 = validateParameter(valid_614164, JArray, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "Tags", valid_614164
  var valid_614165 = query.getOrDefault("ThresholdMetricId")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "ThresholdMetricId", valid_614165
  var valid_614166 = query.getOrDefault("Namespace")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "Namespace", valid_614166
  var valid_614167 = query.getOrDefault("TreatMissingData")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "TreatMissingData", valid_614167
  var valid_614168 = query.getOrDefault("ExtendedStatistic")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "ExtendedStatistic", valid_614168
  var valid_614169 = query.getOrDefault("OKActions")
  valid_614169 = validateParameter(valid_614169, JArray, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "OKActions", valid_614169
  var valid_614170 = query.getOrDefault("Dimensions")
  valid_614170 = validateParameter(valid_614170, JArray, required = false,
                                 default = nil)
  if valid_614170 != nil:
    section.add "Dimensions", valid_614170
  var valid_614171 = query.getOrDefault("Period")
  valid_614171 = validateParameter(valid_614171, JInt, required = false, default = nil)
  if valid_614171 != nil:
    section.add "Period", valid_614171
  assert query != nil,
        "query argument is necessary due to required `AlarmName` field"
  var valid_614172 = query.getOrDefault("AlarmName")
  valid_614172 = validateParameter(valid_614172, JString, required = true,
                                 default = nil)
  if valid_614172 != nil:
    section.add "AlarmName", valid_614172
  var valid_614173 = query.getOrDefault("Action")
  valid_614173 = validateParameter(valid_614173, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_614173 != nil:
    section.add "Action", valid_614173
  var valid_614174 = query.getOrDefault("EvaluationPeriods")
  valid_614174 = validateParameter(valid_614174, JInt, required = true, default = nil)
  if valid_614174 != nil:
    section.add "EvaluationPeriods", valid_614174
  var valid_614175 = query.getOrDefault("ActionsEnabled")
  valid_614175 = validateParameter(valid_614175, JBool, required = false, default = nil)
  if valid_614175 != nil:
    section.add "ActionsEnabled", valid_614175
  var valid_614176 = query.getOrDefault("ComparisonOperator")
  valid_614176 = validateParameter(valid_614176, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_614176 != nil:
    section.add "ComparisonOperator", valid_614176
  var valid_614177 = query.getOrDefault("AlarmActions")
  valid_614177 = validateParameter(valid_614177, JArray, required = false,
                                 default = nil)
  if valid_614177 != nil:
    section.add "AlarmActions", valid_614177
  var valid_614178 = query.getOrDefault("Metrics")
  valid_614178 = validateParameter(valid_614178, JArray, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "Metrics", valid_614178
  var valid_614179 = query.getOrDefault("Version")
  valid_614179 = validateParameter(valid_614179, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614179 != nil:
    section.add "Version", valid_614179
  var valid_614180 = query.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_614180
  var valid_614181 = query.getOrDefault("MetricName")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "MetricName", valid_614181
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
  var valid_614182 = header.getOrDefault("X-Amz-Signature")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Signature", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Content-Sha256", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-Date")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-Date", valid_614184
  var valid_614185 = header.getOrDefault("X-Amz-Credential")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "X-Amz-Credential", valid_614185
  var valid_614186 = header.getOrDefault("X-Amz-Security-Token")
  valid_614186 = validateParameter(valid_614186, JString, required = false,
                                 default = nil)
  if valid_614186 != nil:
    section.add "X-Amz-Security-Token", valid_614186
  var valid_614187 = header.getOrDefault("X-Amz-Algorithm")
  valid_614187 = validateParameter(valid_614187, JString, required = false,
                                 default = nil)
  if valid_614187 != nil:
    section.add "X-Amz-Algorithm", valid_614187
  var valid_614188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614188 = validateParameter(valid_614188, JString, required = false,
                                 default = nil)
  if valid_614188 != nil:
    section.add "X-Amz-SignedHeaders", valid_614188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614189: Call_GetPutMetricAlarm_614155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_614189.validator(path, query, header, formData, body)
  let scheme = call_614189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614189.url(scheme.get, call_614189.host, call_614189.base,
                         call_614189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614189, url, valid)

proc call*(call_614190: Call_GetPutMetricAlarm_614155; AlarmName: string;
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
  var query_614191 = newJObject()
  if InsufficientDataActions != nil:
    query_614191.add "InsufficientDataActions", InsufficientDataActions
  add(query_614191, "Statistic", newJString(Statistic))
  add(query_614191, "AlarmDescription", newJString(AlarmDescription))
  add(query_614191, "Unit", newJString(Unit))
  add(query_614191, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(query_614191, "Threshold", newJFloat(Threshold))
  if Tags != nil:
    query_614191.add "Tags", Tags
  add(query_614191, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_614191, "Namespace", newJString(Namespace))
  add(query_614191, "TreatMissingData", newJString(TreatMissingData))
  add(query_614191, "ExtendedStatistic", newJString(ExtendedStatistic))
  if OKActions != nil:
    query_614191.add "OKActions", OKActions
  if Dimensions != nil:
    query_614191.add "Dimensions", Dimensions
  add(query_614191, "Period", newJInt(Period))
  add(query_614191, "AlarmName", newJString(AlarmName))
  add(query_614191, "Action", newJString(Action))
  add(query_614191, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(query_614191, "ActionsEnabled", newJBool(ActionsEnabled))
  add(query_614191, "ComparisonOperator", newJString(ComparisonOperator))
  if AlarmActions != nil:
    query_614191.add "AlarmActions", AlarmActions
  if Metrics != nil:
    query_614191.add "Metrics", Metrics
  add(query_614191, "Version", newJString(Version))
  add(query_614191, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  add(query_614191, "MetricName", newJString(MetricName))
  result = call_614190.call(nil, query_614191, nil, nil, nil)

var getPutMetricAlarm* = Call_GetPutMetricAlarm_614155(name: "getPutMetricAlarm",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricAlarm", validator: validate_GetPutMetricAlarm_614156,
    base: "/", url: url_GetPutMetricAlarm_614157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricData_614247 = ref object of OpenApiRestCall_612658
proc url_PostPutMetricData_614249(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutMetricData_614248(path: JsonNode; query: JsonNode;
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
  var valid_614250 = query.getOrDefault("Action")
  valid_614250 = validateParameter(valid_614250, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_614250 != nil:
    section.add "Action", valid_614250
  var valid_614251 = query.getOrDefault("Version")
  valid_614251 = validateParameter(valid_614251, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614251 != nil:
    section.add "Version", valid_614251
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
  var valid_614252 = header.getOrDefault("X-Amz-Signature")
  valid_614252 = validateParameter(valid_614252, JString, required = false,
                                 default = nil)
  if valid_614252 != nil:
    section.add "X-Amz-Signature", valid_614252
  var valid_614253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "X-Amz-Content-Sha256", valid_614253
  var valid_614254 = header.getOrDefault("X-Amz-Date")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "X-Amz-Date", valid_614254
  var valid_614255 = header.getOrDefault("X-Amz-Credential")
  valid_614255 = validateParameter(valid_614255, JString, required = false,
                                 default = nil)
  if valid_614255 != nil:
    section.add "X-Amz-Credential", valid_614255
  var valid_614256 = header.getOrDefault("X-Amz-Security-Token")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "X-Amz-Security-Token", valid_614256
  var valid_614257 = header.getOrDefault("X-Amz-Algorithm")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "X-Amz-Algorithm", valid_614257
  var valid_614258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614258 = validateParameter(valid_614258, JString, required = false,
                                 default = nil)
  if valid_614258 != nil:
    section.add "X-Amz-SignedHeaders", valid_614258
  result.add "header", section
  ## parameters in `formData` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Namespace` field"
  var valid_614259 = formData.getOrDefault("Namespace")
  valid_614259 = validateParameter(valid_614259, JString, required = true,
                                 default = nil)
  if valid_614259 != nil:
    section.add "Namespace", valid_614259
  var valid_614260 = formData.getOrDefault("MetricData")
  valid_614260 = validateParameter(valid_614260, JArray, required = true, default = nil)
  if valid_614260 != nil:
    section.add "MetricData", valid_614260
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614261: Call_PostPutMetricData_614247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_614261.validator(path, query, header, formData, body)
  let scheme = call_614261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614261.url(scheme.get, call_614261.host, call_614261.base,
                         call_614261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614261, url, valid)

proc call*(call_614262: Call_PostPutMetricData_614247; Namespace: string;
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
  var query_614263 = newJObject()
  var formData_614264 = newJObject()
  add(query_614263, "Action", newJString(Action))
  add(formData_614264, "Namespace", newJString(Namespace))
  if MetricData != nil:
    formData_614264.add "MetricData", MetricData
  add(query_614263, "Version", newJString(Version))
  result = call_614262.call(nil, query_614263, nil, formData_614264, nil)

var postPutMetricData* = Call_PostPutMetricData_614247(name: "postPutMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_PostPutMetricData_614248,
    base: "/", url: url_PostPutMetricData_614249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricData_614230 = ref object of OpenApiRestCall_612658
proc url_GetPutMetricData_614232(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutMetricData_614231(path: JsonNode; query: JsonNode;
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
  var valid_614233 = query.getOrDefault("Namespace")
  valid_614233 = validateParameter(valid_614233, JString, required = true,
                                 default = nil)
  if valid_614233 != nil:
    section.add "Namespace", valid_614233
  var valid_614234 = query.getOrDefault("Action")
  valid_614234 = validateParameter(valid_614234, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_614234 != nil:
    section.add "Action", valid_614234
  var valid_614235 = query.getOrDefault("Version")
  valid_614235 = validateParameter(valid_614235, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614235 != nil:
    section.add "Version", valid_614235
  var valid_614236 = query.getOrDefault("MetricData")
  valid_614236 = validateParameter(valid_614236, JArray, required = true, default = nil)
  if valid_614236 != nil:
    section.add "MetricData", valid_614236
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
  var valid_614237 = header.getOrDefault("X-Amz-Signature")
  valid_614237 = validateParameter(valid_614237, JString, required = false,
                                 default = nil)
  if valid_614237 != nil:
    section.add "X-Amz-Signature", valid_614237
  var valid_614238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614238 = validateParameter(valid_614238, JString, required = false,
                                 default = nil)
  if valid_614238 != nil:
    section.add "X-Amz-Content-Sha256", valid_614238
  var valid_614239 = header.getOrDefault("X-Amz-Date")
  valid_614239 = validateParameter(valid_614239, JString, required = false,
                                 default = nil)
  if valid_614239 != nil:
    section.add "X-Amz-Date", valid_614239
  var valid_614240 = header.getOrDefault("X-Amz-Credential")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "X-Amz-Credential", valid_614240
  var valid_614241 = header.getOrDefault("X-Amz-Security-Token")
  valid_614241 = validateParameter(valid_614241, JString, required = false,
                                 default = nil)
  if valid_614241 != nil:
    section.add "X-Amz-Security-Token", valid_614241
  var valid_614242 = header.getOrDefault("X-Amz-Algorithm")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "X-Amz-Algorithm", valid_614242
  var valid_614243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "X-Amz-SignedHeaders", valid_614243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614244: Call_GetPutMetricData_614230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_614244.validator(path, query, header, formData, body)
  let scheme = call_614244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614244.url(scheme.get, call_614244.host, call_614244.base,
                         call_614244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614244, url, valid)

proc call*(call_614245: Call_GetPutMetricData_614230; Namespace: string;
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
  var query_614246 = newJObject()
  add(query_614246, "Namespace", newJString(Namespace))
  add(query_614246, "Action", newJString(Action))
  add(query_614246, "Version", newJString(Version))
  if MetricData != nil:
    query_614246.add "MetricData", MetricData
  result = call_614245.call(nil, query_614246, nil, nil, nil)

var getPutMetricData* = Call_GetPutMetricData_614230(name: "getPutMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_GetPutMetricData_614231,
    base: "/", url: url_GetPutMetricData_614232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetAlarmState_614284 = ref object of OpenApiRestCall_612658
proc url_PostSetAlarmState_614286(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetAlarmState_614285(path: JsonNode; query: JsonNode;
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
  var valid_614287 = query.getOrDefault("Action")
  valid_614287 = validateParameter(valid_614287, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_614287 != nil:
    section.add "Action", valid_614287
  var valid_614288 = query.getOrDefault("Version")
  valid_614288 = validateParameter(valid_614288, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614288 != nil:
    section.add "Version", valid_614288
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
  var valid_614289 = header.getOrDefault("X-Amz-Signature")
  valid_614289 = validateParameter(valid_614289, JString, required = false,
                                 default = nil)
  if valid_614289 != nil:
    section.add "X-Amz-Signature", valid_614289
  var valid_614290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "X-Amz-Content-Sha256", valid_614290
  var valid_614291 = header.getOrDefault("X-Amz-Date")
  valid_614291 = validateParameter(valid_614291, JString, required = false,
                                 default = nil)
  if valid_614291 != nil:
    section.add "X-Amz-Date", valid_614291
  var valid_614292 = header.getOrDefault("X-Amz-Credential")
  valid_614292 = validateParameter(valid_614292, JString, required = false,
                                 default = nil)
  if valid_614292 != nil:
    section.add "X-Amz-Credential", valid_614292
  var valid_614293 = header.getOrDefault("X-Amz-Security-Token")
  valid_614293 = validateParameter(valid_614293, JString, required = false,
                                 default = nil)
  if valid_614293 != nil:
    section.add "X-Amz-Security-Token", valid_614293
  var valid_614294 = header.getOrDefault("X-Amz-Algorithm")
  valid_614294 = validateParameter(valid_614294, JString, required = false,
                                 default = nil)
  if valid_614294 != nil:
    section.add "X-Amz-Algorithm", valid_614294
  var valid_614295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614295 = validateParameter(valid_614295, JString, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "X-Amz-SignedHeaders", valid_614295
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
  var valid_614296 = formData.getOrDefault("AlarmName")
  valid_614296 = validateParameter(valid_614296, JString, required = true,
                                 default = nil)
  if valid_614296 != nil:
    section.add "AlarmName", valid_614296
  var valid_614297 = formData.getOrDefault("StateValue")
  valid_614297 = validateParameter(valid_614297, JString, required = true,
                                 default = newJString("OK"))
  if valid_614297 != nil:
    section.add "StateValue", valid_614297
  var valid_614298 = formData.getOrDefault("StateReason")
  valid_614298 = validateParameter(valid_614298, JString, required = true,
                                 default = nil)
  if valid_614298 != nil:
    section.add "StateReason", valid_614298
  var valid_614299 = formData.getOrDefault("StateReasonData")
  valid_614299 = validateParameter(valid_614299, JString, required = false,
                                 default = nil)
  if valid_614299 != nil:
    section.add "StateReasonData", valid_614299
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614300: Call_PostSetAlarmState_614284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_614300.validator(path, query, header, formData, body)
  let scheme = call_614300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614300.url(scheme.get, call_614300.host, call_614300.base,
                         call_614300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614300, url, valid)

proc call*(call_614301: Call_PostSetAlarmState_614284; AlarmName: string;
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
  var query_614302 = newJObject()
  var formData_614303 = newJObject()
  add(formData_614303, "AlarmName", newJString(AlarmName))
  add(formData_614303, "StateValue", newJString(StateValue))
  add(formData_614303, "StateReason", newJString(StateReason))
  add(formData_614303, "StateReasonData", newJString(StateReasonData))
  add(query_614302, "Action", newJString(Action))
  add(query_614302, "Version", newJString(Version))
  result = call_614301.call(nil, query_614302, nil, formData_614303, nil)

var postSetAlarmState* = Call_PostSetAlarmState_614284(name: "postSetAlarmState",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_PostSetAlarmState_614285,
    base: "/", url: url_PostSetAlarmState_614286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetAlarmState_614265 = ref object of OpenApiRestCall_612658
proc url_GetSetAlarmState_614267(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetAlarmState_614266(path: JsonNode; query: JsonNode;
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
  var valid_614268 = query.getOrDefault("StateReason")
  valid_614268 = validateParameter(valid_614268, JString, required = true,
                                 default = nil)
  if valid_614268 != nil:
    section.add "StateReason", valid_614268
  var valid_614269 = query.getOrDefault("StateValue")
  valid_614269 = validateParameter(valid_614269, JString, required = true,
                                 default = newJString("OK"))
  if valid_614269 != nil:
    section.add "StateValue", valid_614269
  var valid_614270 = query.getOrDefault("Action")
  valid_614270 = validateParameter(valid_614270, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_614270 != nil:
    section.add "Action", valid_614270
  var valid_614271 = query.getOrDefault("AlarmName")
  valid_614271 = validateParameter(valid_614271, JString, required = true,
                                 default = nil)
  if valid_614271 != nil:
    section.add "AlarmName", valid_614271
  var valid_614272 = query.getOrDefault("StateReasonData")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "StateReasonData", valid_614272
  var valid_614273 = query.getOrDefault("Version")
  valid_614273 = validateParameter(valid_614273, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614273 != nil:
    section.add "Version", valid_614273
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
  var valid_614274 = header.getOrDefault("X-Amz-Signature")
  valid_614274 = validateParameter(valid_614274, JString, required = false,
                                 default = nil)
  if valid_614274 != nil:
    section.add "X-Amz-Signature", valid_614274
  var valid_614275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "X-Amz-Content-Sha256", valid_614275
  var valid_614276 = header.getOrDefault("X-Amz-Date")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "X-Amz-Date", valid_614276
  var valid_614277 = header.getOrDefault("X-Amz-Credential")
  valid_614277 = validateParameter(valid_614277, JString, required = false,
                                 default = nil)
  if valid_614277 != nil:
    section.add "X-Amz-Credential", valid_614277
  var valid_614278 = header.getOrDefault("X-Amz-Security-Token")
  valid_614278 = validateParameter(valid_614278, JString, required = false,
                                 default = nil)
  if valid_614278 != nil:
    section.add "X-Amz-Security-Token", valid_614278
  var valid_614279 = header.getOrDefault("X-Amz-Algorithm")
  valid_614279 = validateParameter(valid_614279, JString, required = false,
                                 default = nil)
  if valid_614279 != nil:
    section.add "X-Amz-Algorithm", valid_614279
  var valid_614280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "X-Amz-SignedHeaders", valid_614280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614281: Call_GetSetAlarmState_614265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_614281.validator(path, query, header, formData, body)
  let scheme = call_614281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614281.url(scheme.get, call_614281.host, call_614281.base,
                         call_614281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614281, url, valid)

proc call*(call_614282: Call_GetSetAlarmState_614265; StateReason: string;
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
  var query_614283 = newJObject()
  add(query_614283, "StateReason", newJString(StateReason))
  add(query_614283, "StateValue", newJString(StateValue))
  add(query_614283, "Action", newJString(Action))
  add(query_614283, "AlarmName", newJString(AlarmName))
  add(query_614283, "StateReasonData", newJString(StateReasonData))
  add(query_614283, "Version", newJString(Version))
  result = call_614282.call(nil, query_614283, nil, nil, nil)

var getSetAlarmState* = Call_GetSetAlarmState_614265(name: "getSetAlarmState",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_GetSetAlarmState_614266,
    base: "/", url: url_GetSetAlarmState_614267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_614321 = ref object of OpenApiRestCall_612658
proc url_PostTagResource_614323(protocol: Scheme; host: string; base: string;
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

proc validate_PostTagResource_614322(path: JsonNode; query: JsonNode;
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
  var valid_614324 = query.getOrDefault("Action")
  valid_614324 = validateParameter(valid_614324, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_614324 != nil:
    section.add "Action", valid_614324
  var valid_614325 = query.getOrDefault("Version")
  valid_614325 = validateParameter(valid_614325, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614325 != nil:
    section.add "Version", valid_614325
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
  var valid_614326 = header.getOrDefault("X-Amz-Signature")
  valid_614326 = validateParameter(valid_614326, JString, required = false,
                                 default = nil)
  if valid_614326 != nil:
    section.add "X-Amz-Signature", valid_614326
  var valid_614327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614327 = validateParameter(valid_614327, JString, required = false,
                                 default = nil)
  if valid_614327 != nil:
    section.add "X-Amz-Content-Sha256", valid_614327
  var valid_614328 = header.getOrDefault("X-Amz-Date")
  valid_614328 = validateParameter(valid_614328, JString, required = false,
                                 default = nil)
  if valid_614328 != nil:
    section.add "X-Amz-Date", valid_614328
  var valid_614329 = header.getOrDefault("X-Amz-Credential")
  valid_614329 = validateParameter(valid_614329, JString, required = false,
                                 default = nil)
  if valid_614329 != nil:
    section.add "X-Amz-Credential", valid_614329
  var valid_614330 = header.getOrDefault("X-Amz-Security-Token")
  valid_614330 = validateParameter(valid_614330, JString, required = false,
                                 default = nil)
  if valid_614330 != nil:
    section.add "X-Amz-Security-Token", valid_614330
  var valid_614331 = header.getOrDefault("X-Amz-Algorithm")
  valid_614331 = validateParameter(valid_614331, JString, required = false,
                                 default = nil)
  if valid_614331 != nil:
    section.add "X-Amz-Algorithm", valid_614331
  var valid_614332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "X-Amz-SignedHeaders", valid_614332
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
  var valid_614333 = formData.getOrDefault("Tags")
  valid_614333 = validateParameter(valid_614333, JArray, required = true, default = nil)
  if valid_614333 != nil:
    section.add "Tags", valid_614333
  var valid_614334 = formData.getOrDefault("ResourceARN")
  valid_614334 = validateParameter(valid_614334, JString, required = true,
                                 default = nil)
  if valid_614334 != nil:
    section.add "ResourceARN", valid_614334
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614335: Call_PostTagResource_614321; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_614335.validator(path, query, header, formData, body)
  let scheme = call_614335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614335.url(scheme.get, call_614335.host, call_614335.base,
                         call_614335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614335, url, valid)

proc call*(call_614336: Call_PostTagResource_614321; Tags: JsonNode;
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
  var query_614337 = newJObject()
  var formData_614338 = newJObject()
  add(query_614337, "Action", newJString(Action))
  if Tags != nil:
    formData_614338.add "Tags", Tags
  add(query_614337, "Version", newJString(Version))
  add(formData_614338, "ResourceARN", newJString(ResourceARN))
  result = call_614336.call(nil, query_614337, nil, formData_614338, nil)

var postTagResource* = Call_PostTagResource_614321(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_614322,
    base: "/", url: url_PostTagResource_614323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_614304 = ref object of OpenApiRestCall_612658
proc url_GetTagResource_614306(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagResource_614305(path: JsonNode; query: JsonNode;
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
  var valid_614307 = query.getOrDefault("Tags")
  valid_614307 = validateParameter(valid_614307, JArray, required = true, default = nil)
  if valid_614307 != nil:
    section.add "Tags", valid_614307
  var valid_614308 = query.getOrDefault("Action")
  valid_614308 = validateParameter(valid_614308, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_614308 != nil:
    section.add "Action", valid_614308
  var valid_614309 = query.getOrDefault("ResourceARN")
  valid_614309 = validateParameter(valid_614309, JString, required = true,
                                 default = nil)
  if valid_614309 != nil:
    section.add "ResourceARN", valid_614309
  var valid_614310 = query.getOrDefault("Version")
  valid_614310 = validateParameter(valid_614310, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614310 != nil:
    section.add "Version", valid_614310
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
  var valid_614311 = header.getOrDefault("X-Amz-Signature")
  valid_614311 = validateParameter(valid_614311, JString, required = false,
                                 default = nil)
  if valid_614311 != nil:
    section.add "X-Amz-Signature", valid_614311
  var valid_614312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614312 = validateParameter(valid_614312, JString, required = false,
                                 default = nil)
  if valid_614312 != nil:
    section.add "X-Amz-Content-Sha256", valid_614312
  var valid_614313 = header.getOrDefault("X-Amz-Date")
  valid_614313 = validateParameter(valid_614313, JString, required = false,
                                 default = nil)
  if valid_614313 != nil:
    section.add "X-Amz-Date", valid_614313
  var valid_614314 = header.getOrDefault("X-Amz-Credential")
  valid_614314 = validateParameter(valid_614314, JString, required = false,
                                 default = nil)
  if valid_614314 != nil:
    section.add "X-Amz-Credential", valid_614314
  var valid_614315 = header.getOrDefault("X-Amz-Security-Token")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "X-Amz-Security-Token", valid_614315
  var valid_614316 = header.getOrDefault("X-Amz-Algorithm")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-Algorithm", valid_614316
  var valid_614317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "X-Amz-SignedHeaders", valid_614317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614318: Call_GetTagResource_614304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_614318.validator(path, query, header, formData, body)
  let scheme = call_614318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614318.url(scheme.get, call_614318.host, call_614318.base,
                         call_614318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614318, url, valid)

proc call*(call_614319: Call_GetTagResource_614304; Tags: JsonNode;
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
  var query_614320 = newJObject()
  if Tags != nil:
    query_614320.add "Tags", Tags
  add(query_614320, "Action", newJString(Action))
  add(query_614320, "ResourceARN", newJString(ResourceARN))
  add(query_614320, "Version", newJString(Version))
  result = call_614319.call(nil, query_614320, nil, nil, nil)

var getTagResource* = Call_GetTagResource_614304(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_614305,
    base: "/", url: url_GetTagResource_614306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_614356 = ref object of OpenApiRestCall_612658
proc url_PostUntagResource_614358(protocol: Scheme; host: string; base: string;
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

proc validate_PostUntagResource_614357(path: JsonNode; query: JsonNode;
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
  var valid_614359 = query.getOrDefault("Action")
  valid_614359 = validateParameter(valid_614359, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_614359 != nil:
    section.add "Action", valid_614359
  var valid_614360 = query.getOrDefault("Version")
  valid_614360 = validateParameter(valid_614360, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614360 != nil:
    section.add "Version", valid_614360
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
  var valid_614361 = header.getOrDefault("X-Amz-Signature")
  valid_614361 = validateParameter(valid_614361, JString, required = false,
                                 default = nil)
  if valid_614361 != nil:
    section.add "X-Amz-Signature", valid_614361
  var valid_614362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614362 = validateParameter(valid_614362, JString, required = false,
                                 default = nil)
  if valid_614362 != nil:
    section.add "X-Amz-Content-Sha256", valid_614362
  var valid_614363 = header.getOrDefault("X-Amz-Date")
  valid_614363 = validateParameter(valid_614363, JString, required = false,
                                 default = nil)
  if valid_614363 != nil:
    section.add "X-Amz-Date", valid_614363
  var valid_614364 = header.getOrDefault("X-Amz-Credential")
  valid_614364 = validateParameter(valid_614364, JString, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "X-Amz-Credential", valid_614364
  var valid_614365 = header.getOrDefault("X-Amz-Security-Token")
  valid_614365 = validateParameter(valid_614365, JString, required = false,
                                 default = nil)
  if valid_614365 != nil:
    section.add "X-Amz-Security-Token", valid_614365
  var valid_614366 = header.getOrDefault("X-Amz-Algorithm")
  valid_614366 = validateParameter(valid_614366, JString, required = false,
                                 default = nil)
  if valid_614366 != nil:
    section.add "X-Amz-Algorithm", valid_614366
  var valid_614367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "X-Amz-SignedHeaders", valid_614367
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
  var valid_614368 = formData.getOrDefault("TagKeys")
  valid_614368 = validateParameter(valid_614368, JArray, required = true, default = nil)
  if valid_614368 != nil:
    section.add "TagKeys", valid_614368
  var valid_614369 = formData.getOrDefault("ResourceARN")
  valid_614369 = validateParameter(valid_614369, JString, required = true,
                                 default = nil)
  if valid_614369 != nil:
    section.add "ResourceARN", valid_614369
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614370: Call_PostUntagResource_614356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_614370.validator(path, query, header, formData, body)
  let scheme = call_614370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614370.url(scheme.get, call_614370.host, call_614370.base,
                         call_614370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614370, url, valid)

proc call*(call_614371: Call_PostUntagResource_614356; TagKeys: JsonNode;
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
  var query_614372 = newJObject()
  var formData_614373 = newJObject()
  if TagKeys != nil:
    formData_614373.add "TagKeys", TagKeys
  add(query_614372, "Action", newJString(Action))
  add(query_614372, "Version", newJString(Version))
  add(formData_614373, "ResourceARN", newJString(ResourceARN))
  result = call_614371.call(nil, query_614372, nil, formData_614373, nil)

var postUntagResource* = Call_PostUntagResource_614356(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_614357,
    base: "/", url: url_PostUntagResource_614358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_614339 = ref object of OpenApiRestCall_612658
proc url_GetUntagResource_614341(protocol: Scheme; host: string; base: string;
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

proc validate_GetUntagResource_614340(path: JsonNode; query: JsonNode;
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
  var valid_614342 = query.getOrDefault("TagKeys")
  valid_614342 = validateParameter(valid_614342, JArray, required = true, default = nil)
  if valid_614342 != nil:
    section.add "TagKeys", valid_614342
  var valid_614343 = query.getOrDefault("Action")
  valid_614343 = validateParameter(valid_614343, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_614343 != nil:
    section.add "Action", valid_614343
  var valid_614344 = query.getOrDefault("ResourceARN")
  valid_614344 = validateParameter(valid_614344, JString, required = true,
                                 default = nil)
  if valid_614344 != nil:
    section.add "ResourceARN", valid_614344
  var valid_614345 = query.getOrDefault("Version")
  valid_614345 = validateParameter(valid_614345, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_614345 != nil:
    section.add "Version", valid_614345
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
  var valid_614346 = header.getOrDefault("X-Amz-Signature")
  valid_614346 = validateParameter(valid_614346, JString, required = false,
                                 default = nil)
  if valid_614346 != nil:
    section.add "X-Amz-Signature", valid_614346
  var valid_614347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614347 = validateParameter(valid_614347, JString, required = false,
                                 default = nil)
  if valid_614347 != nil:
    section.add "X-Amz-Content-Sha256", valid_614347
  var valid_614348 = header.getOrDefault("X-Amz-Date")
  valid_614348 = validateParameter(valid_614348, JString, required = false,
                                 default = nil)
  if valid_614348 != nil:
    section.add "X-Amz-Date", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Credential")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Credential", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-Security-Token")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-Security-Token", valid_614350
  var valid_614351 = header.getOrDefault("X-Amz-Algorithm")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "X-Amz-Algorithm", valid_614351
  var valid_614352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-SignedHeaders", valid_614352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614353: Call_GetUntagResource_614339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_614353.validator(path, query, header, formData, body)
  let scheme = call_614353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614353.url(scheme.get, call_614353.host, call_614353.base,
                         call_614353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614353, url, valid)

proc call*(call_614354: Call_GetUntagResource_614339; TagKeys: JsonNode;
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
  var query_614355 = newJObject()
  if TagKeys != nil:
    query_614355.add "TagKeys", TagKeys
  add(query_614355, "Action", newJString(Action))
  add(query_614355, "ResourceARN", newJString(ResourceARN))
  add(query_614355, "Version", newJString(Version))
  result = call_614354.call(nil, query_614355, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_614339(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_614340,
    base: "/", url: url_GetUntagResource_614341,
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
