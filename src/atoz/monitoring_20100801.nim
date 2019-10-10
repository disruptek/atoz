
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostDeleteAlarms_603074 = ref object of OpenApiRestCall_602466
proc url_PostDeleteAlarms_603076(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAlarms_603075(path: JsonNode; query: JsonNode;
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
  var valid_603077 = query.getOrDefault("Action")
  valid_603077 = validateParameter(valid_603077, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_603077 != nil:
    section.add "Action", valid_603077
  var valid_603078 = query.getOrDefault("Version")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603078 != nil:
    section.add "Version", valid_603078
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
  var valid_603079 = header.getOrDefault("X-Amz-Date")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Date", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Security-Token")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Security-Token", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Content-Sha256", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Algorithm")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Algorithm", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Signature")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Signature", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-SignedHeaders", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Credential")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Credential", valid_603085
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_603086 = formData.getOrDefault("AlarmNames")
  valid_603086 = validateParameter(valid_603086, JArray, required = true, default = nil)
  if valid_603086 != nil:
    section.add "AlarmNames", valid_603086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603087: Call_PostDeleteAlarms_603074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_603087.validator(path, query, header, formData, body)
  let scheme = call_603087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603087.url(scheme.get, call_603087.host, call_603087.base,
                         call_603087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603087, url, valid)

proc call*(call_603088: Call_PostDeleteAlarms_603074; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   Action: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Version: string (required)
  var query_603089 = newJObject()
  var formData_603090 = newJObject()
  add(query_603089, "Action", newJString(Action))
  if AlarmNames != nil:
    formData_603090.add "AlarmNames", AlarmNames
  add(query_603089, "Version", newJString(Version))
  result = call_603088.call(nil, query_603089, nil, formData_603090, nil)

var postDeleteAlarms* = Call_PostDeleteAlarms_603074(name: "postDeleteAlarms",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_PostDeleteAlarms_603075,
    base: "/", url: url_PostDeleteAlarms_603076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAlarms_602803 = ref object of OpenApiRestCall_602466
proc url_GetDeleteAlarms_602805(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAlarms_602804(path: JsonNode; query: JsonNode;
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
  var valid_602917 = query.getOrDefault("AlarmNames")
  valid_602917 = validateParameter(valid_602917, JArray, required = true, default = nil)
  if valid_602917 != nil:
    section.add "AlarmNames", valid_602917
  var valid_602931 = query.getOrDefault("Action")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_602931 != nil:
    section.add "Action", valid_602931
  var valid_602932 = query.getOrDefault("Version")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602932 != nil:
    section.add "Version", valid_602932
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
  var valid_602933 = header.getOrDefault("X-Amz-Date")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Date", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Security-Token")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Security-Token", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Content-Sha256", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Algorithm")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Algorithm", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Signature")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Signature", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-SignedHeaders", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Credential")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Credential", valid_602939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602962: Call_GetDeleteAlarms_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_602962.validator(path, query, header, formData, body)
  let scheme = call_602962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602962.url(scheme.get, call_602962.host, call_602962.base,
                         call_602962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602962, url, valid)

proc call*(call_603033: Call_GetDeleteAlarms_602803; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603034 = newJObject()
  if AlarmNames != nil:
    query_603034.add "AlarmNames", AlarmNames
  add(query_603034, "Action", newJString(Action))
  add(query_603034, "Version", newJString(Version))
  result = call_603033.call(nil, query_603034, nil, nil, nil)

var getDeleteAlarms* = Call_GetDeleteAlarms_602803(name: "getDeleteAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_GetDeleteAlarms_602804,
    base: "/", url: url_GetDeleteAlarms_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnomalyDetector_603110 = ref object of OpenApiRestCall_602466
proc url_PostDeleteAnomalyDetector_603112(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAnomalyDetector_603111(path: JsonNode; query: JsonNode;
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
  var valid_603113 = query.getOrDefault("Action")
  valid_603113 = validateParameter(valid_603113, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_603113 != nil:
    section.add "Action", valid_603113
  var valid_603114 = query.getOrDefault("Version")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603114 != nil:
    section.add "Version", valid_603114
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
  var valid_603115 = header.getOrDefault("X-Amz-Date")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Date", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Security-Token")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Security-Token", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Content-Sha256", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Algorithm")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Algorithm", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Signature")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Signature", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-SignedHeaders", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Credential")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Credential", valid_603121
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
  var valid_603122 = formData.getOrDefault("MetricName")
  valid_603122 = validateParameter(valid_603122, JString, required = true,
                                 default = nil)
  if valid_603122 != nil:
    section.add "MetricName", valid_603122
  var valid_603123 = formData.getOrDefault("Dimensions")
  valid_603123 = validateParameter(valid_603123, JArray, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "Dimensions", valid_603123
  var valid_603124 = formData.getOrDefault("Stat")
  valid_603124 = validateParameter(valid_603124, JString, required = true,
                                 default = nil)
  if valid_603124 != nil:
    section.add "Stat", valid_603124
  var valid_603125 = formData.getOrDefault("Namespace")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "Namespace", valid_603125
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_PostDeleteAnomalyDetector_603110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_PostDeleteAnomalyDetector_603110; MetricName: string;
          Stat: string; Namespace: string; Dimensions: JsonNode = nil;
          Action: string = "DeleteAnomalyDetector"; Version: string = "2010-08-01"): Recallable =
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
  var query_603128 = newJObject()
  var formData_603129 = newJObject()
  add(formData_603129, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_603129.add "Dimensions", Dimensions
  add(query_603128, "Action", newJString(Action))
  add(formData_603129, "Stat", newJString(Stat))
  add(formData_603129, "Namespace", newJString(Namespace))
  add(query_603128, "Version", newJString(Version))
  result = call_603127.call(nil, query_603128, nil, formData_603129, nil)

var postDeleteAnomalyDetector* = Call_PostDeleteAnomalyDetector_603110(
    name: "postDeleteAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_PostDeleteAnomalyDetector_603111, base: "/",
    url: url_PostDeleteAnomalyDetector_603112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnomalyDetector_603091 = ref object of OpenApiRestCall_602466
proc url_GetDeleteAnomalyDetector_603093(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAnomalyDetector_603092(path: JsonNode; query: JsonNode;
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
  var valid_603094 = query.getOrDefault("Namespace")
  valid_603094 = validateParameter(valid_603094, JString, required = true,
                                 default = nil)
  if valid_603094 != nil:
    section.add "Namespace", valid_603094
  var valid_603095 = query.getOrDefault("Stat")
  valid_603095 = validateParameter(valid_603095, JString, required = true,
                                 default = nil)
  if valid_603095 != nil:
    section.add "Stat", valid_603095
  var valid_603096 = query.getOrDefault("Dimensions")
  valid_603096 = validateParameter(valid_603096, JArray, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "Dimensions", valid_603096
  var valid_603097 = query.getOrDefault("Action")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_603097 != nil:
    section.add "Action", valid_603097
  var valid_603098 = query.getOrDefault("Version")
  valid_603098 = validateParameter(valid_603098, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603098 != nil:
    section.add "Version", valid_603098
  var valid_603099 = query.getOrDefault("MetricName")
  valid_603099 = validateParameter(valid_603099, JString, required = true,
                                 default = nil)
  if valid_603099 != nil:
    section.add "MetricName", valid_603099
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
  var valid_603100 = header.getOrDefault("X-Amz-Date")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Date", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Security-Token")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Security-Token", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Content-Sha256", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Algorithm")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Algorithm", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Signature")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Signature", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-SignedHeaders", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Credential")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Credential", valid_603106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603107: Call_GetDeleteAnomalyDetector_603091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_603107.validator(path, query, header, formData, body)
  let scheme = call_603107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603107.url(scheme.get, call_603107.host, call_603107.base,
                         call_603107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603107, url, valid)

proc call*(call_603108: Call_GetDeleteAnomalyDetector_603091; Namespace: string;
          Stat: string; MetricName: string; Dimensions: JsonNode = nil;
          Action: string = "DeleteAnomalyDetector"; Version: string = "2010-08-01"): Recallable =
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
  var query_603109 = newJObject()
  add(query_603109, "Namespace", newJString(Namespace))
  add(query_603109, "Stat", newJString(Stat))
  if Dimensions != nil:
    query_603109.add "Dimensions", Dimensions
  add(query_603109, "Action", newJString(Action))
  add(query_603109, "Version", newJString(Version))
  add(query_603109, "MetricName", newJString(MetricName))
  result = call_603108.call(nil, query_603109, nil, nil, nil)

var getDeleteAnomalyDetector* = Call_GetDeleteAnomalyDetector_603091(
    name: "getDeleteAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_GetDeleteAnomalyDetector_603092, base: "/",
    url: url_GetDeleteAnomalyDetector_603093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDashboards_603146 = ref object of OpenApiRestCall_602466
proc url_PostDeleteDashboards_603148(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDashboards_603147(path: JsonNode; query: JsonNode;
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
  var valid_603149 = query.getOrDefault("Action")
  valid_603149 = validateParameter(valid_603149, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_603149 != nil:
    section.add "Action", valid_603149
  var valid_603150 = query.getOrDefault("Version")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603150 != nil:
    section.add "Version", valid_603150
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
  var valid_603151 = header.getOrDefault("X-Amz-Date")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Date", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Security-Token")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Security-Token", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardNames` field"
  var valid_603158 = formData.getOrDefault("DashboardNames")
  valid_603158 = validateParameter(valid_603158, JArray, required = true, default = nil)
  if valid_603158 != nil:
    section.add "DashboardNames", valid_603158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_PostDeleteDashboards_603146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_PostDeleteDashboards_603146; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  var query_603161 = newJObject()
  var formData_603162 = newJObject()
  add(query_603161, "Action", newJString(Action))
  add(query_603161, "Version", newJString(Version))
  if DashboardNames != nil:
    formData_603162.add "DashboardNames", DashboardNames
  result = call_603160.call(nil, query_603161, nil, formData_603162, nil)

var postDeleteDashboards* = Call_PostDeleteDashboards_603146(
    name: "postDeleteDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_PostDeleteDashboards_603147, base: "/",
    url: url_PostDeleteDashboards_603148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDashboards_603130 = ref object of OpenApiRestCall_602466
proc url_GetDeleteDashboards_603132(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDashboards_603131(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603133 = query.getOrDefault("Action")
  valid_603133 = validateParameter(valid_603133, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_603133 != nil:
    section.add "Action", valid_603133
  var valid_603134 = query.getOrDefault("DashboardNames")
  valid_603134 = validateParameter(valid_603134, JArray, required = true, default = nil)
  if valid_603134 != nil:
    section.add "DashboardNames", valid_603134
  var valid_603135 = query.getOrDefault("Version")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603135 != nil:
    section.add "Version", valid_603135
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
  var valid_603136 = header.getOrDefault("X-Amz-Date")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Date", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Security-Token")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Security-Token", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603143: Call_GetDeleteDashboards_603130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_603143.validator(path, query, header, formData, body)
  let scheme = call_603143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603143.url(scheme.get, call_603143.host, call_603143.base,
                         call_603143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603143, url, valid)

proc call*(call_603144: Call_GetDeleteDashboards_603130; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   Action: string (required)
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Version: string (required)
  var query_603145 = newJObject()
  add(query_603145, "Action", newJString(Action))
  if DashboardNames != nil:
    query_603145.add "DashboardNames", DashboardNames
  add(query_603145, "Version", newJString(Version))
  result = call_603144.call(nil, query_603145, nil, nil, nil)

var getDeleteDashboards* = Call_GetDeleteDashboards_603130(
    name: "getDeleteDashboards", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_GetDeleteDashboards_603131, base: "/",
    url: url_GetDeleteDashboards_603132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmHistory_603184 = ref object of OpenApiRestCall_602466
proc url_PostDescribeAlarmHistory_603186(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAlarmHistory_603185(path: JsonNode; query: JsonNode;
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
  var valid_603187 = query.getOrDefault("Action")
  valid_603187 = validateParameter(valid_603187, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_603187 != nil:
    section.add "Action", valid_603187
  var valid_603188 = query.getOrDefault("Version")
  valid_603188 = validateParameter(valid_603188, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603188 != nil:
    section.add "Version", valid_603188
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
  var valid_603189 = header.getOrDefault("X-Amz-Date")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Date", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Security-Token")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Security-Token", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Content-Sha256", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Algorithm")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Algorithm", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Signature")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Signature", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-SignedHeaders", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Credential")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Credential", valid_603195
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
  var valid_603196 = formData.getOrDefault("NextToken")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "NextToken", valid_603196
  var valid_603197 = formData.getOrDefault("AlarmName")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "AlarmName", valid_603197
  var valid_603198 = formData.getOrDefault("MaxRecords")
  valid_603198 = validateParameter(valid_603198, JInt, required = false, default = nil)
  if valid_603198 != nil:
    section.add "MaxRecords", valid_603198
  var valid_603199 = formData.getOrDefault("HistoryItemType")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_603199 != nil:
    section.add "HistoryItemType", valid_603199
  var valid_603200 = formData.getOrDefault("EndDate")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "EndDate", valid_603200
  var valid_603201 = formData.getOrDefault("StartDate")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "StartDate", valid_603201
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603202: Call_PostDescribeAlarmHistory_603184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_603202.validator(path, query, header, formData, body)
  let scheme = call_603202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603202.url(scheme.get, call_603202.host, call_603202.base,
                         call_603202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603202, url, valid)

proc call*(call_603203: Call_PostDescribeAlarmHistory_603184;
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
  var query_603204 = newJObject()
  var formData_603205 = newJObject()
  add(formData_603205, "NextToken", newJString(NextToken))
  add(query_603204, "Action", newJString(Action))
  add(formData_603205, "AlarmName", newJString(AlarmName))
  add(formData_603205, "MaxRecords", newJInt(MaxRecords))
  add(formData_603205, "HistoryItemType", newJString(HistoryItemType))
  add(formData_603205, "EndDate", newJString(EndDate))
  add(query_603204, "Version", newJString(Version))
  add(formData_603205, "StartDate", newJString(StartDate))
  result = call_603203.call(nil, query_603204, nil, formData_603205, nil)

var postDescribeAlarmHistory* = Call_PostDescribeAlarmHistory_603184(
    name: "postDescribeAlarmHistory", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_PostDescribeAlarmHistory_603185, base: "/",
    url: url_PostDescribeAlarmHistory_603186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmHistory_603163 = ref object of OpenApiRestCall_602466
proc url_GetDescribeAlarmHistory_603165(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAlarmHistory_603164(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603166 = query.getOrDefault("MaxRecords")
  valid_603166 = validateParameter(valid_603166, JInt, required = false, default = nil)
  if valid_603166 != nil:
    section.add "MaxRecords", valid_603166
  var valid_603167 = query.getOrDefault("EndDate")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "EndDate", valid_603167
  var valid_603168 = query.getOrDefault("AlarmName")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "AlarmName", valid_603168
  var valid_603169 = query.getOrDefault("NextToken")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "NextToken", valid_603169
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603170 = query.getOrDefault("Action")
  valid_603170 = validateParameter(valid_603170, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_603170 != nil:
    section.add "Action", valid_603170
  var valid_603171 = query.getOrDefault("StartDate")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "StartDate", valid_603171
  var valid_603172 = query.getOrDefault("Version")
  valid_603172 = validateParameter(valid_603172, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603172 != nil:
    section.add "Version", valid_603172
  var valid_603173 = query.getOrDefault("HistoryItemType")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_603173 != nil:
    section.add "HistoryItemType", valid_603173
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
  var valid_603174 = header.getOrDefault("X-Amz-Date")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Date", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Security-Token")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Security-Token", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Content-Sha256", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Algorithm")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Algorithm", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Signature")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Signature", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-SignedHeaders", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Credential")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Credential", valid_603180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603181: Call_GetDescribeAlarmHistory_603163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_603181.validator(path, query, header, formData, body)
  let scheme = call_603181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603181.url(scheme.get, call_603181.host, call_603181.base,
                         call_603181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603181, url, valid)

proc call*(call_603182: Call_GetDescribeAlarmHistory_603163; MaxRecords: int = 0;
          EndDate: string = ""; AlarmName: string = ""; NextToken: string = "";
          Action: string = "DescribeAlarmHistory"; StartDate: string = "";
          Version: string = "2010-08-01";
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
  var query_603183 = newJObject()
  add(query_603183, "MaxRecords", newJInt(MaxRecords))
  add(query_603183, "EndDate", newJString(EndDate))
  add(query_603183, "AlarmName", newJString(AlarmName))
  add(query_603183, "NextToken", newJString(NextToken))
  add(query_603183, "Action", newJString(Action))
  add(query_603183, "StartDate", newJString(StartDate))
  add(query_603183, "Version", newJString(Version))
  add(query_603183, "HistoryItemType", newJString(HistoryItemType))
  result = call_603182.call(nil, query_603183, nil, nil, nil)

var getDescribeAlarmHistory* = Call_GetDescribeAlarmHistory_603163(
    name: "getDescribeAlarmHistory", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_GetDescribeAlarmHistory_603164, base: "/",
    url: url_GetDescribeAlarmHistory_603165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarms_603227 = ref object of OpenApiRestCall_602466
proc url_PostDescribeAlarms_603229(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAlarms_603228(path: JsonNode; query: JsonNode;
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
  var valid_603230 = query.getOrDefault("Action")
  valid_603230 = validateParameter(valid_603230, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_603230 != nil:
    section.add "Action", valid_603230
  var valid_603231 = query.getOrDefault("Version")
  valid_603231 = validateParameter(valid_603231, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603231 != nil:
    section.add "Version", valid_603231
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
  var valid_603232 = header.getOrDefault("X-Amz-Date")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Date", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Security-Token")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Security-Token", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Content-Sha256", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Algorithm")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Algorithm", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Signature")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Signature", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-SignedHeaders", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Credential")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Credential", valid_603238
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
  var valid_603239 = formData.getOrDefault("ActionPrefix")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "ActionPrefix", valid_603239
  var valid_603240 = formData.getOrDefault("NextToken")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "NextToken", valid_603240
  var valid_603241 = formData.getOrDefault("StateValue")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = newJString("OK"))
  if valid_603241 != nil:
    section.add "StateValue", valid_603241
  var valid_603242 = formData.getOrDefault("AlarmNamePrefix")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "AlarmNamePrefix", valid_603242
  var valid_603243 = formData.getOrDefault("MaxRecords")
  valid_603243 = validateParameter(valid_603243, JInt, required = false, default = nil)
  if valid_603243 != nil:
    section.add "MaxRecords", valid_603243
  var valid_603244 = formData.getOrDefault("AlarmNames")
  valid_603244 = validateParameter(valid_603244, JArray, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "AlarmNames", valid_603244
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603245: Call_PostDescribeAlarms_603227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_603245.validator(path, query, header, formData, body)
  let scheme = call_603245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603245.url(scheme.get, call_603245.host, call_603245.base,
                         call_603245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603245, url, valid)

proc call*(call_603246: Call_PostDescribeAlarms_603227; ActionPrefix: string = "";
          NextToken: string = ""; StateValue: string = "OK";
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
  var query_603247 = newJObject()
  var formData_603248 = newJObject()
  add(formData_603248, "ActionPrefix", newJString(ActionPrefix))
  add(formData_603248, "NextToken", newJString(NextToken))
  add(formData_603248, "StateValue", newJString(StateValue))
  add(query_603247, "Action", newJString(Action))
  add(formData_603248, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(formData_603248, "MaxRecords", newJInt(MaxRecords))
  if AlarmNames != nil:
    formData_603248.add "AlarmNames", AlarmNames
  add(query_603247, "Version", newJString(Version))
  result = call_603246.call(nil, query_603247, nil, formData_603248, nil)

var postDescribeAlarms* = Call_PostDescribeAlarms_603227(
    name: "postDescribeAlarms", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarms",
    validator: validate_PostDescribeAlarms_603228, base: "/",
    url: url_PostDescribeAlarms_603229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarms_603206 = ref object of OpenApiRestCall_602466
proc url_GetDescribeAlarms_603208(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAlarms_603207(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_603209 = query.getOrDefault("AlarmNamePrefix")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "AlarmNamePrefix", valid_603209
  var valid_603210 = query.getOrDefault("MaxRecords")
  valid_603210 = validateParameter(valid_603210, JInt, required = false, default = nil)
  if valid_603210 != nil:
    section.add "MaxRecords", valid_603210
  var valid_603211 = query.getOrDefault("ActionPrefix")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "ActionPrefix", valid_603211
  var valid_603212 = query.getOrDefault("AlarmNames")
  valid_603212 = validateParameter(valid_603212, JArray, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "AlarmNames", valid_603212
  var valid_603213 = query.getOrDefault("NextToken")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "NextToken", valid_603213
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603214 = query.getOrDefault("Action")
  valid_603214 = validateParameter(valid_603214, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_603214 != nil:
    section.add "Action", valid_603214
  var valid_603215 = query.getOrDefault("StateValue")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = newJString("OK"))
  if valid_603215 != nil:
    section.add "StateValue", valid_603215
  var valid_603216 = query.getOrDefault("Version")
  valid_603216 = validateParameter(valid_603216, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603216 != nil:
    section.add "Version", valid_603216
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
  var valid_603217 = header.getOrDefault("X-Amz-Date")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Date", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Security-Token")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Security-Token", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Content-Sha256", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Algorithm")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Algorithm", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Signature")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Signature", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-SignedHeaders", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Credential")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Credential", valid_603223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603224: Call_GetDescribeAlarms_603206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_603224.validator(path, query, header, formData, body)
  let scheme = call_603224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603224.url(scheme.get, call_603224.host, call_603224.base,
                         call_603224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603224, url, valid)

proc call*(call_603225: Call_GetDescribeAlarms_603206;
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
  var query_603226 = newJObject()
  add(query_603226, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(query_603226, "MaxRecords", newJInt(MaxRecords))
  add(query_603226, "ActionPrefix", newJString(ActionPrefix))
  if AlarmNames != nil:
    query_603226.add "AlarmNames", AlarmNames
  add(query_603226, "NextToken", newJString(NextToken))
  add(query_603226, "Action", newJString(Action))
  add(query_603226, "StateValue", newJString(StateValue))
  add(query_603226, "Version", newJString(Version))
  result = call_603225.call(nil, query_603226, nil, nil, nil)

var getDescribeAlarms* = Call_GetDescribeAlarms_603206(name: "getDescribeAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DescribeAlarms", validator: validate_GetDescribeAlarms_603207,
    base: "/", url: url_GetDescribeAlarms_603208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmsForMetric_603271 = ref object of OpenApiRestCall_602466
proc url_PostDescribeAlarmsForMetric_603273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAlarmsForMetric_603272(path: JsonNode; query: JsonNode;
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
  var valid_603274 = query.getOrDefault("Action")
  valid_603274 = validateParameter(valid_603274, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_603274 != nil:
    section.add "Action", valid_603274
  var valid_603275 = query.getOrDefault("Version")
  valid_603275 = validateParameter(valid_603275, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603275 != nil:
    section.add "Version", valid_603275
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
  var valid_603276 = header.getOrDefault("X-Amz-Date")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Date", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Security-Token")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Security-Token", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Content-Sha256", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Algorithm")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Algorithm", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Signature")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Signature", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-SignedHeaders", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Credential")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Credential", valid_603282
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
  var valid_603283 = formData.getOrDefault("ExtendedStatistic")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "ExtendedStatistic", valid_603283
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_603284 = formData.getOrDefault("MetricName")
  valid_603284 = validateParameter(valid_603284, JString, required = true,
                                 default = nil)
  if valid_603284 != nil:
    section.add "MetricName", valid_603284
  var valid_603285 = formData.getOrDefault("Dimensions")
  valid_603285 = validateParameter(valid_603285, JArray, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "Dimensions", valid_603285
  var valid_603286 = formData.getOrDefault("Statistic")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_603286 != nil:
    section.add "Statistic", valid_603286
  var valid_603287 = formData.getOrDefault("Namespace")
  valid_603287 = validateParameter(valid_603287, JString, required = true,
                                 default = nil)
  if valid_603287 != nil:
    section.add "Namespace", valid_603287
  var valid_603288 = formData.getOrDefault("Unit")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_603288 != nil:
    section.add "Unit", valid_603288
  var valid_603289 = formData.getOrDefault("Period")
  valid_603289 = validateParameter(valid_603289, JInt, required = false, default = nil)
  if valid_603289 != nil:
    section.add "Period", valid_603289
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603290: Call_PostDescribeAlarmsForMetric_603271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_603290.validator(path, query, header, formData, body)
  let scheme = call_603290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603290.url(scheme.get, call_603290.host, call_603290.base,
                         call_603290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603290, url, valid)

proc call*(call_603291: Call_PostDescribeAlarmsForMetric_603271;
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
  var query_603292 = newJObject()
  var formData_603293 = newJObject()
  add(formData_603293, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(formData_603293, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_603293.add "Dimensions", Dimensions
  add(query_603292, "Action", newJString(Action))
  add(formData_603293, "Statistic", newJString(Statistic))
  add(formData_603293, "Namespace", newJString(Namespace))
  add(formData_603293, "Unit", newJString(Unit))
  add(query_603292, "Version", newJString(Version))
  add(formData_603293, "Period", newJInt(Period))
  result = call_603291.call(nil, query_603292, nil, formData_603293, nil)

var postDescribeAlarmsForMetric* = Call_PostDescribeAlarmsForMetric_603271(
    name: "postDescribeAlarmsForMetric", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_PostDescribeAlarmsForMetric_603272, base: "/",
    url: url_PostDescribeAlarmsForMetric_603273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmsForMetric_603249 = ref object of OpenApiRestCall_602466
proc url_GetDescribeAlarmsForMetric_603251(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAlarmsForMetric_603250(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603252 = query.getOrDefault("Namespace")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = nil)
  if valid_603252 != nil:
    section.add "Namespace", valid_603252
  var valid_603253 = query.getOrDefault("Unit")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_603253 != nil:
    section.add "Unit", valid_603253
  var valid_603254 = query.getOrDefault("ExtendedStatistic")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "ExtendedStatistic", valid_603254
  var valid_603255 = query.getOrDefault("Dimensions")
  valid_603255 = validateParameter(valid_603255, JArray, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "Dimensions", valid_603255
  var valid_603256 = query.getOrDefault("Action")
  valid_603256 = validateParameter(valid_603256, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_603256 != nil:
    section.add "Action", valid_603256
  var valid_603257 = query.getOrDefault("Period")
  valid_603257 = validateParameter(valid_603257, JInt, required = false, default = nil)
  if valid_603257 != nil:
    section.add "Period", valid_603257
  var valid_603258 = query.getOrDefault("MetricName")
  valid_603258 = validateParameter(valid_603258, JString, required = true,
                                 default = nil)
  if valid_603258 != nil:
    section.add "MetricName", valid_603258
  var valid_603259 = query.getOrDefault("Statistic")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_603259 != nil:
    section.add "Statistic", valid_603259
  var valid_603260 = query.getOrDefault("Version")
  valid_603260 = validateParameter(valid_603260, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603260 != nil:
    section.add "Version", valid_603260
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
  var valid_603261 = header.getOrDefault("X-Amz-Date")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Date", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Security-Token")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Security-Token", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Content-Sha256", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Algorithm")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Algorithm", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Signature")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Signature", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-SignedHeaders", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Credential")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Credential", valid_603267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603268: Call_GetDescribeAlarmsForMetric_603249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_603268.validator(path, query, header, formData, body)
  let scheme = call_603268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603268.url(scheme.get, call_603268.host, call_603268.base,
                         call_603268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603268, url, valid)

proc call*(call_603269: Call_GetDescribeAlarmsForMetric_603249; Namespace: string;
          MetricName: string; Unit: string = "Seconds";
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
  var query_603270 = newJObject()
  add(query_603270, "Namespace", newJString(Namespace))
  add(query_603270, "Unit", newJString(Unit))
  add(query_603270, "ExtendedStatistic", newJString(ExtendedStatistic))
  if Dimensions != nil:
    query_603270.add "Dimensions", Dimensions
  add(query_603270, "Action", newJString(Action))
  add(query_603270, "Period", newJInt(Period))
  add(query_603270, "MetricName", newJString(MetricName))
  add(query_603270, "Statistic", newJString(Statistic))
  add(query_603270, "Version", newJString(Version))
  result = call_603269.call(nil, query_603270, nil, nil, nil)

var getDescribeAlarmsForMetric* = Call_GetDescribeAlarmsForMetric_603249(
    name: "getDescribeAlarmsForMetric", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_GetDescribeAlarmsForMetric_603250, base: "/",
    url: url_GetDescribeAlarmsForMetric_603251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnomalyDetectors_603314 = ref object of OpenApiRestCall_602466
proc url_PostDescribeAnomalyDetectors_603316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAnomalyDetectors_603315(path: JsonNode; query: JsonNode;
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
  var valid_603317 = query.getOrDefault("Action")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_603317 != nil:
    section.add "Action", valid_603317
  var valid_603318 = query.getOrDefault("Version")
  valid_603318 = validateParameter(valid_603318, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603318 != nil:
    section.add "Version", valid_603318
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
  var valid_603319 = header.getOrDefault("X-Amz-Date")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Date", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Security-Token")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Security-Token", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Content-Sha256", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Algorithm")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Algorithm", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Signature")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Signature", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-SignedHeaders", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Credential")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Credential", valid_603325
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
  var valid_603326 = formData.getOrDefault("NextToken")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "NextToken", valid_603326
  var valid_603327 = formData.getOrDefault("MaxResults")
  valid_603327 = validateParameter(valid_603327, JInt, required = false, default = nil)
  if valid_603327 != nil:
    section.add "MaxResults", valid_603327
  var valid_603328 = formData.getOrDefault("MetricName")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "MetricName", valid_603328
  var valid_603329 = formData.getOrDefault("Dimensions")
  valid_603329 = validateParameter(valid_603329, JArray, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "Dimensions", valid_603329
  var valid_603330 = formData.getOrDefault("Namespace")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "Namespace", valid_603330
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603331: Call_PostDescribeAnomalyDetectors_603314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_603331.validator(path, query, header, formData, body)
  let scheme = call_603331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603331.url(scheme.get, call_603331.host, call_603331.base,
                         call_603331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603331, url, valid)

proc call*(call_603332: Call_PostDescribeAnomalyDetectors_603314;
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
  var query_603333 = newJObject()
  var formData_603334 = newJObject()
  add(formData_603334, "NextToken", newJString(NextToken))
  add(formData_603334, "MaxResults", newJInt(MaxResults))
  add(formData_603334, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_603334.add "Dimensions", Dimensions
  add(query_603333, "Action", newJString(Action))
  add(formData_603334, "Namespace", newJString(Namespace))
  add(query_603333, "Version", newJString(Version))
  result = call_603332.call(nil, query_603333, nil, formData_603334, nil)

var postDescribeAnomalyDetectors* = Call_PostDescribeAnomalyDetectors_603314(
    name: "postDescribeAnomalyDetectors", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_PostDescribeAnomalyDetectors_603315, base: "/",
    url: url_PostDescribeAnomalyDetectors_603316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnomalyDetectors_603294 = ref object of OpenApiRestCall_602466
proc url_GetDescribeAnomalyDetectors_603296(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAnomalyDetectors_603295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603297 = query.getOrDefault("Namespace")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "Namespace", valid_603297
  var valid_603298 = query.getOrDefault("Dimensions")
  valid_603298 = validateParameter(valid_603298, JArray, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "Dimensions", valid_603298
  var valid_603299 = query.getOrDefault("NextToken")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "NextToken", valid_603299
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603300 = query.getOrDefault("Action")
  valid_603300 = validateParameter(valid_603300, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_603300 != nil:
    section.add "Action", valid_603300
  var valid_603301 = query.getOrDefault("Version")
  valid_603301 = validateParameter(valid_603301, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603301 != nil:
    section.add "Version", valid_603301
  var valid_603302 = query.getOrDefault("MetricName")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "MetricName", valid_603302
  var valid_603303 = query.getOrDefault("MaxResults")
  valid_603303 = validateParameter(valid_603303, JInt, required = false, default = nil)
  if valid_603303 != nil:
    section.add "MaxResults", valid_603303
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
  var valid_603304 = header.getOrDefault("X-Amz-Date")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Date", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Security-Token")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Security-Token", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Content-Sha256", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Algorithm")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Algorithm", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Signature")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Signature", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-SignedHeaders", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Credential")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Credential", valid_603310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603311: Call_GetDescribeAnomalyDetectors_603294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_603311.validator(path, query, header, formData, body)
  let scheme = call_603311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603311.url(scheme.get, call_603311.host, call_603311.base,
                         call_603311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603311, url, valid)

proc call*(call_603312: Call_GetDescribeAnomalyDetectors_603294;
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
  var query_603313 = newJObject()
  add(query_603313, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_603313.add "Dimensions", Dimensions
  add(query_603313, "NextToken", newJString(NextToken))
  add(query_603313, "Action", newJString(Action))
  add(query_603313, "Version", newJString(Version))
  add(query_603313, "MetricName", newJString(MetricName))
  add(query_603313, "MaxResults", newJInt(MaxResults))
  result = call_603312.call(nil, query_603313, nil, nil, nil)

var getDescribeAnomalyDetectors* = Call_GetDescribeAnomalyDetectors_603294(
    name: "getDescribeAnomalyDetectors", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_GetDescribeAnomalyDetectors_603295, base: "/",
    url: url_GetDescribeAnomalyDetectors_603296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAlarmActions_603351 = ref object of OpenApiRestCall_602466
proc url_PostDisableAlarmActions_603353(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDisableAlarmActions_603352(path: JsonNode; query: JsonNode;
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
  var valid_603354 = query.getOrDefault("Action")
  valid_603354 = validateParameter(valid_603354, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_603354 != nil:
    section.add "Action", valid_603354
  var valid_603355 = query.getOrDefault("Version")
  valid_603355 = validateParameter(valid_603355, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603355 != nil:
    section.add "Version", valid_603355
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
  var valid_603356 = header.getOrDefault("X-Amz-Date")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Date", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Security-Token")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Security-Token", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Content-Sha256", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Algorithm")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Algorithm", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Signature")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Signature", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-SignedHeaders", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Credential")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Credential", valid_603362
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_603363 = formData.getOrDefault("AlarmNames")
  valid_603363 = validateParameter(valid_603363, JArray, required = true, default = nil)
  if valid_603363 != nil:
    section.add "AlarmNames", valid_603363
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603364: Call_PostDisableAlarmActions_603351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_603364.validator(path, query, header, formData, body)
  let scheme = call_603364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603364.url(scheme.get, call_603364.host, call_603364.base,
                         call_603364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603364, url, valid)

proc call*(call_603365: Call_PostDisableAlarmActions_603351; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   Action: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Version: string (required)
  var query_603366 = newJObject()
  var formData_603367 = newJObject()
  add(query_603366, "Action", newJString(Action))
  if AlarmNames != nil:
    formData_603367.add "AlarmNames", AlarmNames
  add(query_603366, "Version", newJString(Version))
  result = call_603365.call(nil, query_603366, nil, formData_603367, nil)

var postDisableAlarmActions* = Call_PostDisableAlarmActions_603351(
    name: "postDisableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_PostDisableAlarmActions_603352, base: "/",
    url: url_PostDisableAlarmActions_603353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAlarmActions_603335 = ref object of OpenApiRestCall_602466
proc url_GetDisableAlarmActions_603337(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDisableAlarmActions_603336(path: JsonNode; query: JsonNode;
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
  var valid_603338 = query.getOrDefault("AlarmNames")
  valid_603338 = validateParameter(valid_603338, JArray, required = true, default = nil)
  if valid_603338 != nil:
    section.add "AlarmNames", valid_603338
  var valid_603339 = query.getOrDefault("Action")
  valid_603339 = validateParameter(valid_603339, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_603339 != nil:
    section.add "Action", valid_603339
  var valid_603340 = query.getOrDefault("Version")
  valid_603340 = validateParameter(valid_603340, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603340 != nil:
    section.add "Version", valid_603340
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
  var valid_603341 = header.getOrDefault("X-Amz-Date")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Date", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Security-Token")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Security-Token", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Content-Sha256", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Algorithm")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Algorithm", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Signature")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Signature", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-SignedHeaders", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Credential")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Credential", valid_603347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603348: Call_GetDisableAlarmActions_603335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_603348.validator(path, query, header, formData, body)
  let scheme = call_603348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603348.url(scheme.get, call_603348.host, call_603348.base,
                         call_603348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603348, url, valid)

proc call*(call_603349: Call_GetDisableAlarmActions_603335; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603350 = newJObject()
  if AlarmNames != nil:
    query_603350.add "AlarmNames", AlarmNames
  add(query_603350, "Action", newJString(Action))
  add(query_603350, "Version", newJString(Version))
  result = call_603349.call(nil, query_603350, nil, nil, nil)

var getDisableAlarmActions* = Call_GetDisableAlarmActions_603335(
    name: "getDisableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_GetDisableAlarmActions_603336, base: "/",
    url: url_GetDisableAlarmActions_603337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAlarmActions_603384 = ref object of OpenApiRestCall_602466
proc url_PostEnableAlarmActions_603386(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostEnableAlarmActions_603385(path: JsonNode; query: JsonNode;
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
  var valid_603387 = query.getOrDefault("Action")
  valid_603387 = validateParameter(valid_603387, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_603387 != nil:
    section.add "Action", valid_603387
  var valid_603388 = query.getOrDefault("Version")
  valid_603388 = validateParameter(valid_603388, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603388 != nil:
    section.add "Version", valid_603388
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
  var valid_603389 = header.getOrDefault("X-Amz-Date")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Date", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Security-Token")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Security-Token", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Content-Sha256", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Algorithm")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Algorithm", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Signature")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Signature", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-SignedHeaders", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Credential")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Credential", valid_603395
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_603396 = formData.getOrDefault("AlarmNames")
  valid_603396 = validateParameter(valid_603396, JArray, required = true, default = nil)
  if valid_603396 != nil:
    section.add "AlarmNames", valid_603396
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603397: Call_PostEnableAlarmActions_603384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_603397.validator(path, query, header, formData, body)
  let scheme = call_603397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603397.url(scheme.get, call_603397.host, call_603397.base,
                         call_603397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603397, url, valid)

proc call*(call_603398: Call_PostEnableAlarmActions_603384; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   Action: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Version: string (required)
  var query_603399 = newJObject()
  var formData_603400 = newJObject()
  add(query_603399, "Action", newJString(Action))
  if AlarmNames != nil:
    formData_603400.add "AlarmNames", AlarmNames
  add(query_603399, "Version", newJString(Version))
  result = call_603398.call(nil, query_603399, nil, formData_603400, nil)

var postEnableAlarmActions* = Call_PostEnableAlarmActions_603384(
    name: "postEnableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_PostEnableAlarmActions_603385, base: "/",
    url: url_PostEnableAlarmActions_603386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAlarmActions_603368 = ref object of OpenApiRestCall_602466
proc url_GetEnableAlarmActions_603370(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEnableAlarmActions_603369(path: JsonNode; query: JsonNode;
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
  var valid_603371 = query.getOrDefault("AlarmNames")
  valid_603371 = validateParameter(valid_603371, JArray, required = true, default = nil)
  if valid_603371 != nil:
    section.add "AlarmNames", valid_603371
  var valid_603372 = query.getOrDefault("Action")
  valid_603372 = validateParameter(valid_603372, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_603372 != nil:
    section.add "Action", valid_603372
  var valid_603373 = query.getOrDefault("Version")
  valid_603373 = validateParameter(valid_603373, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603373 != nil:
    section.add "Version", valid_603373
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
  var valid_603374 = header.getOrDefault("X-Amz-Date")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Date", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Security-Token")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Security-Token", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Content-Sha256", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Algorithm")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Algorithm", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Signature")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Signature", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-SignedHeaders", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Credential")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Credential", valid_603380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603381: Call_GetEnableAlarmActions_603368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_603381.validator(path, query, header, formData, body)
  let scheme = call_603381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603381.url(scheme.get, call_603381.host, call_603381.base,
                         call_603381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603381, url, valid)

proc call*(call_603382: Call_GetEnableAlarmActions_603368; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603383 = newJObject()
  if AlarmNames != nil:
    query_603383.add "AlarmNames", AlarmNames
  add(query_603383, "Action", newJString(Action))
  add(query_603383, "Version", newJString(Version))
  result = call_603382.call(nil, query_603383, nil, nil, nil)

var getEnableAlarmActions* = Call_GetEnableAlarmActions_603368(
    name: "getEnableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_GetEnableAlarmActions_603369, base: "/",
    url: url_GetEnableAlarmActions_603370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetDashboard_603417 = ref object of OpenApiRestCall_602466
proc url_PostGetDashboard_603419(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetDashboard_603418(path: JsonNode; query: JsonNode;
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
  var valid_603420 = query.getOrDefault("Action")
  valid_603420 = validateParameter(valid_603420, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_603420 != nil:
    section.add "Action", valid_603420
  var valid_603421 = query.getOrDefault("Version")
  valid_603421 = validateParameter(valid_603421, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603421 != nil:
    section.add "Version", valid_603421
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
  var valid_603422 = header.getOrDefault("X-Amz-Date")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Date", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Security-Token")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Security-Token", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-SignedHeaders", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_603429 = formData.getOrDefault("DashboardName")
  valid_603429 = validateParameter(valid_603429, JString, required = true,
                                 default = nil)
  if valid_603429 != nil:
    section.add "DashboardName", valid_603429
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603430: Call_PostGetDashboard_603417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_603430.validator(path, query, header, formData, body)
  let scheme = call_603430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603430.url(scheme.get, call_603430.host, call_603430.base,
                         call_603430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603430, url, valid)

proc call*(call_603431: Call_PostGetDashboard_603417; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## postGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Version: string (required)
  var query_603432 = newJObject()
  var formData_603433 = newJObject()
  add(query_603432, "Action", newJString(Action))
  add(formData_603433, "DashboardName", newJString(DashboardName))
  add(query_603432, "Version", newJString(Version))
  result = call_603431.call(nil, query_603432, nil, formData_603433, nil)

var postGetDashboard* = Call_PostGetDashboard_603417(name: "postGetDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_PostGetDashboard_603418,
    base: "/", url: url_PostGetDashboard_603419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetDashboard_603401 = ref object of OpenApiRestCall_602466
proc url_GetGetDashboard_603403(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetDashboard_603402(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_603404 = query.getOrDefault("DashboardName")
  valid_603404 = validateParameter(valid_603404, JString, required = true,
                                 default = nil)
  if valid_603404 != nil:
    section.add "DashboardName", valid_603404
  var valid_603405 = query.getOrDefault("Action")
  valid_603405 = validateParameter(valid_603405, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_603405 != nil:
    section.add "Action", valid_603405
  var valid_603406 = query.getOrDefault("Version")
  valid_603406 = validateParameter(valid_603406, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603406 != nil:
    section.add "Version", valid_603406
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
  var valid_603407 = header.getOrDefault("X-Amz-Date")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Date", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Security-Token")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Security-Token", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Content-Sha256", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Algorithm")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Algorithm", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Signature")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Signature", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-SignedHeaders", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Credential")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Credential", valid_603413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_GetGetDashboard_603401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_GetGetDashboard_603401; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## getGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603416 = newJObject()
  add(query_603416, "DashboardName", newJString(DashboardName))
  add(query_603416, "Action", newJString(Action))
  add(query_603416, "Version", newJString(Version))
  result = call_603415.call(nil, query_603416, nil, nil, nil)

var getGetDashboard* = Call_GetGetDashboard_603401(name: "getGetDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_GetGetDashboard_603402,
    base: "/", url: url_GetGetDashboard_603403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricData_603455 = ref object of OpenApiRestCall_602466
proc url_PostGetMetricData_603457(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetMetricData_603456(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
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
  var valid_603458 = query.getOrDefault("Action")
  valid_603458 = validateParameter(valid_603458, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_603458 != nil:
    section.add "Action", valid_603458
  var valid_603459 = query.getOrDefault("Version")
  valid_603459 = validateParameter(valid_603459, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603459 != nil:
    section.add "Version", valid_603459
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
  var valid_603460 = header.getOrDefault("X-Amz-Date")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Date", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Security-Token")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Security-Token", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Content-Sha256", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Algorithm")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Algorithm", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Signature")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Signature", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-SignedHeaders", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Credential")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Credential", valid_603466
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
  var valid_603467 = formData.getOrDefault("NextToken")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "NextToken", valid_603467
  var valid_603468 = formData.getOrDefault("ScanBy")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_603468 != nil:
    section.add "ScanBy", valid_603468
  assert formData != nil,
        "formData argument is necessary due to required `StartTime` field"
  var valid_603469 = formData.getOrDefault("StartTime")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = nil)
  if valid_603469 != nil:
    section.add "StartTime", valid_603469
  var valid_603470 = formData.getOrDefault("EndTime")
  valid_603470 = validateParameter(valid_603470, JString, required = true,
                                 default = nil)
  if valid_603470 != nil:
    section.add "EndTime", valid_603470
  var valid_603471 = formData.getOrDefault("MetricDataQueries")
  valid_603471 = validateParameter(valid_603471, JArray, required = true, default = nil)
  if valid_603471 != nil:
    section.add "MetricDataQueries", valid_603471
  var valid_603472 = formData.getOrDefault("MaxDatapoints")
  valid_603472 = validateParameter(valid_603472, JInt, required = false, default = nil)
  if valid_603472 != nil:
    section.add "MaxDatapoints", valid_603472
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603473: Call_PostGetMetricData_603455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_603473.validator(path, query, header, formData, body)
  let scheme = call_603473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603473.url(scheme.get, call_603473.host, call_603473.base,
                         call_603473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603473, url, valid)

proc call*(call_603474: Call_PostGetMetricData_603455; StartTime: string;
          EndTime: string; MetricDataQueries: JsonNode; NextToken: string = "";
          ScanBy: string = "TimestampDescending"; Action: string = "GetMetricData";
          MaxDatapoints: int = 0; Version: string = "2010-08-01"): Recallable =
  ## postGetMetricData
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
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
  var query_603475 = newJObject()
  var formData_603476 = newJObject()
  add(formData_603476, "NextToken", newJString(NextToken))
  add(formData_603476, "ScanBy", newJString(ScanBy))
  add(formData_603476, "StartTime", newJString(StartTime))
  add(query_603475, "Action", newJString(Action))
  add(formData_603476, "EndTime", newJString(EndTime))
  if MetricDataQueries != nil:
    formData_603476.add "MetricDataQueries", MetricDataQueries
  add(formData_603476, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_603475, "Version", newJString(Version))
  result = call_603474.call(nil, query_603475, nil, formData_603476, nil)

var postGetMetricData* = Call_PostGetMetricData_603455(name: "postGetMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_PostGetMetricData_603456,
    base: "/", url: url_PostGetMetricData_603457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricData_603434 = ref object of OpenApiRestCall_602466
proc url_GetGetMetricData_603436(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetMetricData_603435(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
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
  var valid_603437 = query.getOrDefault("MaxDatapoints")
  valid_603437 = validateParameter(valid_603437, JInt, required = false, default = nil)
  if valid_603437 != nil:
    section.add "MaxDatapoints", valid_603437
  var valid_603438 = query.getOrDefault("ScanBy")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_603438 != nil:
    section.add "ScanBy", valid_603438
  assert query != nil,
        "query argument is necessary due to required `StartTime` field"
  var valid_603439 = query.getOrDefault("StartTime")
  valid_603439 = validateParameter(valid_603439, JString, required = true,
                                 default = nil)
  if valid_603439 != nil:
    section.add "StartTime", valid_603439
  var valid_603440 = query.getOrDefault("NextToken")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "NextToken", valid_603440
  var valid_603441 = query.getOrDefault("Action")
  valid_603441 = validateParameter(valid_603441, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_603441 != nil:
    section.add "Action", valid_603441
  var valid_603442 = query.getOrDefault("MetricDataQueries")
  valid_603442 = validateParameter(valid_603442, JArray, required = true, default = nil)
  if valid_603442 != nil:
    section.add "MetricDataQueries", valid_603442
  var valid_603443 = query.getOrDefault("EndTime")
  valid_603443 = validateParameter(valid_603443, JString, required = true,
                                 default = nil)
  if valid_603443 != nil:
    section.add "EndTime", valid_603443
  var valid_603444 = query.getOrDefault("Version")
  valid_603444 = validateParameter(valid_603444, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603444 != nil:
    section.add "Version", valid_603444
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
  var valid_603445 = header.getOrDefault("X-Amz-Date")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Date", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Security-Token")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Security-Token", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Content-Sha256", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Algorithm")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Algorithm", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Signature")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Signature", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-SignedHeaders", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Credential")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Credential", valid_603451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603452: Call_GetGetMetricData_603434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_603452.validator(path, query, header, formData, body)
  let scheme = call_603452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603452.url(scheme.get, call_603452.host, call_603452.base,
                         call_603452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603452, url, valid)

proc call*(call_603453: Call_GetGetMetricData_603434; StartTime: string;
          MetricDataQueries: JsonNode; EndTime: string; MaxDatapoints: int = 0;
          ScanBy: string = "TimestampDescending"; NextToken: string = "";
          Action: string = "GetMetricData"; Version: string = "2010-08-01"): Recallable =
  ## getGetMetricData
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
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
  var query_603454 = newJObject()
  add(query_603454, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_603454, "ScanBy", newJString(ScanBy))
  add(query_603454, "StartTime", newJString(StartTime))
  add(query_603454, "NextToken", newJString(NextToken))
  add(query_603454, "Action", newJString(Action))
  if MetricDataQueries != nil:
    query_603454.add "MetricDataQueries", MetricDataQueries
  add(query_603454, "EndTime", newJString(EndTime))
  add(query_603454, "Version", newJString(Version))
  result = call_603453.call(nil, query_603454, nil, nil, nil)

var getGetMetricData* = Call_GetGetMetricData_603434(name: "getGetMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_GetGetMetricData_603435,
    base: "/", url: url_GetGetMetricData_603436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricStatistics_603501 = ref object of OpenApiRestCall_602466
proc url_PostGetMetricStatistics_603503(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetMetricStatistics_603502(path: JsonNode; query: JsonNode;
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
  var valid_603504 = query.getOrDefault("Action")
  valid_603504 = validateParameter(valid_603504, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_603504 != nil:
    section.add "Action", valid_603504
  var valid_603505 = query.getOrDefault("Version")
  valid_603505 = validateParameter(valid_603505, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603505 != nil:
    section.add "Version", valid_603505
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
  var valid_603506 = header.getOrDefault("X-Amz-Date")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Date", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Security-Token")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Security-Token", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Content-Sha256", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Algorithm")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Algorithm", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Signature")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Signature", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-SignedHeaders", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Credential")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Credential", valid_603512
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
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   Namespace: JString (required)
  ##            : The namespace of the metric, with or without spaces.
  ##   ExtendedStatistics: JArray
  ##                     : The percentile statistics. Specify values between p0.0 and p100. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both. Percentile statistics are not available for metrics when any of the metric values are negative numbers.
  ##   EndTime: JString (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Unit: JString
  ##       : The unit for a given metric. If you omit <code>Unit</code>, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.
  ##   Period: JInt (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  section = newJObject()
  var valid_603513 = formData.getOrDefault("Statistics")
  valid_603513 = validateParameter(valid_603513, JArray, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "Statistics", valid_603513
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_603514 = formData.getOrDefault("MetricName")
  valid_603514 = validateParameter(valid_603514, JString, required = true,
                                 default = nil)
  if valid_603514 != nil:
    section.add "MetricName", valid_603514
  var valid_603515 = formData.getOrDefault("Dimensions")
  valid_603515 = validateParameter(valid_603515, JArray, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "Dimensions", valid_603515
  var valid_603516 = formData.getOrDefault("StartTime")
  valid_603516 = validateParameter(valid_603516, JString, required = true,
                                 default = nil)
  if valid_603516 != nil:
    section.add "StartTime", valid_603516
  var valid_603517 = formData.getOrDefault("Namespace")
  valid_603517 = validateParameter(valid_603517, JString, required = true,
                                 default = nil)
  if valid_603517 != nil:
    section.add "Namespace", valid_603517
  var valid_603518 = formData.getOrDefault("ExtendedStatistics")
  valid_603518 = validateParameter(valid_603518, JArray, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "ExtendedStatistics", valid_603518
  var valid_603519 = formData.getOrDefault("EndTime")
  valid_603519 = validateParameter(valid_603519, JString, required = true,
                                 default = nil)
  if valid_603519 != nil:
    section.add "EndTime", valid_603519
  var valid_603520 = formData.getOrDefault("Unit")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_603520 != nil:
    section.add "Unit", valid_603520
  var valid_603521 = formData.getOrDefault("Period")
  valid_603521 = validateParameter(valid_603521, JInt, required = true, default = nil)
  if valid_603521 != nil:
    section.add "Period", valid_603521
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603522: Call_PostGetMetricStatistics_603501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_603522.validator(path, query, header, formData, body)
  let scheme = call_603522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603522.url(scheme.get, call_603522.host, call_603522.base,
                         call_603522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603522, url, valid)

proc call*(call_603523: Call_PostGetMetricStatistics_603501; MetricName: string;
          StartTime: string; Namespace: string; EndTime: string; Period: int;
          Statistics: JsonNode = nil; Dimensions: JsonNode = nil;
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
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   Action: string (required)
  ##   Namespace: string (required)
  ##            : The namespace of the metric, with or without spaces.
  ##   ExtendedStatistics: JArray
  ##                     : The percentile statistics. Specify values between p0.0 and p100. When calling <code>GetMetricStatistics</code>, you must specify either <code>Statistics</code> or <code>ExtendedStatistics</code>, but not both. Percentile statistics are not available for metrics when any of the metric values are negative numbers.
  ##   EndTime: string (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Unit: string
  ##       : The unit for a given metric. If you omit <code>Unit</code>, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.
  ##   Version: string (required)
  ##   Period: int (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  var query_603524 = newJObject()
  var formData_603525 = newJObject()
  if Statistics != nil:
    formData_603525.add "Statistics", Statistics
  add(formData_603525, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_603525.add "Dimensions", Dimensions
  add(formData_603525, "StartTime", newJString(StartTime))
  add(query_603524, "Action", newJString(Action))
  add(formData_603525, "Namespace", newJString(Namespace))
  if ExtendedStatistics != nil:
    formData_603525.add "ExtendedStatistics", ExtendedStatistics
  add(formData_603525, "EndTime", newJString(EndTime))
  add(formData_603525, "Unit", newJString(Unit))
  add(query_603524, "Version", newJString(Version))
  add(formData_603525, "Period", newJInt(Period))
  result = call_603523.call(nil, query_603524, nil, formData_603525, nil)

var postGetMetricStatistics* = Call_PostGetMetricStatistics_603501(
    name: "postGetMetricStatistics", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_PostGetMetricStatistics_603502, base: "/",
    url: url_PostGetMetricStatistics_603503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricStatistics_603477 = ref object of OpenApiRestCall_602466
proc url_GetGetMetricStatistics_603479(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetMetricStatistics_603478(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
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
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Period: JInt (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  ##   MetricName: JString (required)
  ##             : The name of the metric, with or without spaces.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_603480 = query.getOrDefault("Namespace")
  valid_603480 = validateParameter(valid_603480, JString, required = true,
                                 default = nil)
  if valid_603480 != nil:
    section.add "Namespace", valid_603480
  var valid_603481 = query.getOrDefault("Unit")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_603481 != nil:
    section.add "Unit", valid_603481
  var valid_603482 = query.getOrDefault("StartTime")
  valid_603482 = validateParameter(valid_603482, JString, required = true,
                                 default = nil)
  if valid_603482 != nil:
    section.add "StartTime", valid_603482
  var valid_603483 = query.getOrDefault("Dimensions")
  valid_603483 = validateParameter(valid_603483, JArray, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "Dimensions", valid_603483
  var valid_603484 = query.getOrDefault("Action")
  valid_603484 = validateParameter(valid_603484, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_603484 != nil:
    section.add "Action", valid_603484
  var valid_603485 = query.getOrDefault("ExtendedStatistics")
  valid_603485 = validateParameter(valid_603485, JArray, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "ExtendedStatistics", valid_603485
  var valid_603486 = query.getOrDefault("Statistics")
  valid_603486 = validateParameter(valid_603486, JArray, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "Statistics", valid_603486
  var valid_603487 = query.getOrDefault("EndTime")
  valid_603487 = validateParameter(valid_603487, JString, required = true,
                                 default = nil)
  if valid_603487 != nil:
    section.add "EndTime", valid_603487
  var valid_603488 = query.getOrDefault("Period")
  valid_603488 = validateParameter(valid_603488, JInt, required = true, default = nil)
  if valid_603488 != nil:
    section.add "Period", valid_603488
  var valid_603489 = query.getOrDefault("MetricName")
  valid_603489 = validateParameter(valid_603489, JString, required = true,
                                 default = nil)
  if valid_603489 != nil:
    section.add "MetricName", valid_603489
  var valid_603490 = query.getOrDefault("Version")
  valid_603490 = validateParameter(valid_603490, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603490 != nil:
    section.add "Version", valid_603490
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
  var valid_603491 = header.getOrDefault("X-Amz-Date")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Date", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Security-Token")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Security-Token", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Content-Sha256", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Algorithm")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Algorithm", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Signature")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Signature", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-SignedHeaders", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Credential")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Credential", valid_603497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603498: Call_GetGetMetricStatistics_603477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_603498.validator(path, query, header, formData, body)
  let scheme = call_603498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603498.url(scheme.get, call_603498.host, call_603498.base,
                         call_603498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603498, url, valid)

proc call*(call_603499: Call_GetGetMetricStatistics_603477; Namespace: string;
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
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
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
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Period: int (required)
  ##         : <p>The granularity, in seconds, of the returned data points. For metrics with regular resolution, a period can be as short as one minute (60 seconds) and must be a multiple of 60. For high-resolution metrics that are collected at intervals of less than one minute, the period can be 1, 5, 10, 30, 60, or any multiple of 60. High-resolution metrics are those metrics stored by a <code>PutMetricData</code> call that includes a <code>StorageResolution</code> of 1 second.</p> <p>If the <code>StartTime</code> parameter specifies a time stamp that is greater than 3 hours ago, you must specify the period as follows or no data points in that time range is returned:</p> <ul> <li> <p>Start time between 3 hours and 15 days ago - Use a multiple of 60 seconds (1 minute).</p> </li> <li> <p>Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes).</p> </li> <li> <p>Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour).</p> </li> </ul>
  ##   MetricName: string (required)
  ##             : The name of the metric, with or without spaces.
  ##   Version: string (required)
  var query_603500 = newJObject()
  add(query_603500, "Namespace", newJString(Namespace))
  add(query_603500, "Unit", newJString(Unit))
  add(query_603500, "StartTime", newJString(StartTime))
  if Dimensions != nil:
    query_603500.add "Dimensions", Dimensions
  add(query_603500, "Action", newJString(Action))
  if ExtendedStatistics != nil:
    query_603500.add "ExtendedStatistics", ExtendedStatistics
  if Statistics != nil:
    query_603500.add "Statistics", Statistics
  add(query_603500, "EndTime", newJString(EndTime))
  add(query_603500, "Period", newJInt(Period))
  add(query_603500, "MetricName", newJString(MetricName))
  add(query_603500, "Version", newJString(Version))
  result = call_603499.call(nil, query_603500, nil, nil, nil)

var getGetMetricStatistics* = Call_GetGetMetricStatistics_603477(
    name: "getGetMetricStatistics", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_GetGetMetricStatistics_603478, base: "/",
    url: url_GetGetMetricStatistics_603479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricWidgetImage_603543 = ref object of OpenApiRestCall_602466
proc url_PostGetMetricWidgetImage_603545(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetMetricWidgetImage_603544(path: JsonNode; query: JsonNode;
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
  var valid_603546 = query.getOrDefault("Action")
  valid_603546 = validateParameter(valid_603546, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_603546 != nil:
    section.add "Action", valid_603546
  var valid_603547 = query.getOrDefault("Version")
  valid_603547 = validateParameter(valid_603547, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603547 != nil:
    section.add "Version", valid_603547
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
  var valid_603548 = header.getOrDefault("X-Amz-Date")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Date", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Security-Token")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Security-Token", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Content-Sha256", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Algorithm")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Algorithm", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Signature")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Signature", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-SignedHeaders", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Credential")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Credential", valid_603554
  result.add "header", section
  ## parameters in `formData` object:
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  section = newJObject()
  var valid_603555 = formData.getOrDefault("OutputFormat")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "OutputFormat", valid_603555
  assert formData != nil,
        "formData argument is necessary due to required `MetricWidget` field"
  var valid_603556 = formData.getOrDefault("MetricWidget")
  valid_603556 = validateParameter(valid_603556, JString, required = true,
                                 default = nil)
  if valid_603556 != nil:
    section.add "MetricWidget", valid_603556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603557: Call_PostGetMetricWidgetImage_603543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_603557.validator(path, query, header, formData, body)
  let scheme = call_603557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603557.url(scheme.get, call_603557.host, call_603557.base,
                         call_603557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603557, url, valid)

proc call*(call_603558: Call_PostGetMetricWidgetImage_603543; MetricWidget: string;
          OutputFormat: string = ""; Action: string = "GetMetricWidgetImage";
          Version: string = "2010-08-01"): Recallable =
  ## postGetMetricWidgetImage
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ##   OutputFormat: string
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   MetricWidget: string (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603559 = newJObject()
  var formData_603560 = newJObject()
  add(formData_603560, "OutputFormat", newJString(OutputFormat))
  add(formData_603560, "MetricWidget", newJString(MetricWidget))
  add(query_603559, "Action", newJString(Action))
  add(query_603559, "Version", newJString(Version))
  result = call_603558.call(nil, query_603559, nil, formData_603560, nil)

var postGetMetricWidgetImage* = Call_PostGetMetricWidgetImage_603543(
    name: "postGetMetricWidgetImage", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_PostGetMetricWidgetImage_603544, base: "/",
    url: url_PostGetMetricWidgetImage_603545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricWidgetImage_603526 = ref object of OpenApiRestCall_602466
proc url_GetGetMetricWidgetImage_603528(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetMetricWidgetImage_603527(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603529 = query.getOrDefault("MetricWidget")
  valid_603529 = validateParameter(valid_603529, JString, required = true,
                                 default = nil)
  if valid_603529 != nil:
    section.add "MetricWidget", valid_603529
  var valid_603530 = query.getOrDefault("OutputFormat")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "OutputFormat", valid_603530
  var valid_603531 = query.getOrDefault("Action")
  valid_603531 = validateParameter(valid_603531, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_603531 != nil:
    section.add "Action", valid_603531
  var valid_603532 = query.getOrDefault("Version")
  valid_603532 = validateParameter(valid_603532, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603532 != nil:
    section.add "Version", valid_603532
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
  var valid_603533 = header.getOrDefault("X-Amz-Date")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Date", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Security-Token")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Security-Token", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Content-Sha256", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Algorithm")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Algorithm", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Signature")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Signature", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-SignedHeaders", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Credential")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Credential", valid_603539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603540: Call_GetGetMetricWidgetImage_603526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_603540.validator(path, query, header, formData, body)
  let scheme = call_603540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603540.url(scheme.get, call_603540.host, call_603540.base,
                         call_603540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603540, url, valid)

proc call*(call_603541: Call_GetGetMetricWidgetImage_603526; MetricWidget: string;
          OutputFormat: string = ""; Action: string = "GetMetricWidgetImage";
          Version: string = "2010-08-01"): Recallable =
  ## getGetMetricWidgetImage
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ##   MetricWidget: string (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   OutputFormat: string
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603542 = newJObject()
  add(query_603542, "MetricWidget", newJString(MetricWidget))
  add(query_603542, "OutputFormat", newJString(OutputFormat))
  add(query_603542, "Action", newJString(Action))
  add(query_603542, "Version", newJString(Version))
  result = call_603541.call(nil, query_603542, nil, nil, nil)

var getGetMetricWidgetImage* = Call_GetGetMetricWidgetImage_603526(
    name: "getGetMetricWidgetImage", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_GetGetMetricWidgetImage_603527, base: "/",
    url: url_GetGetMetricWidgetImage_603528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDashboards_603578 = ref object of OpenApiRestCall_602466
proc url_PostListDashboards_603580(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListDashboards_603579(path: JsonNode; query: JsonNode;
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
  var valid_603581 = query.getOrDefault("Action")
  valid_603581 = validateParameter(valid_603581, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_603581 != nil:
    section.add "Action", valid_603581
  var valid_603582 = query.getOrDefault("Version")
  valid_603582 = validateParameter(valid_603582, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603582 != nil:
    section.add "Version", valid_603582
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
  var valid_603583 = header.getOrDefault("X-Amz-Date")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Date", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Security-Token")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Security-Token", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Content-Sha256", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Algorithm")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Algorithm", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Signature")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Signature", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-SignedHeaders", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Credential")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Credential", valid_603589
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   DashboardNamePrefix: JString
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  section = newJObject()
  var valid_603590 = formData.getOrDefault("NextToken")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "NextToken", valid_603590
  var valid_603591 = formData.getOrDefault("DashboardNamePrefix")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "DashboardNamePrefix", valid_603591
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603592: Call_PostListDashboards_603578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_603592.validator(path, query, header, formData, body)
  let scheme = call_603592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603592.url(scheme.get, call_603592.host, call_603592.base,
                         call_603592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603592, url, valid)

proc call*(call_603593: Call_PostListDashboards_603578; NextToken: string = "";
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
  var query_603594 = newJObject()
  var formData_603595 = newJObject()
  add(formData_603595, "NextToken", newJString(NextToken))
  add(query_603594, "Action", newJString(Action))
  add(formData_603595, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_603594, "Version", newJString(Version))
  result = call_603593.call(nil, query_603594, nil, formData_603595, nil)

var postListDashboards* = Call_PostListDashboards_603578(
    name: "postListDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListDashboards",
    validator: validate_PostListDashboards_603579, base: "/",
    url: url_PostListDashboards_603580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDashboards_603561 = ref object of OpenApiRestCall_602466
proc url_GetListDashboards_603563(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListDashboards_603562(path: JsonNode; query: JsonNode;
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
  var valid_603564 = query.getOrDefault("DashboardNamePrefix")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "DashboardNamePrefix", valid_603564
  var valid_603565 = query.getOrDefault("NextToken")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "NextToken", valid_603565
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603566 = query.getOrDefault("Action")
  valid_603566 = validateParameter(valid_603566, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_603566 != nil:
    section.add "Action", valid_603566
  var valid_603567 = query.getOrDefault("Version")
  valid_603567 = validateParameter(valid_603567, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603567 != nil:
    section.add "Version", valid_603567
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
  var valid_603568 = header.getOrDefault("X-Amz-Date")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Date", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Security-Token")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Security-Token", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Content-Sha256", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Algorithm")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Algorithm", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Signature")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Signature", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-SignedHeaders", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Credential")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Credential", valid_603574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603575: Call_GetListDashboards_603561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_603575.validator(path, query, header, formData, body)
  let scheme = call_603575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603575.url(scheme.get, call_603575.host, call_603575.base,
                         call_603575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603575, url, valid)

proc call*(call_603576: Call_GetListDashboards_603561;
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
  var query_603577 = newJObject()
  add(query_603577, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_603577, "NextToken", newJString(NextToken))
  add(query_603577, "Action", newJString(Action))
  add(query_603577, "Version", newJString(Version))
  result = call_603576.call(nil, query_603577, nil, nil, nil)

var getListDashboards* = Call_GetListDashboards_603561(name: "getListDashboards",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListDashboards", validator: validate_GetListDashboards_603562,
    base: "/", url: url_GetListDashboards_603563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListMetrics_603615 = ref object of OpenApiRestCall_602466
proc url_PostListMetrics_603617(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListMetrics_603616(path: JsonNode; query: JsonNode;
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
  var valid_603618 = query.getOrDefault("Action")
  valid_603618 = validateParameter(valid_603618, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_603618 != nil:
    section.add "Action", valid_603618
  var valid_603619 = query.getOrDefault("Version")
  valid_603619 = validateParameter(valid_603619, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603619 != nil:
    section.add "Version", valid_603619
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
  var valid_603620 = header.getOrDefault("X-Amz-Date")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Date", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Security-Token")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Security-Token", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Content-Sha256", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Algorithm")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Algorithm", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Signature")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Signature", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-SignedHeaders", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Credential")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Credential", valid_603626
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
  var valid_603627 = formData.getOrDefault("NextToken")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "NextToken", valid_603627
  var valid_603628 = formData.getOrDefault("MetricName")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "MetricName", valid_603628
  var valid_603629 = formData.getOrDefault("Dimensions")
  valid_603629 = validateParameter(valid_603629, JArray, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "Dimensions", valid_603629
  var valid_603630 = formData.getOrDefault("Namespace")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "Namespace", valid_603630
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603631: Call_PostListMetrics_603615; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_603631.validator(path, query, header, formData, body)
  let scheme = call_603631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603631.url(scheme.get, call_603631.host, call_603631.base,
                         call_603631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603631, url, valid)

proc call*(call_603632: Call_PostListMetrics_603615; NextToken: string = "";
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
  var query_603633 = newJObject()
  var formData_603634 = newJObject()
  add(formData_603634, "NextToken", newJString(NextToken))
  add(formData_603634, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_603634.add "Dimensions", Dimensions
  add(query_603633, "Action", newJString(Action))
  add(formData_603634, "Namespace", newJString(Namespace))
  add(query_603633, "Version", newJString(Version))
  result = call_603632.call(nil, query_603633, nil, formData_603634, nil)

var postListMetrics* = Call_PostListMetrics_603615(name: "postListMetrics",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_PostListMetrics_603616,
    base: "/", url: url_PostListMetrics_603617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListMetrics_603596 = ref object of OpenApiRestCall_602466
proc url_GetListMetrics_603598(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListMetrics_603597(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_603599 = query.getOrDefault("Namespace")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "Namespace", valid_603599
  var valid_603600 = query.getOrDefault("Dimensions")
  valid_603600 = validateParameter(valid_603600, JArray, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "Dimensions", valid_603600
  var valid_603601 = query.getOrDefault("NextToken")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "NextToken", valid_603601
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603602 = query.getOrDefault("Action")
  valid_603602 = validateParameter(valid_603602, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_603602 != nil:
    section.add "Action", valid_603602
  var valid_603603 = query.getOrDefault("Version")
  valid_603603 = validateParameter(valid_603603, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603603 != nil:
    section.add "Version", valid_603603
  var valid_603604 = query.getOrDefault("MetricName")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "MetricName", valid_603604
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
  var valid_603605 = header.getOrDefault("X-Amz-Date")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Date", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Security-Token")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Security-Token", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Content-Sha256", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Algorithm")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Algorithm", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Signature")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Signature", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-SignedHeaders", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Credential")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Credential", valid_603611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603612: Call_GetListMetrics_603596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_603612.validator(path, query, header, formData, body)
  let scheme = call_603612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603612.url(scheme.get, call_603612.host, call_603612.base,
                         call_603612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603612, url, valid)

proc call*(call_603613: Call_GetListMetrics_603596; Namespace: string = "";
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
  var query_603614 = newJObject()
  add(query_603614, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_603614.add "Dimensions", Dimensions
  add(query_603614, "NextToken", newJString(NextToken))
  add(query_603614, "Action", newJString(Action))
  add(query_603614, "Version", newJString(Version))
  add(query_603614, "MetricName", newJString(MetricName))
  result = call_603613.call(nil, query_603614, nil, nil, nil)

var getListMetrics* = Call_GetListMetrics_603596(name: "getListMetrics",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_GetListMetrics_603597,
    base: "/", url: url_GetListMetrics_603598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_603651 = ref object of OpenApiRestCall_602466
proc url_PostListTagsForResource_603653(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_603652(path: JsonNode; query: JsonNode;
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
  var valid_603654 = query.getOrDefault("Action")
  valid_603654 = validateParameter(valid_603654, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603654 != nil:
    section.add "Action", valid_603654
  var valid_603655 = query.getOrDefault("Version")
  valid_603655 = validateParameter(valid_603655, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603655 != nil:
    section.add "Version", valid_603655
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
  var valid_603656 = header.getOrDefault("X-Amz-Date")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Date", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Security-Token")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Security-Token", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Content-Sha256", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Algorithm")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Algorithm", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Signature")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Signature", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-SignedHeaders", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Credential")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Credential", valid_603662
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceARN` field"
  var valid_603663 = formData.getOrDefault("ResourceARN")
  valid_603663 = validateParameter(valid_603663, JString, required = true,
                                 default = nil)
  if valid_603663 != nil:
    section.add "ResourceARN", valid_603663
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603664: Call_PostListTagsForResource_603651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_603664.validator(path, query, header, formData, body)
  let scheme = call_603664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603664.url(scheme.get, call_603664.host, call_603664.base,
                         call_603664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603664, url, valid)

proc call*(call_603665: Call_PostListTagsForResource_603651; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## postListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_603666 = newJObject()
  var formData_603667 = newJObject()
  add(query_603666, "Action", newJString(Action))
  add(formData_603667, "ResourceARN", newJString(ResourceARN))
  add(query_603666, "Version", newJString(Version))
  result = call_603665.call(nil, query_603666, nil, formData_603667, nil)

var postListTagsForResource* = Call_PostListTagsForResource_603651(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_603652, base: "/",
    url: url_PostListTagsForResource_603653, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_603635 = ref object of OpenApiRestCall_602466
proc url_GetListTagsForResource_603637(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_603636(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603638 = query.getOrDefault("ResourceARN")
  valid_603638 = validateParameter(valid_603638, JString, required = true,
                                 default = nil)
  if valid_603638 != nil:
    section.add "ResourceARN", valid_603638
  var valid_603639 = query.getOrDefault("Action")
  valid_603639 = validateParameter(valid_603639, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603639 != nil:
    section.add "Action", valid_603639
  var valid_603640 = query.getOrDefault("Version")
  valid_603640 = validateParameter(valid_603640, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603640 != nil:
    section.add "Version", valid_603640
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
  var valid_603641 = header.getOrDefault("X-Amz-Date")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Date", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Security-Token")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Security-Token", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Content-Sha256", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Algorithm")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Algorithm", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Signature")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Signature", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-SignedHeaders", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Credential")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Credential", valid_603647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603648: Call_GetListTagsForResource_603635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_603648.validator(path, query, header, formData, body)
  let scheme = call_603648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603648.url(scheme.get, call_603648.host, call_603648.base,
                         call_603648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603648, url, valid)

proc call*(call_603649: Call_GetListTagsForResource_603635; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## getListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603650 = newJObject()
  add(query_603650, "ResourceARN", newJString(ResourceARN))
  add(query_603650, "Action", newJString(Action))
  add(query_603650, "Version", newJString(Version))
  result = call_603649.call(nil, query_603650, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_603635(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_603636, base: "/",
    url: url_GetListTagsForResource_603637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAnomalyDetector_603689 = ref object of OpenApiRestCall_602466
proc url_PostPutAnomalyDetector_603691(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutAnomalyDetector_603690(path: JsonNode; query: JsonNode;
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
  var valid_603692 = query.getOrDefault("Action")
  valid_603692 = validateParameter(valid_603692, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_603692 != nil:
    section.add "Action", valid_603692
  var valid_603693 = query.getOrDefault("Version")
  valid_603693 = validateParameter(valid_603693, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603693 != nil:
    section.add "Version", valid_603693
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
  var valid_603694 = header.getOrDefault("X-Amz-Date")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Date", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Security-Token")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Security-Token", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Content-Sha256", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Algorithm")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Algorithm", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Signature")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Signature", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-SignedHeaders", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Credential")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Credential", valid_603700
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
  var valid_603701 = formData.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_603701 = validateParameter(valid_603701, JArray, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_603701
  var valid_603702 = formData.getOrDefault("Configuration.MetricTimezone")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "Configuration.MetricTimezone", valid_603702
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_603703 = formData.getOrDefault("MetricName")
  valid_603703 = validateParameter(valid_603703, JString, required = true,
                                 default = nil)
  if valid_603703 != nil:
    section.add "MetricName", valid_603703
  var valid_603704 = formData.getOrDefault("Dimensions")
  valid_603704 = validateParameter(valid_603704, JArray, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "Dimensions", valid_603704
  var valid_603705 = formData.getOrDefault("Stat")
  valid_603705 = validateParameter(valid_603705, JString, required = true,
                                 default = nil)
  if valid_603705 != nil:
    section.add "Stat", valid_603705
  var valid_603706 = formData.getOrDefault("Namespace")
  valid_603706 = validateParameter(valid_603706, JString, required = true,
                                 default = nil)
  if valid_603706 != nil:
    section.add "Namespace", valid_603706
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603707: Call_PostPutAnomalyDetector_603689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_603707.validator(path, query, header, formData, body)
  let scheme = call_603707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603707.url(scheme.get, call_603707.host, call_603707.base,
                         call_603707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603707, url, valid)

proc call*(call_603708: Call_PostPutAnomalyDetector_603689; MetricName: string;
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
  var query_603709 = newJObject()
  var formData_603710 = newJObject()
  if ConfigurationExcludedTimeRanges != nil:
    formData_603710.add "Configuration.ExcludedTimeRanges",
                       ConfigurationExcludedTimeRanges
  add(formData_603710, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  add(formData_603710, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_603710.add "Dimensions", Dimensions
  add(query_603709, "Action", newJString(Action))
  add(formData_603710, "Stat", newJString(Stat))
  add(formData_603710, "Namespace", newJString(Namespace))
  add(query_603709, "Version", newJString(Version))
  result = call_603708.call(nil, query_603709, nil, formData_603710, nil)

var postPutAnomalyDetector* = Call_PostPutAnomalyDetector_603689(
    name: "postPutAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_PostPutAnomalyDetector_603690, base: "/",
    url: url_PostPutAnomalyDetector_603691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAnomalyDetector_603668 = ref object of OpenApiRestCall_602466
proc url_GetPutAnomalyDetector_603670(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutAnomalyDetector_603669(path: JsonNode; query: JsonNode;
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
  var valid_603671 = query.getOrDefault("Namespace")
  valid_603671 = validateParameter(valid_603671, JString, required = true,
                                 default = nil)
  if valid_603671 != nil:
    section.add "Namespace", valid_603671
  var valid_603672 = query.getOrDefault("Stat")
  valid_603672 = validateParameter(valid_603672, JString, required = true,
                                 default = nil)
  if valid_603672 != nil:
    section.add "Stat", valid_603672
  var valid_603673 = query.getOrDefault("Configuration.MetricTimezone")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "Configuration.MetricTimezone", valid_603673
  var valid_603674 = query.getOrDefault("Dimensions")
  valid_603674 = validateParameter(valid_603674, JArray, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "Dimensions", valid_603674
  var valid_603675 = query.getOrDefault("Action")
  valid_603675 = validateParameter(valid_603675, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_603675 != nil:
    section.add "Action", valid_603675
  var valid_603676 = query.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_603676 = validateParameter(valid_603676, JArray, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_603676
  var valid_603677 = query.getOrDefault("Version")
  valid_603677 = validateParameter(valid_603677, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603677 != nil:
    section.add "Version", valid_603677
  var valid_603678 = query.getOrDefault("MetricName")
  valid_603678 = validateParameter(valid_603678, JString, required = true,
                                 default = nil)
  if valid_603678 != nil:
    section.add "MetricName", valid_603678
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
  var valid_603679 = header.getOrDefault("X-Amz-Date")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Date", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Security-Token")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Security-Token", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-Content-Sha256", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Algorithm")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Algorithm", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Signature")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Signature", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-SignedHeaders", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Credential")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Credential", valid_603685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603686: Call_GetPutAnomalyDetector_603668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_603686.validator(path, query, header, formData, body)
  let scheme = call_603686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603686.url(scheme.get, call_603686.host, call_603686.base,
                         call_603686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603686, url, valid)

proc call*(call_603687: Call_GetPutAnomalyDetector_603668; Namespace: string;
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
  var query_603688 = newJObject()
  add(query_603688, "Namespace", newJString(Namespace))
  add(query_603688, "Stat", newJString(Stat))
  add(query_603688, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  if Dimensions != nil:
    query_603688.add "Dimensions", Dimensions
  add(query_603688, "Action", newJString(Action))
  if ConfigurationExcludedTimeRanges != nil:
    query_603688.add "Configuration.ExcludedTimeRanges",
                    ConfigurationExcludedTimeRanges
  add(query_603688, "Version", newJString(Version))
  add(query_603688, "MetricName", newJString(MetricName))
  result = call_603687.call(nil, query_603688, nil, nil, nil)

var getPutAnomalyDetector* = Call_GetPutAnomalyDetector_603668(
    name: "getPutAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_GetPutAnomalyDetector_603669, base: "/",
    url: url_GetPutAnomalyDetector_603670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutDashboard_603728 = ref object of OpenApiRestCall_602466
proc url_PostPutDashboard_603730(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutDashboard_603729(path: JsonNode; query: JsonNode;
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
  var valid_603731 = query.getOrDefault("Action")
  valid_603731 = validateParameter(valid_603731, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_603731 != nil:
    section.add "Action", valid_603731
  var valid_603732 = query.getOrDefault("Version")
  valid_603732 = validateParameter(valid_603732, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603732 != nil:
    section.add "Version", valid_603732
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
  var valid_603733 = header.getOrDefault("X-Amz-Date")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Date", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Security-Token")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Security-Token", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Content-Sha256", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Algorithm")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Algorithm", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Signature")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Signature", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-SignedHeaders", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Credential")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Credential", valid_603739
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_603740 = formData.getOrDefault("DashboardName")
  valid_603740 = validateParameter(valid_603740, JString, required = true,
                                 default = nil)
  if valid_603740 != nil:
    section.add "DashboardName", valid_603740
  var valid_603741 = formData.getOrDefault("DashboardBody")
  valid_603741 = validateParameter(valid_603741, JString, required = true,
                                 default = nil)
  if valid_603741 != nil:
    section.add "DashboardBody", valid_603741
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603742: Call_PostPutDashboard_603728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_603742.validator(path, query, header, formData, body)
  let scheme = call_603742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603742.url(scheme.get, call_603742.host, call_603742.base,
                         call_603742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603742, url, valid)

proc call*(call_603743: Call_PostPutDashboard_603728; DashboardName: string;
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
  var query_603744 = newJObject()
  var formData_603745 = newJObject()
  add(query_603744, "Action", newJString(Action))
  add(formData_603745, "DashboardName", newJString(DashboardName))
  add(formData_603745, "DashboardBody", newJString(DashboardBody))
  add(query_603744, "Version", newJString(Version))
  result = call_603743.call(nil, query_603744, nil, formData_603745, nil)

var postPutDashboard* = Call_PostPutDashboard_603728(name: "postPutDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_PostPutDashboard_603729,
    base: "/", url: url_PostPutDashboard_603730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutDashboard_603711 = ref object of OpenApiRestCall_602466
proc url_GetPutDashboard_603713(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutDashboard_603712(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_603714 = query.getOrDefault("DashboardName")
  valid_603714 = validateParameter(valid_603714, JString, required = true,
                                 default = nil)
  if valid_603714 != nil:
    section.add "DashboardName", valid_603714
  var valid_603715 = query.getOrDefault("Action")
  valid_603715 = validateParameter(valid_603715, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_603715 != nil:
    section.add "Action", valid_603715
  var valid_603716 = query.getOrDefault("DashboardBody")
  valid_603716 = validateParameter(valid_603716, JString, required = true,
                                 default = nil)
  if valid_603716 != nil:
    section.add "DashboardBody", valid_603716
  var valid_603717 = query.getOrDefault("Version")
  valid_603717 = validateParameter(valid_603717, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603717 != nil:
    section.add "Version", valid_603717
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
  var valid_603718 = header.getOrDefault("X-Amz-Date")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Date", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Security-Token")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Security-Token", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Content-Sha256", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Algorithm")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Algorithm", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Signature")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Signature", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-SignedHeaders", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-Credential")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Credential", valid_603724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603725: Call_GetPutDashboard_603711; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_603725.validator(path, query, header, formData, body)
  let scheme = call_603725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603725.url(scheme.get, call_603725.host, call_603725.base,
                         call_603725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603725, url, valid)

proc call*(call_603726: Call_GetPutDashboard_603711; DashboardName: string;
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
  var query_603727 = newJObject()
  add(query_603727, "DashboardName", newJString(DashboardName))
  add(query_603727, "Action", newJString(Action))
  add(query_603727, "DashboardBody", newJString(DashboardBody))
  add(query_603727, "Version", newJString(Version))
  result = call_603726.call(nil, query_603727, nil, nil, nil)

var getPutDashboard* = Call_GetPutDashboard_603711(name: "getPutDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_GetPutDashboard_603712,
    base: "/", url: url_GetPutDashboard_603713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricAlarm_603783 = ref object of OpenApiRestCall_602466
proc url_PostPutMetricAlarm_603785(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutMetricAlarm_603784(path: JsonNode; query: JsonNode;
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
  var valid_603786 = query.getOrDefault("Action")
  valid_603786 = validateParameter(valid_603786, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_603786 != nil:
    section.add "Action", valid_603786
  var valid_603787 = query.getOrDefault("Version")
  valid_603787 = validateParameter(valid_603787, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603787 != nil:
    section.add "Version", valid_603787
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
  var valid_603788 = header.getOrDefault("X-Amz-Date")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Date", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Security-Token")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Security-Token", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Content-Sha256", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Algorithm")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Algorithm", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Signature")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Signature", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-SignedHeaders", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-Credential")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Credential", valid_603794
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
  ##                    : The number of datapoints that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
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
  var valid_603795 = formData.getOrDefault("ActionsEnabled")
  valid_603795 = validateParameter(valid_603795, JBool, required = false, default = nil)
  if valid_603795 != nil:
    section.add "ActionsEnabled", valid_603795
  var valid_603796 = formData.getOrDefault("Threshold")
  valid_603796 = validateParameter(valid_603796, JFloat, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "Threshold", valid_603796
  var valid_603797 = formData.getOrDefault("ExtendedStatistic")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "ExtendedStatistic", valid_603797
  var valid_603798 = formData.getOrDefault("Metrics")
  valid_603798 = validateParameter(valid_603798, JArray, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "Metrics", valid_603798
  var valid_603799 = formData.getOrDefault("MetricName")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "MetricName", valid_603799
  var valid_603800 = formData.getOrDefault("TreatMissingData")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "TreatMissingData", valid_603800
  var valid_603801 = formData.getOrDefault("AlarmDescription")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "AlarmDescription", valid_603801
  var valid_603802 = formData.getOrDefault("Dimensions")
  valid_603802 = validateParameter(valid_603802, JArray, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "Dimensions", valid_603802
  assert formData != nil, "formData argument is necessary due to required `ComparisonOperator` field"
  var valid_603803 = formData.getOrDefault("ComparisonOperator")
  valid_603803 = validateParameter(valid_603803, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_603803 != nil:
    section.add "ComparisonOperator", valid_603803
  var valid_603804 = formData.getOrDefault("Tags")
  valid_603804 = validateParameter(valid_603804, JArray, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "Tags", valid_603804
  var valid_603805 = formData.getOrDefault("ThresholdMetricId")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "ThresholdMetricId", valid_603805
  var valid_603806 = formData.getOrDefault("OKActions")
  valid_603806 = validateParameter(valid_603806, JArray, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "OKActions", valid_603806
  var valid_603807 = formData.getOrDefault("Statistic")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_603807 != nil:
    section.add "Statistic", valid_603807
  var valid_603808 = formData.getOrDefault("EvaluationPeriods")
  valid_603808 = validateParameter(valid_603808, JInt, required = true, default = nil)
  if valid_603808 != nil:
    section.add "EvaluationPeriods", valid_603808
  var valid_603809 = formData.getOrDefault("DatapointsToAlarm")
  valid_603809 = validateParameter(valid_603809, JInt, required = false, default = nil)
  if valid_603809 != nil:
    section.add "DatapointsToAlarm", valid_603809
  var valid_603810 = formData.getOrDefault("AlarmName")
  valid_603810 = validateParameter(valid_603810, JString, required = true,
                                 default = nil)
  if valid_603810 != nil:
    section.add "AlarmName", valid_603810
  var valid_603811 = formData.getOrDefault("Namespace")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "Namespace", valid_603811
  var valid_603812 = formData.getOrDefault("InsufficientDataActions")
  valid_603812 = validateParameter(valid_603812, JArray, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "InsufficientDataActions", valid_603812
  var valid_603813 = formData.getOrDefault("AlarmActions")
  valid_603813 = validateParameter(valid_603813, JArray, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "AlarmActions", valid_603813
  var valid_603814 = formData.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_603814
  var valid_603815 = formData.getOrDefault("Unit")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_603815 != nil:
    section.add "Unit", valid_603815
  var valid_603816 = formData.getOrDefault("Period")
  valid_603816 = validateParameter(valid_603816, JInt, required = false, default = nil)
  if valid_603816 != nil:
    section.add "Period", valid_603816
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603817: Call_PostPutMetricAlarm_603783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_603817.validator(path, query, header, formData, body)
  let scheme = call_603817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603817.url(scheme.get, call_603817.host, call_603817.base,
                         call_603817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603817, url, valid)

proc call*(call_603818: Call_PostPutMetricAlarm_603783; EvaluationPeriods: int;
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
  ##                    : The number of datapoints that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
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
  var query_603819 = newJObject()
  var formData_603820 = newJObject()
  add(formData_603820, "ActionsEnabled", newJBool(ActionsEnabled))
  add(formData_603820, "Threshold", newJFloat(Threshold))
  add(formData_603820, "ExtendedStatistic", newJString(ExtendedStatistic))
  if Metrics != nil:
    formData_603820.add "Metrics", Metrics
  add(formData_603820, "MetricName", newJString(MetricName))
  add(formData_603820, "TreatMissingData", newJString(TreatMissingData))
  add(formData_603820, "AlarmDescription", newJString(AlarmDescription))
  if Dimensions != nil:
    formData_603820.add "Dimensions", Dimensions
  add(formData_603820, "ComparisonOperator", newJString(ComparisonOperator))
  if Tags != nil:
    formData_603820.add "Tags", Tags
  add(formData_603820, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_603819, "Action", newJString(Action))
  if OKActions != nil:
    formData_603820.add "OKActions", OKActions
  add(formData_603820, "Statistic", newJString(Statistic))
  add(formData_603820, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(formData_603820, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(formData_603820, "AlarmName", newJString(AlarmName))
  add(formData_603820, "Namespace", newJString(Namespace))
  if InsufficientDataActions != nil:
    formData_603820.add "InsufficientDataActions", InsufficientDataActions
  if AlarmActions != nil:
    formData_603820.add "AlarmActions", AlarmActions
  add(formData_603820, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  add(formData_603820, "Unit", newJString(Unit))
  add(query_603819, "Version", newJString(Version))
  add(formData_603820, "Period", newJInt(Period))
  result = call_603818.call(nil, query_603819, nil, formData_603820, nil)

var postPutMetricAlarm* = Call_PostPutMetricAlarm_603783(
    name: "postPutMetricAlarm", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutMetricAlarm",
    validator: validate_PostPutMetricAlarm_603784, base: "/",
    url: url_PostPutMetricAlarm_603785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricAlarm_603746 = ref object of OpenApiRestCall_602466
proc url_GetPutMetricAlarm_603748(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutMetricAlarm_603747(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  ##                    : The number of datapoints that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
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
  var valid_603749 = query.getOrDefault("Namespace")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "Namespace", valid_603749
  var valid_603750 = query.getOrDefault("DatapointsToAlarm")
  valid_603750 = validateParameter(valid_603750, JInt, required = false, default = nil)
  if valid_603750 != nil:
    section.add "DatapointsToAlarm", valid_603750
  assert query != nil,
        "query argument is necessary due to required `AlarmName` field"
  var valid_603751 = query.getOrDefault("AlarmName")
  valid_603751 = validateParameter(valid_603751, JString, required = true,
                                 default = nil)
  if valid_603751 != nil:
    section.add "AlarmName", valid_603751
  var valid_603752 = query.getOrDefault("Unit")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_603752 != nil:
    section.add "Unit", valid_603752
  var valid_603753 = query.getOrDefault("Threshold")
  valid_603753 = validateParameter(valid_603753, JFloat, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "Threshold", valid_603753
  var valid_603754 = query.getOrDefault("ExtendedStatistic")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "ExtendedStatistic", valid_603754
  var valid_603755 = query.getOrDefault("TreatMissingData")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "TreatMissingData", valid_603755
  var valid_603756 = query.getOrDefault("Dimensions")
  valid_603756 = validateParameter(valid_603756, JArray, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "Dimensions", valid_603756
  var valid_603757 = query.getOrDefault("Tags")
  valid_603757 = validateParameter(valid_603757, JArray, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "Tags", valid_603757
  var valid_603758 = query.getOrDefault("Action")
  valid_603758 = validateParameter(valid_603758, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_603758 != nil:
    section.add "Action", valid_603758
  var valid_603759 = query.getOrDefault("EvaluationPeriods")
  valid_603759 = validateParameter(valid_603759, JInt, required = true, default = nil)
  if valid_603759 != nil:
    section.add "EvaluationPeriods", valid_603759
  var valid_603760 = query.getOrDefault("ActionsEnabled")
  valid_603760 = validateParameter(valid_603760, JBool, required = false, default = nil)
  if valid_603760 != nil:
    section.add "ActionsEnabled", valid_603760
  var valid_603761 = query.getOrDefault("ComparisonOperator")
  valid_603761 = validateParameter(valid_603761, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_603761 != nil:
    section.add "ComparisonOperator", valid_603761
  var valid_603762 = query.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_603762
  var valid_603763 = query.getOrDefault("Metrics")
  valid_603763 = validateParameter(valid_603763, JArray, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "Metrics", valid_603763
  var valid_603764 = query.getOrDefault("InsufficientDataActions")
  valid_603764 = validateParameter(valid_603764, JArray, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "InsufficientDataActions", valid_603764
  var valid_603765 = query.getOrDefault("AlarmDescription")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "AlarmDescription", valid_603765
  var valid_603766 = query.getOrDefault("AlarmActions")
  valid_603766 = validateParameter(valid_603766, JArray, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "AlarmActions", valid_603766
  var valid_603767 = query.getOrDefault("Period")
  valid_603767 = validateParameter(valid_603767, JInt, required = false, default = nil)
  if valid_603767 != nil:
    section.add "Period", valid_603767
  var valid_603768 = query.getOrDefault("MetricName")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "MetricName", valid_603768
  var valid_603769 = query.getOrDefault("Statistic")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_603769 != nil:
    section.add "Statistic", valid_603769
  var valid_603770 = query.getOrDefault("ThresholdMetricId")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "ThresholdMetricId", valid_603770
  var valid_603771 = query.getOrDefault("Version")
  valid_603771 = validateParameter(valid_603771, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603771 != nil:
    section.add "Version", valid_603771
  var valid_603772 = query.getOrDefault("OKActions")
  valid_603772 = validateParameter(valid_603772, JArray, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "OKActions", valid_603772
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
  var valid_603773 = header.getOrDefault("X-Amz-Date")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Date", valid_603773
  var valid_603774 = header.getOrDefault("X-Amz-Security-Token")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Security-Token", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-Content-Sha256", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Algorithm")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Algorithm", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Signature")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Signature", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-SignedHeaders", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-Credential")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Credential", valid_603779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603780: Call_GetPutMetricAlarm_603746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_603780.validator(path, query, header, formData, body)
  let scheme = call_603780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603780.url(scheme.get, call_603780.host, call_603780.base,
                         call_603780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603780, url, valid)

proc call*(call_603781: Call_GetPutMetricAlarm_603746; AlarmName: string;
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
  ##                    : The number of datapoints that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
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
  var query_603782 = newJObject()
  add(query_603782, "Namespace", newJString(Namespace))
  add(query_603782, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(query_603782, "AlarmName", newJString(AlarmName))
  add(query_603782, "Unit", newJString(Unit))
  add(query_603782, "Threshold", newJFloat(Threshold))
  add(query_603782, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_603782, "TreatMissingData", newJString(TreatMissingData))
  if Dimensions != nil:
    query_603782.add "Dimensions", Dimensions
  if Tags != nil:
    query_603782.add "Tags", Tags
  add(query_603782, "Action", newJString(Action))
  add(query_603782, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(query_603782, "ActionsEnabled", newJBool(ActionsEnabled))
  add(query_603782, "ComparisonOperator", newJString(ComparisonOperator))
  add(query_603782, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  if Metrics != nil:
    query_603782.add "Metrics", Metrics
  if InsufficientDataActions != nil:
    query_603782.add "InsufficientDataActions", InsufficientDataActions
  add(query_603782, "AlarmDescription", newJString(AlarmDescription))
  if AlarmActions != nil:
    query_603782.add "AlarmActions", AlarmActions
  add(query_603782, "Period", newJInt(Period))
  add(query_603782, "MetricName", newJString(MetricName))
  add(query_603782, "Statistic", newJString(Statistic))
  add(query_603782, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_603782, "Version", newJString(Version))
  if OKActions != nil:
    query_603782.add "OKActions", OKActions
  result = call_603781.call(nil, query_603782, nil, nil, nil)

var getPutMetricAlarm* = Call_GetPutMetricAlarm_603746(name: "getPutMetricAlarm",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricAlarm", validator: validate_GetPutMetricAlarm_603747,
    base: "/", url: url_GetPutMetricAlarm_603748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricData_603838 = ref object of OpenApiRestCall_602466
proc url_PostPutMetricData_603840(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutMetricData_603839(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
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
  var valid_603841 = query.getOrDefault("Action")
  valid_603841 = validateParameter(valid_603841, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_603841 != nil:
    section.add "Action", valid_603841
  var valid_603842 = query.getOrDefault("Version")
  valid_603842 = validateParameter(valid_603842, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603842 != nil:
    section.add "Version", valid_603842
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
  var valid_603843 = header.getOrDefault("X-Amz-Date")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Date", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-Security-Token")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Security-Token", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Content-Sha256", valid_603845
  var valid_603846 = header.getOrDefault("X-Amz-Algorithm")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-Algorithm", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Signature")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Signature", valid_603847
  var valid_603848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-SignedHeaders", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-Credential")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Credential", valid_603849
  result.add "header", section
  ## parameters in `formData` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Namespace` field"
  var valid_603850 = formData.getOrDefault("Namespace")
  valid_603850 = validateParameter(valid_603850, JString, required = true,
                                 default = nil)
  if valid_603850 != nil:
    section.add "Namespace", valid_603850
  var valid_603851 = formData.getOrDefault("MetricData")
  valid_603851 = validateParameter(valid_603851, JArray, required = true, default = nil)
  if valid_603851 != nil:
    section.add "MetricData", valid_603851
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603852: Call_PostPutMetricData_603838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_603852.validator(path, query, header, formData, body)
  let scheme = call_603852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603852.url(scheme.get, call_603852.host, call_603852.base,
                         call_603852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603852, url, valid)

proc call*(call_603853: Call_PostPutMetricData_603838; Namespace: string;
          MetricData: JsonNode; Action: string = "PutMetricData";
          Version: string = "2010-08-01"): Recallable =
  ## postPutMetricData
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Namespace: string (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  ##   Version: string (required)
  var query_603854 = newJObject()
  var formData_603855 = newJObject()
  add(query_603854, "Action", newJString(Action))
  add(formData_603855, "Namespace", newJString(Namespace))
  if MetricData != nil:
    formData_603855.add "MetricData", MetricData
  add(query_603854, "Version", newJString(Version))
  result = call_603853.call(nil, query_603854, nil, formData_603855, nil)

var postPutMetricData* = Call_PostPutMetricData_603838(name: "postPutMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_PostPutMetricData_603839,
    base: "/", url: url_PostPutMetricData_603840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricData_603821 = ref object of OpenApiRestCall_602466
proc url_GetPutMetricData_603823(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutMetricData_603822(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
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
  var valid_603824 = query.getOrDefault("Namespace")
  valid_603824 = validateParameter(valid_603824, JString, required = true,
                                 default = nil)
  if valid_603824 != nil:
    section.add "Namespace", valid_603824
  var valid_603825 = query.getOrDefault("MetricData")
  valid_603825 = validateParameter(valid_603825, JArray, required = true, default = nil)
  if valid_603825 != nil:
    section.add "MetricData", valid_603825
  var valid_603826 = query.getOrDefault("Action")
  valid_603826 = validateParameter(valid_603826, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_603826 != nil:
    section.add "Action", valid_603826
  var valid_603827 = query.getOrDefault("Version")
  valid_603827 = validateParameter(valid_603827, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603827 != nil:
    section.add "Version", valid_603827
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
  var valid_603828 = header.getOrDefault("X-Amz-Date")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Date", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Security-Token")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Security-Token", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Content-Sha256", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-Algorithm")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Algorithm", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Signature")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Signature", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-SignedHeaders", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Credential")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Credential", valid_603834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603835: Call_GetPutMetricData_603821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_603835.validator(path, query, header, formData, body)
  let scheme = call_603835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603835.url(scheme.get, call_603835.host, call_603835.base,
                         call_603835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603835, url, valid)

proc call*(call_603836: Call_GetPutMetricData_603821; Namespace: string;
          MetricData: JsonNode; Action: string = "PutMetricData";
          Version: string = "2010-08-01"): Recallable =
  ## getPutMetricData
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ##   Namespace: string (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603837 = newJObject()
  add(query_603837, "Namespace", newJString(Namespace))
  if MetricData != nil:
    query_603837.add "MetricData", MetricData
  add(query_603837, "Action", newJString(Action))
  add(query_603837, "Version", newJString(Version))
  result = call_603836.call(nil, query_603837, nil, nil, nil)

var getPutMetricData* = Call_GetPutMetricData_603821(name: "getPutMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_GetPutMetricData_603822,
    base: "/", url: url_GetPutMetricData_603823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetAlarmState_603875 = ref object of OpenApiRestCall_602466
proc url_PostSetAlarmState_603877(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetAlarmState_603876(path: JsonNode; query: JsonNode;
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
  var valid_603878 = query.getOrDefault("Action")
  valid_603878 = validateParameter(valid_603878, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_603878 != nil:
    section.add "Action", valid_603878
  var valid_603879 = query.getOrDefault("Version")
  valid_603879 = validateParameter(valid_603879, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603879 != nil:
    section.add "Version", valid_603879
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
  var valid_603880 = header.getOrDefault("X-Amz-Date")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Date", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Security-Token")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Security-Token", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Content-Sha256", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Algorithm")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Algorithm", valid_603883
  var valid_603884 = header.getOrDefault("X-Amz-Signature")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Signature", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-SignedHeaders", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Credential")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Credential", valid_603886
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
  var valid_603887 = formData.getOrDefault("StateReasonData")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "StateReasonData", valid_603887
  assert formData != nil,
        "formData argument is necessary due to required `StateReason` field"
  var valid_603888 = formData.getOrDefault("StateReason")
  valid_603888 = validateParameter(valid_603888, JString, required = true,
                                 default = nil)
  if valid_603888 != nil:
    section.add "StateReason", valid_603888
  var valid_603889 = formData.getOrDefault("StateValue")
  valid_603889 = validateParameter(valid_603889, JString, required = true,
                                 default = newJString("OK"))
  if valid_603889 != nil:
    section.add "StateValue", valid_603889
  var valid_603890 = formData.getOrDefault("AlarmName")
  valid_603890 = validateParameter(valid_603890, JString, required = true,
                                 default = nil)
  if valid_603890 != nil:
    section.add "AlarmName", valid_603890
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603891: Call_PostSetAlarmState_603875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_603891.validator(path, query, header, formData, body)
  let scheme = call_603891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603891.url(scheme.get, call_603891.host, call_603891.base,
                         call_603891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603891, url, valid)

proc call*(call_603892: Call_PostSetAlarmState_603875; StateReason: string;
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
  var query_603893 = newJObject()
  var formData_603894 = newJObject()
  add(formData_603894, "StateReasonData", newJString(StateReasonData))
  add(formData_603894, "StateReason", newJString(StateReason))
  add(formData_603894, "StateValue", newJString(StateValue))
  add(query_603893, "Action", newJString(Action))
  add(formData_603894, "AlarmName", newJString(AlarmName))
  add(query_603893, "Version", newJString(Version))
  result = call_603892.call(nil, query_603893, nil, formData_603894, nil)

var postSetAlarmState* = Call_PostSetAlarmState_603875(name: "postSetAlarmState",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_PostSetAlarmState_603876,
    base: "/", url: url_PostSetAlarmState_603877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetAlarmState_603856 = ref object of OpenApiRestCall_602466
proc url_GetSetAlarmState_603858(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetAlarmState_603857(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_603859 = query.getOrDefault("AlarmName")
  valid_603859 = validateParameter(valid_603859, JString, required = true,
                                 default = nil)
  if valid_603859 != nil:
    section.add "AlarmName", valid_603859
  var valid_603860 = query.getOrDefault("Action")
  valid_603860 = validateParameter(valid_603860, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_603860 != nil:
    section.add "Action", valid_603860
  var valid_603861 = query.getOrDefault("StateValue")
  valid_603861 = validateParameter(valid_603861, JString, required = true,
                                 default = newJString("OK"))
  if valid_603861 != nil:
    section.add "StateValue", valid_603861
  var valid_603862 = query.getOrDefault("StateReasonData")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "StateReasonData", valid_603862
  var valid_603863 = query.getOrDefault("StateReason")
  valid_603863 = validateParameter(valid_603863, JString, required = true,
                                 default = nil)
  if valid_603863 != nil:
    section.add "StateReason", valid_603863
  var valid_603864 = query.getOrDefault("Version")
  valid_603864 = validateParameter(valid_603864, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603864 != nil:
    section.add "Version", valid_603864
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
  var valid_603865 = header.getOrDefault("X-Amz-Date")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Date", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Security-Token")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Security-Token", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Content-Sha256", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Algorithm")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Algorithm", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Signature")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Signature", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-SignedHeaders", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Credential")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Credential", valid_603871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603872: Call_GetSetAlarmState_603856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_603872.validator(path, query, header, formData, body)
  let scheme = call_603872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603872.url(scheme.get, call_603872.host, call_603872.base,
                         call_603872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603872, url, valid)

proc call*(call_603873: Call_GetSetAlarmState_603856; AlarmName: string;
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
  var query_603874 = newJObject()
  add(query_603874, "AlarmName", newJString(AlarmName))
  add(query_603874, "Action", newJString(Action))
  add(query_603874, "StateValue", newJString(StateValue))
  add(query_603874, "StateReasonData", newJString(StateReasonData))
  add(query_603874, "StateReason", newJString(StateReason))
  add(query_603874, "Version", newJString(Version))
  result = call_603873.call(nil, query_603874, nil, nil, nil)

var getSetAlarmState* = Call_GetSetAlarmState_603856(name: "getSetAlarmState",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_GetSetAlarmState_603857,
    base: "/", url: url_GetSetAlarmState_603858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_603912 = ref object of OpenApiRestCall_602466
proc url_PostTagResource_603914(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostTagResource_603913(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
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
  var valid_603915 = query.getOrDefault("Action")
  valid_603915 = validateParameter(valid_603915, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_603915 != nil:
    section.add "Action", valid_603915
  var valid_603916 = query.getOrDefault("Version")
  valid_603916 = validateParameter(valid_603916, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603916 != nil:
    section.add "Version", valid_603916
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
  var valid_603917 = header.getOrDefault("X-Amz-Date")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Date", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-Security-Token")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Security-Token", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Content-Sha256", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Algorithm")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Algorithm", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Signature")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Signature", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-SignedHeaders", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Credential")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Credential", valid_603923
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the resource.
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you're adding tags to. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_603924 = formData.getOrDefault("Tags")
  valid_603924 = validateParameter(valid_603924, JArray, required = true, default = nil)
  if valid_603924 != nil:
    section.add "Tags", valid_603924
  var valid_603925 = formData.getOrDefault("ResourceARN")
  valid_603925 = validateParameter(valid_603925, JString, required = true,
                                 default = nil)
  if valid_603925 != nil:
    section.add "ResourceARN", valid_603925
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603926: Call_PostTagResource_603912; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_603926.validator(path, query, header, formData, body)
  let scheme = call_603926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603926.url(scheme.get, call_603926.host, call_603926.base,
                         call_603926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603926, url, valid)

proc call*(call_603927: Call_PostTagResource_603912; Tags: JsonNode;
          ResourceARN: string; Action: string = "TagResource";
          Version: string = "2010-08-01"): Recallable =
  ## postTagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the resource.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you're adding tags to. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_603928 = newJObject()
  var formData_603929 = newJObject()
  if Tags != nil:
    formData_603929.add "Tags", Tags
  add(query_603928, "Action", newJString(Action))
  add(formData_603929, "ResourceARN", newJString(ResourceARN))
  add(query_603928, "Version", newJString(Version))
  result = call_603927.call(nil, query_603928, nil, formData_603929, nil)

var postTagResource* = Call_PostTagResource_603912(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_603913,
    base: "/", url: url_PostTagResource_603914, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_603895 = ref object of OpenApiRestCall_602466
proc url_GetTagResource_603897(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTagResource_603896(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you're adding tags to. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the resource.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceARN` field"
  var valid_603898 = query.getOrDefault("ResourceARN")
  valid_603898 = validateParameter(valid_603898, JString, required = true,
                                 default = nil)
  if valid_603898 != nil:
    section.add "ResourceARN", valid_603898
  var valid_603899 = query.getOrDefault("Tags")
  valid_603899 = validateParameter(valid_603899, JArray, required = true, default = nil)
  if valid_603899 != nil:
    section.add "Tags", valid_603899
  var valid_603900 = query.getOrDefault("Action")
  valid_603900 = validateParameter(valid_603900, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_603900 != nil:
    section.add "Action", valid_603900
  var valid_603901 = query.getOrDefault("Version")
  valid_603901 = validateParameter(valid_603901, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603901 != nil:
    section.add "Version", valid_603901
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
  var valid_603902 = header.getOrDefault("X-Amz-Date")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Date", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-Security-Token")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Security-Token", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Content-Sha256", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-Algorithm")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Algorithm", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Signature")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Signature", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-SignedHeaders", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Credential")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Credential", valid_603908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603909: Call_GetTagResource_603895; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_603909.validator(path, query, header, formData, body)
  let scheme = call_603909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603909.url(scheme.get, call_603909.host, call_603909.base,
                         call_603909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603909, url, valid)

proc call*(call_603910: Call_GetTagResource_603895; ResourceARN: string;
          Tags: JsonNode; Action: string = "TagResource";
          Version: string = "2010-08-01"): Recallable =
  ## getTagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you're adding tags to. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the resource.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603911 = newJObject()
  add(query_603911, "ResourceARN", newJString(ResourceARN))
  if Tags != nil:
    query_603911.add "Tags", Tags
  add(query_603911, "Action", newJString(Action))
  add(query_603911, "Version", newJString(Version))
  result = call_603910.call(nil, query_603911, nil, nil, nil)

var getTagResource* = Call_GetTagResource_603895(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_603896,
    base: "/", url: url_GetTagResource_603897, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_603947 = ref object of OpenApiRestCall_602466
proc url_PostUntagResource_603949(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUntagResource_603948(path: JsonNode; query: JsonNode;
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
  var valid_603950 = query.getOrDefault("Action")
  valid_603950 = validateParameter(valid_603950, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_603950 != nil:
    section.add "Action", valid_603950
  var valid_603951 = query.getOrDefault("Version")
  valid_603951 = validateParameter(valid_603951, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603951 != nil:
    section.add "Version", valid_603951
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
  var valid_603952 = header.getOrDefault("X-Amz-Date")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Date", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Security-Token")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Security-Token", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Content-Sha256", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Algorithm")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Algorithm", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Signature")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Signature", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-SignedHeaders", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Credential")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Credential", valid_603958
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
  var valid_603959 = formData.getOrDefault("ResourceARN")
  valid_603959 = validateParameter(valid_603959, JString, required = true,
                                 default = nil)
  if valid_603959 != nil:
    section.add "ResourceARN", valid_603959
  var valid_603960 = formData.getOrDefault("TagKeys")
  valid_603960 = validateParameter(valid_603960, JArray, required = true, default = nil)
  if valid_603960 != nil:
    section.add "TagKeys", valid_603960
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603961: Call_PostUntagResource_603947; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_603961.validator(path, query, header, formData, body)
  let scheme = call_603961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603961.url(scheme.get, call_603961.host, call_603961.base,
                         call_603961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603961, url, valid)

proc call*(call_603962: Call_PostUntagResource_603947; ResourceARN: string;
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
  var query_603963 = newJObject()
  var formData_603964 = newJObject()
  add(query_603963, "Action", newJString(Action))
  add(formData_603964, "ResourceARN", newJString(ResourceARN))
  if TagKeys != nil:
    formData_603964.add "TagKeys", TagKeys
  add(query_603963, "Version", newJString(Version))
  result = call_603962.call(nil, query_603963, nil, formData_603964, nil)

var postUntagResource* = Call_PostUntagResource_603947(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_603948,
    base: "/", url: url_PostUntagResource_603949,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_603930 = ref object of OpenApiRestCall_602466
proc url_GetUntagResource_603932(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUntagResource_603931(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_603933 = query.getOrDefault("ResourceARN")
  valid_603933 = validateParameter(valid_603933, JString, required = true,
                                 default = nil)
  if valid_603933 != nil:
    section.add "ResourceARN", valid_603933
  var valid_603934 = query.getOrDefault("Action")
  valid_603934 = validateParameter(valid_603934, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_603934 != nil:
    section.add "Action", valid_603934
  var valid_603935 = query.getOrDefault("TagKeys")
  valid_603935 = validateParameter(valid_603935, JArray, required = true, default = nil)
  if valid_603935 != nil:
    section.add "TagKeys", valid_603935
  var valid_603936 = query.getOrDefault("Version")
  valid_603936 = validateParameter(valid_603936, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603936 != nil:
    section.add "Version", valid_603936
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
  var valid_603937 = header.getOrDefault("X-Amz-Date")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Date", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Security-Token")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Security-Token", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Content-Sha256", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Algorithm")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Algorithm", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Signature")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Signature", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-SignedHeaders", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Credential")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Credential", valid_603943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603944: Call_GetUntagResource_603930; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_603944.validator(path, query, header, formData, body)
  let scheme = call_603944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603944.url(scheme.get, call_603944.host, call_603944.base,
                         call_603944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603944, url, valid)

proc call*(call_603945: Call_GetUntagResource_603930; ResourceARN: string;
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
  var query_603946 = newJObject()
  add(query_603946, "ResourceARN", newJString(ResourceARN))
  add(query_603946, "Action", newJString(Action))
  if TagKeys != nil:
    query_603946.add "TagKeys", TagKeys
  add(query_603946, "Version", newJString(Version))
  result = call_603945.call(nil, query_603946, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_603930(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_603931,
    base: "/", url: url_GetUntagResource_603932,
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
