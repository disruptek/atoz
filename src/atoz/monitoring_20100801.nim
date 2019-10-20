
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostDeleteAlarms_592974 = ref object of OpenApiRestCall_592364
proc url_PostDeleteAlarms_592976(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAlarms_592975(path: JsonNode; query: JsonNode;
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
  var valid_592977 = query.getOrDefault("Action")
  valid_592977 = validateParameter(valid_592977, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_592977 != nil:
    section.add "Action", valid_592977
  var valid_592978 = query.getOrDefault("Version")
  valid_592978 = validateParameter(valid_592978, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_592978 != nil:
    section.add "Version", valid_592978
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
  var valid_592979 = header.getOrDefault("X-Amz-Signature")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Signature", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Content-Sha256", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Date")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Date", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Credential")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Credential", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Security-Token")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Security-Token", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Algorithm")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Algorithm", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-SignedHeaders", valid_592985
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_592986 = formData.getOrDefault("AlarmNames")
  valid_592986 = validateParameter(valid_592986, JArray, required = true, default = nil)
  if valid_592986 != nil:
    section.add "AlarmNames", valid_592986
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592987: Call_PostDeleteAlarms_592974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_592987.validator(path, query, header, formData, body)
  let scheme = call_592987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592987.url(scheme.get, call_592987.host, call_592987.base,
                         call_592987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592987, url, valid)

proc call*(call_592988: Call_PostDeleteAlarms_592974; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  var query_592989 = newJObject()
  var formData_592990 = newJObject()
  add(query_592989, "Action", newJString(Action))
  add(query_592989, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_592990.add "AlarmNames", AlarmNames
  result = call_592988.call(nil, query_592989, nil, formData_592990, nil)

var postDeleteAlarms* = Call_PostDeleteAlarms_592974(name: "postDeleteAlarms",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_PostDeleteAlarms_592975,
    base: "/", url: url_PostDeleteAlarms_592976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAlarms_592703 = ref object of OpenApiRestCall_592364
proc url_GetDeleteAlarms_592705(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAlarms_592704(path: JsonNode; query: JsonNode;
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
  var valid_592817 = query.getOrDefault("AlarmNames")
  valid_592817 = validateParameter(valid_592817, JArray, required = true, default = nil)
  if valid_592817 != nil:
    section.add "AlarmNames", valid_592817
  var valid_592831 = query.getOrDefault("Action")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_592831 != nil:
    section.add "Action", valid_592831
  var valid_592832 = query.getOrDefault("Version")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_592832 != nil:
    section.add "Version", valid_592832
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
  var valid_592833 = header.getOrDefault("X-Amz-Signature")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Signature", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Content-Sha256", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Date")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Date", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Credential")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Credential", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Security-Token")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Security-Token", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Algorithm")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Algorithm", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-SignedHeaders", valid_592839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592862: Call_GetDeleteAlarms_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_592862.validator(path, query, header, formData, body)
  let scheme = call_592862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592862.url(scheme.get, call_592862.host, call_592862.base,
                         call_592862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592862, url, valid)

proc call*(call_592933: Call_GetDeleteAlarms_592703; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592934 = newJObject()
  if AlarmNames != nil:
    query_592934.add "AlarmNames", AlarmNames
  add(query_592934, "Action", newJString(Action))
  add(query_592934, "Version", newJString(Version))
  result = call_592933.call(nil, query_592934, nil, nil, nil)

var getDeleteAlarms* = Call_GetDeleteAlarms_592703(name: "getDeleteAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_GetDeleteAlarms_592704,
    base: "/", url: url_GetDeleteAlarms_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnomalyDetector_593010 = ref object of OpenApiRestCall_592364
proc url_PostDeleteAnomalyDetector_593012(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAnomalyDetector_593011(path: JsonNode; query: JsonNode;
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
  var valid_593013 = query.getOrDefault("Action")
  valid_593013 = validateParameter(valid_593013, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_593013 != nil:
    section.add "Action", valid_593013
  var valid_593014 = query.getOrDefault("Version")
  valid_593014 = validateParameter(valid_593014, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593014 != nil:
    section.add "Version", valid_593014
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
  var valid_593015 = header.getOrDefault("X-Amz-Signature")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Signature", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Content-Sha256", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Date")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Date", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Credential")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Credential", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Security-Token")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Security-Token", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Algorithm")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Algorithm", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-SignedHeaders", valid_593021
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
  var valid_593022 = formData.getOrDefault("Stat")
  valid_593022 = validateParameter(valid_593022, JString, required = true,
                                 default = nil)
  if valid_593022 != nil:
    section.add "Stat", valid_593022
  var valid_593023 = formData.getOrDefault("MetricName")
  valid_593023 = validateParameter(valid_593023, JString, required = true,
                                 default = nil)
  if valid_593023 != nil:
    section.add "MetricName", valid_593023
  var valid_593024 = formData.getOrDefault("Dimensions")
  valid_593024 = validateParameter(valid_593024, JArray, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "Dimensions", valid_593024
  var valid_593025 = formData.getOrDefault("Namespace")
  valid_593025 = validateParameter(valid_593025, JString, required = true,
                                 default = nil)
  if valid_593025 != nil:
    section.add "Namespace", valid_593025
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593026: Call_PostDeleteAnomalyDetector_593010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_593026.validator(path, query, header, formData, body)
  let scheme = call_593026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593026.url(scheme.get, call_593026.host, call_593026.base,
                         call_593026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593026, url, valid)

proc call*(call_593027: Call_PostDeleteAnomalyDetector_593010; Stat: string;
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
  var query_593028 = newJObject()
  var formData_593029 = newJObject()
  add(formData_593029, "Stat", newJString(Stat))
  add(formData_593029, "MetricName", newJString(MetricName))
  add(query_593028, "Action", newJString(Action))
  if Dimensions != nil:
    formData_593029.add "Dimensions", Dimensions
  add(formData_593029, "Namespace", newJString(Namespace))
  add(query_593028, "Version", newJString(Version))
  result = call_593027.call(nil, query_593028, nil, formData_593029, nil)

var postDeleteAnomalyDetector* = Call_PostDeleteAnomalyDetector_593010(
    name: "postDeleteAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_PostDeleteAnomalyDetector_593011, base: "/",
    url: url_PostDeleteAnomalyDetector_593012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnomalyDetector_592991 = ref object of OpenApiRestCall_592364
proc url_GetDeleteAnomalyDetector_592993(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAnomalyDetector_592992(path: JsonNode; query: JsonNode;
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
  var valid_592994 = query.getOrDefault("Namespace")
  valid_592994 = validateParameter(valid_592994, JString, required = true,
                                 default = nil)
  if valid_592994 != nil:
    section.add "Namespace", valid_592994
  var valid_592995 = query.getOrDefault("Dimensions")
  valid_592995 = validateParameter(valid_592995, JArray, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "Dimensions", valid_592995
  var valid_592996 = query.getOrDefault("Action")
  valid_592996 = validateParameter(valid_592996, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_592996 != nil:
    section.add "Action", valid_592996
  var valid_592997 = query.getOrDefault("Version")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_592997 != nil:
    section.add "Version", valid_592997
  var valid_592998 = query.getOrDefault("MetricName")
  valid_592998 = validateParameter(valid_592998, JString, required = true,
                                 default = nil)
  if valid_592998 != nil:
    section.add "MetricName", valid_592998
  var valid_592999 = query.getOrDefault("Stat")
  valid_592999 = validateParameter(valid_592999, JString, required = true,
                                 default = nil)
  if valid_592999 != nil:
    section.add "Stat", valid_592999
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
  var valid_593000 = header.getOrDefault("X-Amz-Signature")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Signature", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Content-Sha256", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Date")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Date", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Credential")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Credential", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Security-Token")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Security-Token", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Algorithm")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Algorithm", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-SignedHeaders", valid_593006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593007: Call_GetDeleteAnomalyDetector_592991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_593007.validator(path, query, header, formData, body)
  let scheme = call_593007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593007.url(scheme.get, call_593007.host, call_593007.base,
                         call_593007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593007, url, valid)

proc call*(call_593008: Call_GetDeleteAnomalyDetector_592991; Namespace: string;
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
  var query_593009 = newJObject()
  add(query_593009, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_593009.add "Dimensions", Dimensions
  add(query_593009, "Action", newJString(Action))
  add(query_593009, "Version", newJString(Version))
  add(query_593009, "MetricName", newJString(MetricName))
  add(query_593009, "Stat", newJString(Stat))
  result = call_593008.call(nil, query_593009, nil, nil, nil)

var getDeleteAnomalyDetector* = Call_GetDeleteAnomalyDetector_592991(
    name: "getDeleteAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_GetDeleteAnomalyDetector_592992, base: "/",
    url: url_GetDeleteAnomalyDetector_592993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDashboards_593046 = ref object of OpenApiRestCall_592364
proc url_PostDeleteDashboards_593048(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDashboards_593047(path: JsonNode; query: JsonNode;
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
  var valid_593049 = query.getOrDefault("Action")
  valid_593049 = validateParameter(valid_593049, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_593049 != nil:
    section.add "Action", valid_593049
  var valid_593050 = query.getOrDefault("Version")
  valid_593050 = validateParameter(valid_593050, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593050 != nil:
    section.add "Version", valid_593050
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
  var valid_593051 = header.getOrDefault("X-Amz-Signature")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Signature", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Content-Sha256", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Date")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Date", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Credential")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Credential", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Security-Token")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Security-Token", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Algorithm")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Algorithm", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-SignedHeaders", valid_593057
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardNames` field"
  var valid_593058 = formData.getOrDefault("DashboardNames")
  valid_593058 = validateParameter(valid_593058, JArray, required = true, default = nil)
  if valid_593058 != nil:
    section.add "DashboardNames", valid_593058
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_PostDeleteDashboards_593046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_PostDeleteDashboards_593046; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593061 = newJObject()
  var formData_593062 = newJObject()
  if DashboardNames != nil:
    formData_593062.add "DashboardNames", DashboardNames
  add(query_593061, "Action", newJString(Action))
  add(query_593061, "Version", newJString(Version))
  result = call_593060.call(nil, query_593061, nil, formData_593062, nil)

var postDeleteDashboards* = Call_PostDeleteDashboards_593046(
    name: "postDeleteDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_PostDeleteDashboards_593047, base: "/",
    url: url_PostDeleteDashboards_593048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDashboards_593030 = ref object of OpenApiRestCall_592364
proc url_GetDeleteDashboards_593032(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDashboards_593031(path: JsonNode; query: JsonNode;
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
  var valid_593033 = query.getOrDefault("DashboardNames")
  valid_593033 = validateParameter(valid_593033, JArray, required = true, default = nil)
  if valid_593033 != nil:
    section.add "DashboardNames", valid_593033
  var valid_593034 = query.getOrDefault("Action")
  valid_593034 = validateParameter(valid_593034, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_593034 != nil:
    section.add "Action", valid_593034
  var valid_593035 = query.getOrDefault("Version")
  valid_593035 = validateParameter(valid_593035, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593035 != nil:
    section.add "Version", valid_593035
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
  var valid_593036 = header.getOrDefault("X-Amz-Signature")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Signature", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Content-Sha256", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Date")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Date", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Credential")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Credential", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Security-Token")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Security-Token", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Algorithm")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Algorithm", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-SignedHeaders", valid_593042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593043: Call_GetDeleteDashboards_593030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_593043.validator(path, query, header, formData, body)
  let scheme = call_593043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593043.url(scheme.get, call_593043.host, call_593043.base,
                         call_593043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593043, url, valid)

proc call*(call_593044: Call_GetDeleteDashboards_593030; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593045 = newJObject()
  if DashboardNames != nil:
    query_593045.add "DashboardNames", DashboardNames
  add(query_593045, "Action", newJString(Action))
  add(query_593045, "Version", newJString(Version))
  result = call_593044.call(nil, query_593045, nil, nil, nil)

var getDeleteDashboards* = Call_GetDeleteDashboards_593030(
    name: "getDeleteDashboards", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_GetDeleteDashboards_593031, base: "/",
    url: url_GetDeleteDashboards_593032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmHistory_593084 = ref object of OpenApiRestCall_592364
proc url_PostDescribeAlarmHistory_593086(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAlarmHistory_593085(path: JsonNode; query: JsonNode;
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
  var valid_593087 = query.getOrDefault("Action")
  valid_593087 = validateParameter(valid_593087, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_593087 != nil:
    section.add "Action", valid_593087
  var valid_593088 = query.getOrDefault("Version")
  valid_593088 = validateParameter(valid_593088, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593088 != nil:
    section.add "Version", valid_593088
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
  var valid_593089 = header.getOrDefault("X-Amz-Signature")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Signature", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Content-Sha256", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Date")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Date", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Credential")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Credential", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Security-Token")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Security-Token", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Algorithm")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Algorithm", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-SignedHeaders", valid_593095
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
  var valid_593096 = formData.getOrDefault("AlarmName")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "AlarmName", valid_593096
  var valid_593097 = formData.getOrDefault("HistoryItemType")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_593097 != nil:
    section.add "HistoryItemType", valid_593097
  var valid_593098 = formData.getOrDefault("MaxRecords")
  valid_593098 = validateParameter(valid_593098, JInt, required = false, default = nil)
  if valid_593098 != nil:
    section.add "MaxRecords", valid_593098
  var valid_593099 = formData.getOrDefault("EndDate")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "EndDate", valid_593099
  var valid_593100 = formData.getOrDefault("NextToken")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "NextToken", valid_593100
  var valid_593101 = formData.getOrDefault("StartDate")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "StartDate", valid_593101
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593102: Call_PostDescribeAlarmHistory_593084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_593102.validator(path, query, header, formData, body)
  let scheme = call_593102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593102.url(scheme.get, call_593102.host, call_593102.base,
                         call_593102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593102, url, valid)

proc call*(call_593103: Call_PostDescribeAlarmHistory_593084;
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
  var query_593104 = newJObject()
  var formData_593105 = newJObject()
  add(formData_593105, "AlarmName", newJString(AlarmName))
  add(formData_593105, "HistoryItemType", newJString(HistoryItemType))
  add(formData_593105, "MaxRecords", newJInt(MaxRecords))
  add(formData_593105, "EndDate", newJString(EndDate))
  add(formData_593105, "NextToken", newJString(NextToken))
  add(formData_593105, "StartDate", newJString(StartDate))
  add(query_593104, "Action", newJString(Action))
  add(query_593104, "Version", newJString(Version))
  result = call_593103.call(nil, query_593104, nil, formData_593105, nil)

var postDescribeAlarmHistory* = Call_PostDescribeAlarmHistory_593084(
    name: "postDescribeAlarmHistory", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_PostDescribeAlarmHistory_593085, base: "/",
    url: url_PostDescribeAlarmHistory_593086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmHistory_593063 = ref object of OpenApiRestCall_592364
proc url_GetDescribeAlarmHistory_593065(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAlarmHistory_593064(path: JsonNode; query: JsonNode;
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
  var valid_593066 = query.getOrDefault("EndDate")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "EndDate", valid_593066
  var valid_593067 = query.getOrDefault("NextToken")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "NextToken", valid_593067
  var valid_593068 = query.getOrDefault("HistoryItemType")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_593068 != nil:
    section.add "HistoryItemType", valid_593068
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593069 = query.getOrDefault("Action")
  valid_593069 = validateParameter(valid_593069, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_593069 != nil:
    section.add "Action", valid_593069
  var valid_593070 = query.getOrDefault("AlarmName")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "AlarmName", valid_593070
  var valid_593071 = query.getOrDefault("StartDate")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "StartDate", valid_593071
  var valid_593072 = query.getOrDefault("Version")
  valid_593072 = validateParameter(valid_593072, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593072 != nil:
    section.add "Version", valid_593072
  var valid_593073 = query.getOrDefault("MaxRecords")
  valid_593073 = validateParameter(valid_593073, JInt, required = false, default = nil)
  if valid_593073 != nil:
    section.add "MaxRecords", valid_593073
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
  var valid_593074 = header.getOrDefault("X-Amz-Signature")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Signature", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Content-Sha256", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Date")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Date", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Credential")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Credential", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Security-Token")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Security-Token", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Algorithm")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Algorithm", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-SignedHeaders", valid_593080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593081: Call_GetDescribeAlarmHistory_593063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_593081.validator(path, query, header, formData, body)
  let scheme = call_593081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593081.url(scheme.get, call_593081.host, call_593081.base,
                         call_593081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593081, url, valid)

proc call*(call_593082: Call_GetDescribeAlarmHistory_593063; EndDate: string = "";
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
  var query_593083 = newJObject()
  add(query_593083, "EndDate", newJString(EndDate))
  add(query_593083, "NextToken", newJString(NextToken))
  add(query_593083, "HistoryItemType", newJString(HistoryItemType))
  add(query_593083, "Action", newJString(Action))
  add(query_593083, "AlarmName", newJString(AlarmName))
  add(query_593083, "StartDate", newJString(StartDate))
  add(query_593083, "Version", newJString(Version))
  add(query_593083, "MaxRecords", newJInt(MaxRecords))
  result = call_593082.call(nil, query_593083, nil, nil, nil)

var getDescribeAlarmHistory* = Call_GetDescribeAlarmHistory_593063(
    name: "getDescribeAlarmHistory", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_GetDescribeAlarmHistory_593064, base: "/",
    url: url_GetDescribeAlarmHistory_593065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarms_593127 = ref object of OpenApiRestCall_592364
proc url_PostDescribeAlarms_593129(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAlarms_593128(path: JsonNode; query: JsonNode;
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
  var valid_593130 = query.getOrDefault("Action")
  valid_593130 = validateParameter(valid_593130, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_593130 != nil:
    section.add "Action", valid_593130
  var valid_593131 = query.getOrDefault("Version")
  valid_593131 = validateParameter(valid_593131, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593131 != nil:
    section.add "Version", valid_593131
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
  var valid_593132 = header.getOrDefault("X-Amz-Signature")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Signature", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Content-Sha256", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Date")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Date", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Credential")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Credential", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Security-Token")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Security-Token", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Algorithm")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Algorithm", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-SignedHeaders", valid_593138
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
  var valid_593139 = formData.getOrDefault("AlarmNamePrefix")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "AlarmNamePrefix", valid_593139
  var valid_593140 = formData.getOrDefault("StateValue")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = newJString("OK"))
  if valid_593140 != nil:
    section.add "StateValue", valid_593140
  var valid_593141 = formData.getOrDefault("NextToken")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "NextToken", valid_593141
  var valid_593142 = formData.getOrDefault("MaxRecords")
  valid_593142 = validateParameter(valid_593142, JInt, required = false, default = nil)
  if valid_593142 != nil:
    section.add "MaxRecords", valid_593142
  var valid_593143 = formData.getOrDefault("ActionPrefix")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "ActionPrefix", valid_593143
  var valid_593144 = formData.getOrDefault("AlarmNames")
  valid_593144 = validateParameter(valid_593144, JArray, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "AlarmNames", valid_593144
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593145: Call_PostDescribeAlarms_593127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_593145.validator(path, query, header, formData, body)
  let scheme = call_593145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593145.url(scheme.get, call_593145.host, call_593145.base,
                         call_593145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593145, url, valid)

proc call*(call_593146: Call_PostDescribeAlarms_593127;
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
  var query_593147 = newJObject()
  var formData_593148 = newJObject()
  add(formData_593148, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(formData_593148, "StateValue", newJString(StateValue))
  add(formData_593148, "NextToken", newJString(NextToken))
  add(formData_593148, "MaxRecords", newJInt(MaxRecords))
  add(query_593147, "Action", newJString(Action))
  add(formData_593148, "ActionPrefix", newJString(ActionPrefix))
  add(query_593147, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_593148.add "AlarmNames", AlarmNames
  result = call_593146.call(nil, query_593147, nil, formData_593148, nil)

var postDescribeAlarms* = Call_PostDescribeAlarms_593127(
    name: "postDescribeAlarms", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarms",
    validator: validate_PostDescribeAlarms_593128, base: "/",
    url: url_PostDescribeAlarms_593129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarms_593106 = ref object of OpenApiRestCall_592364
proc url_GetDescribeAlarms_593108(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAlarms_593107(path: JsonNode; query: JsonNode;
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
  var valid_593109 = query.getOrDefault("StateValue")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = newJString("OK"))
  if valid_593109 != nil:
    section.add "StateValue", valid_593109
  var valid_593110 = query.getOrDefault("ActionPrefix")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "ActionPrefix", valid_593110
  var valid_593111 = query.getOrDefault("NextToken")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "NextToken", valid_593111
  var valid_593112 = query.getOrDefault("AlarmNamePrefix")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "AlarmNamePrefix", valid_593112
  var valid_593113 = query.getOrDefault("AlarmNames")
  valid_593113 = validateParameter(valid_593113, JArray, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "AlarmNames", valid_593113
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593114 = query.getOrDefault("Action")
  valid_593114 = validateParameter(valid_593114, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_593114 != nil:
    section.add "Action", valid_593114
  var valid_593115 = query.getOrDefault("Version")
  valid_593115 = validateParameter(valid_593115, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593115 != nil:
    section.add "Version", valid_593115
  var valid_593116 = query.getOrDefault("MaxRecords")
  valid_593116 = validateParameter(valid_593116, JInt, required = false, default = nil)
  if valid_593116 != nil:
    section.add "MaxRecords", valid_593116
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
  var valid_593117 = header.getOrDefault("X-Amz-Signature")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Signature", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Content-Sha256", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Date")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Date", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Credential")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Credential", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Security-Token")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Security-Token", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Algorithm")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Algorithm", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-SignedHeaders", valid_593123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593124: Call_GetDescribeAlarms_593106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_593124.validator(path, query, header, formData, body)
  let scheme = call_593124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593124.url(scheme.get, call_593124.host, call_593124.base,
                         call_593124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593124, url, valid)

proc call*(call_593125: Call_GetDescribeAlarms_593106; StateValue: string = "OK";
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
  var query_593126 = newJObject()
  add(query_593126, "StateValue", newJString(StateValue))
  add(query_593126, "ActionPrefix", newJString(ActionPrefix))
  add(query_593126, "NextToken", newJString(NextToken))
  add(query_593126, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  if AlarmNames != nil:
    query_593126.add "AlarmNames", AlarmNames
  add(query_593126, "Action", newJString(Action))
  add(query_593126, "Version", newJString(Version))
  add(query_593126, "MaxRecords", newJInt(MaxRecords))
  result = call_593125.call(nil, query_593126, nil, nil, nil)

var getDescribeAlarms* = Call_GetDescribeAlarms_593106(name: "getDescribeAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DescribeAlarms", validator: validate_GetDescribeAlarms_593107,
    base: "/", url: url_GetDescribeAlarms_593108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmsForMetric_593171 = ref object of OpenApiRestCall_592364
proc url_PostDescribeAlarmsForMetric_593173(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAlarmsForMetric_593172(path: JsonNode; query: JsonNode;
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
  var valid_593174 = query.getOrDefault("Action")
  valid_593174 = validateParameter(valid_593174, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_593174 != nil:
    section.add "Action", valid_593174
  var valid_593175 = query.getOrDefault("Version")
  valid_593175 = validateParameter(valid_593175, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593175 != nil:
    section.add "Version", valid_593175
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
  var valid_593176 = header.getOrDefault("X-Amz-Signature")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Signature", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Content-Sha256", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-Date")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Date", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Credential")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Credential", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Security-Token")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Security-Token", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Algorithm")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Algorithm", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-SignedHeaders", valid_593182
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
  var valid_593183 = formData.getOrDefault("Unit")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_593183 != nil:
    section.add "Unit", valid_593183
  var valid_593184 = formData.getOrDefault("Period")
  valid_593184 = validateParameter(valid_593184, JInt, required = false, default = nil)
  if valid_593184 != nil:
    section.add "Period", valid_593184
  var valid_593185 = formData.getOrDefault("Statistic")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_593185 != nil:
    section.add "Statistic", valid_593185
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_593186 = formData.getOrDefault("MetricName")
  valid_593186 = validateParameter(valid_593186, JString, required = true,
                                 default = nil)
  if valid_593186 != nil:
    section.add "MetricName", valid_593186
  var valid_593187 = formData.getOrDefault("Dimensions")
  valid_593187 = validateParameter(valid_593187, JArray, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "Dimensions", valid_593187
  var valid_593188 = formData.getOrDefault("Namespace")
  valid_593188 = validateParameter(valid_593188, JString, required = true,
                                 default = nil)
  if valid_593188 != nil:
    section.add "Namespace", valid_593188
  var valid_593189 = formData.getOrDefault("ExtendedStatistic")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "ExtendedStatistic", valid_593189
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593190: Call_PostDescribeAlarmsForMetric_593171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_593190.validator(path, query, header, formData, body)
  let scheme = call_593190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593190.url(scheme.get, call_593190.host, call_593190.base,
                         call_593190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593190, url, valid)

proc call*(call_593191: Call_PostDescribeAlarmsForMetric_593171;
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
  var query_593192 = newJObject()
  var formData_593193 = newJObject()
  add(formData_593193, "Unit", newJString(Unit))
  add(formData_593193, "Period", newJInt(Period))
  add(formData_593193, "Statistic", newJString(Statistic))
  add(formData_593193, "MetricName", newJString(MetricName))
  add(query_593192, "Action", newJString(Action))
  if Dimensions != nil:
    formData_593193.add "Dimensions", Dimensions
  add(formData_593193, "Namespace", newJString(Namespace))
  add(formData_593193, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_593192, "Version", newJString(Version))
  result = call_593191.call(nil, query_593192, nil, formData_593193, nil)

var postDescribeAlarmsForMetric* = Call_PostDescribeAlarmsForMetric_593171(
    name: "postDescribeAlarmsForMetric", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_PostDescribeAlarmsForMetric_593172, base: "/",
    url: url_PostDescribeAlarmsForMetric_593173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmsForMetric_593149 = ref object of OpenApiRestCall_592364
proc url_GetDescribeAlarmsForMetric_593151(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAlarmsForMetric_593150(path: JsonNode; query: JsonNode;
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
  var valid_593152 = query.getOrDefault("Statistic")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_593152 != nil:
    section.add "Statistic", valid_593152
  var valid_593153 = query.getOrDefault("Unit")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_593153 != nil:
    section.add "Unit", valid_593153
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_593154 = query.getOrDefault("Namespace")
  valid_593154 = validateParameter(valid_593154, JString, required = true,
                                 default = nil)
  if valid_593154 != nil:
    section.add "Namespace", valid_593154
  var valid_593155 = query.getOrDefault("ExtendedStatistic")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "ExtendedStatistic", valid_593155
  var valid_593156 = query.getOrDefault("Period")
  valid_593156 = validateParameter(valid_593156, JInt, required = false, default = nil)
  if valid_593156 != nil:
    section.add "Period", valid_593156
  var valid_593157 = query.getOrDefault("Dimensions")
  valid_593157 = validateParameter(valid_593157, JArray, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "Dimensions", valid_593157
  var valid_593158 = query.getOrDefault("Action")
  valid_593158 = validateParameter(valid_593158, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_593158 != nil:
    section.add "Action", valid_593158
  var valid_593159 = query.getOrDefault("Version")
  valid_593159 = validateParameter(valid_593159, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593159 != nil:
    section.add "Version", valid_593159
  var valid_593160 = query.getOrDefault("MetricName")
  valid_593160 = validateParameter(valid_593160, JString, required = true,
                                 default = nil)
  if valid_593160 != nil:
    section.add "MetricName", valid_593160
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
  var valid_593161 = header.getOrDefault("X-Amz-Signature")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Signature", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Content-Sha256", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Date")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Date", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Credential")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Credential", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Security-Token")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Security-Token", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Algorithm")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Algorithm", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-SignedHeaders", valid_593167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593168: Call_GetDescribeAlarmsForMetric_593149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_593168.validator(path, query, header, formData, body)
  let scheme = call_593168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593168.url(scheme.get, call_593168.host, call_593168.base,
                         call_593168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593168, url, valid)

proc call*(call_593169: Call_GetDescribeAlarmsForMetric_593149; Namespace: string;
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
  var query_593170 = newJObject()
  add(query_593170, "Statistic", newJString(Statistic))
  add(query_593170, "Unit", newJString(Unit))
  add(query_593170, "Namespace", newJString(Namespace))
  add(query_593170, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_593170, "Period", newJInt(Period))
  if Dimensions != nil:
    query_593170.add "Dimensions", Dimensions
  add(query_593170, "Action", newJString(Action))
  add(query_593170, "Version", newJString(Version))
  add(query_593170, "MetricName", newJString(MetricName))
  result = call_593169.call(nil, query_593170, nil, nil, nil)

var getDescribeAlarmsForMetric* = Call_GetDescribeAlarmsForMetric_593149(
    name: "getDescribeAlarmsForMetric", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_GetDescribeAlarmsForMetric_593150, base: "/",
    url: url_GetDescribeAlarmsForMetric_593151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnomalyDetectors_593214 = ref object of OpenApiRestCall_592364
proc url_PostDescribeAnomalyDetectors_593216(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAnomalyDetectors_593215(path: JsonNode; query: JsonNode;
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
  var valid_593217 = query.getOrDefault("Action")
  valid_593217 = validateParameter(valid_593217, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_593217 != nil:
    section.add "Action", valid_593217
  var valid_593218 = query.getOrDefault("Version")
  valid_593218 = validateParameter(valid_593218, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593218 != nil:
    section.add "Version", valid_593218
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
  var valid_593219 = header.getOrDefault("X-Amz-Signature")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Signature", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Content-Sha256", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Date")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Date", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Credential")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Credential", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Security-Token")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Security-Token", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Algorithm")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Algorithm", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-SignedHeaders", valid_593225
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
  var valid_593226 = formData.getOrDefault("NextToken")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "NextToken", valid_593226
  var valid_593227 = formData.getOrDefault("MetricName")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "MetricName", valid_593227
  var valid_593228 = formData.getOrDefault("Dimensions")
  valid_593228 = validateParameter(valid_593228, JArray, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "Dimensions", valid_593228
  var valid_593229 = formData.getOrDefault("Namespace")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "Namespace", valid_593229
  var valid_593230 = formData.getOrDefault("MaxResults")
  valid_593230 = validateParameter(valid_593230, JInt, required = false, default = nil)
  if valid_593230 != nil:
    section.add "MaxResults", valid_593230
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593231: Call_PostDescribeAnomalyDetectors_593214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_593231.validator(path, query, header, formData, body)
  let scheme = call_593231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593231.url(scheme.get, call_593231.host, call_593231.base,
                         call_593231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593231, url, valid)

proc call*(call_593232: Call_PostDescribeAnomalyDetectors_593214;
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
  var query_593233 = newJObject()
  var formData_593234 = newJObject()
  add(formData_593234, "NextToken", newJString(NextToken))
  add(formData_593234, "MetricName", newJString(MetricName))
  add(query_593233, "Action", newJString(Action))
  if Dimensions != nil:
    formData_593234.add "Dimensions", Dimensions
  add(formData_593234, "Namespace", newJString(Namespace))
  add(query_593233, "Version", newJString(Version))
  add(formData_593234, "MaxResults", newJInt(MaxResults))
  result = call_593232.call(nil, query_593233, nil, formData_593234, nil)

var postDescribeAnomalyDetectors* = Call_PostDescribeAnomalyDetectors_593214(
    name: "postDescribeAnomalyDetectors", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_PostDescribeAnomalyDetectors_593215, base: "/",
    url: url_PostDescribeAnomalyDetectors_593216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnomalyDetectors_593194 = ref object of OpenApiRestCall_592364
proc url_GetDescribeAnomalyDetectors_593196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAnomalyDetectors_593195(path: JsonNode; query: JsonNode;
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
  var valid_593197 = query.getOrDefault("MaxResults")
  valid_593197 = validateParameter(valid_593197, JInt, required = false, default = nil)
  if valid_593197 != nil:
    section.add "MaxResults", valid_593197
  var valid_593198 = query.getOrDefault("NextToken")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "NextToken", valid_593198
  var valid_593199 = query.getOrDefault("Namespace")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "Namespace", valid_593199
  var valid_593200 = query.getOrDefault("Dimensions")
  valid_593200 = validateParameter(valid_593200, JArray, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "Dimensions", valid_593200
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593201 = query.getOrDefault("Action")
  valid_593201 = validateParameter(valid_593201, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_593201 != nil:
    section.add "Action", valid_593201
  var valid_593202 = query.getOrDefault("Version")
  valid_593202 = validateParameter(valid_593202, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593202 != nil:
    section.add "Version", valid_593202
  var valid_593203 = query.getOrDefault("MetricName")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "MetricName", valid_593203
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
  var valid_593204 = header.getOrDefault("X-Amz-Signature")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Signature", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Content-Sha256", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Date")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Date", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Credential")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Credential", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Security-Token")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Security-Token", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Algorithm")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Algorithm", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-SignedHeaders", valid_593210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593211: Call_GetDescribeAnomalyDetectors_593194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_593211.validator(path, query, header, formData, body)
  let scheme = call_593211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593211.url(scheme.get, call_593211.host, call_593211.base,
                         call_593211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593211, url, valid)

proc call*(call_593212: Call_GetDescribeAnomalyDetectors_593194;
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
  var query_593213 = newJObject()
  add(query_593213, "MaxResults", newJInt(MaxResults))
  add(query_593213, "NextToken", newJString(NextToken))
  add(query_593213, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_593213.add "Dimensions", Dimensions
  add(query_593213, "Action", newJString(Action))
  add(query_593213, "Version", newJString(Version))
  add(query_593213, "MetricName", newJString(MetricName))
  result = call_593212.call(nil, query_593213, nil, nil, nil)

var getDescribeAnomalyDetectors* = Call_GetDescribeAnomalyDetectors_593194(
    name: "getDescribeAnomalyDetectors", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_GetDescribeAnomalyDetectors_593195, base: "/",
    url: url_GetDescribeAnomalyDetectors_593196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAlarmActions_593251 = ref object of OpenApiRestCall_592364
proc url_PostDisableAlarmActions_593253(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDisableAlarmActions_593252(path: JsonNode; query: JsonNode;
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
  var valid_593254 = query.getOrDefault("Action")
  valid_593254 = validateParameter(valid_593254, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_593254 != nil:
    section.add "Action", valid_593254
  var valid_593255 = query.getOrDefault("Version")
  valid_593255 = validateParameter(valid_593255, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593255 != nil:
    section.add "Version", valid_593255
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
  var valid_593256 = header.getOrDefault("X-Amz-Signature")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Signature", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Content-Sha256", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Date")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Date", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Credential")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Credential", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Security-Token")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Security-Token", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Algorithm")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Algorithm", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-SignedHeaders", valid_593262
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_593263 = formData.getOrDefault("AlarmNames")
  valid_593263 = validateParameter(valid_593263, JArray, required = true, default = nil)
  if valid_593263 != nil:
    section.add "AlarmNames", valid_593263
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593264: Call_PostDisableAlarmActions_593251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_593264.validator(path, query, header, formData, body)
  let scheme = call_593264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593264.url(scheme.get, call_593264.host, call_593264.base,
                         call_593264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593264, url, valid)

proc call*(call_593265: Call_PostDisableAlarmActions_593251; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_593266 = newJObject()
  var formData_593267 = newJObject()
  add(query_593266, "Action", newJString(Action))
  add(query_593266, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_593267.add "AlarmNames", AlarmNames
  result = call_593265.call(nil, query_593266, nil, formData_593267, nil)

var postDisableAlarmActions* = Call_PostDisableAlarmActions_593251(
    name: "postDisableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_PostDisableAlarmActions_593252, base: "/",
    url: url_PostDisableAlarmActions_593253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAlarmActions_593235 = ref object of OpenApiRestCall_592364
proc url_GetDisableAlarmActions_593237(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDisableAlarmActions_593236(path: JsonNode; query: JsonNode;
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
  var valid_593238 = query.getOrDefault("AlarmNames")
  valid_593238 = validateParameter(valid_593238, JArray, required = true, default = nil)
  if valid_593238 != nil:
    section.add "AlarmNames", valid_593238
  var valid_593239 = query.getOrDefault("Action")
  valid_593239 = validateParameter(valid_593239, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_593239 != nil:
    section.add "Action", valid_593239
  var valid_593240 = query.getOrDefault("Version")
  valid_593240 = validateParameter(valid_593240, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593240 != nil:
    section.add "Version", valid_593240
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
  var valid_593241 = header.getOrDefault("X-Amz-Signature")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Signature", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Content-Sha256", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Date")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Date", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Credential")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Credential", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Security-Token")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Security-Token", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Algorithm")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Algorithm", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-SignedHeaders", valid_593247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593248: Call_GetDisableAlarmActions_593235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_593248.validator(path, query, header, formData, body)
  let scheme = call_593248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593248.url(scheme.get, call_593248.host, call_593248.base,
                         call_593248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593248, url, valid)

proc call*(call_593249: Call_GetDisableAlarmActions_593235; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593250 = newJObject()
  if AlarmNames != nil:
    query_593250.add "AlarmNames", AlarmNames
  add(query_593250, "Action", newJString(Action))
  add(query_593250, "Version", newJString(Version))
  result = call_593249.call(nil, query_593250, nil, nil, nil)

var getDisableAlarmActions* = Call_GetDisableAlarmActions_593235(
    name: "getDisableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_GetDisableAlarmActions_593236, base: "/",
    url: url_GetDisableAlarmActions_593237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAlarmActions_593284 = ref object of OpenApiRestCall_592364
proc url_PostEnableAlarmActions_593286(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostEnableAlarmActions_593285(path: JsonNode; query: JsonNode;
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
  var valid_593287 = query.getOrDefault("Action")
  valid_593287 = validateParameter(valid_593287, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_593287 != nil:
    section.add "Action", valid_593287
  var valid_593288 = query.getOrDefault("Version")
  valid_593288 = validateParameter(valid_593288, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593288 != nil:
    section.add "Version", valid_593288
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
  var valid_593289 = header.getOrDefault("X-Amz-Signature")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Signature", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Content-Sha256", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Date")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Date", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Credential")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Credential", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Security-Token")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Security-Token", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Algorithm")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Algorithm", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-SignedHeaders", valid_593295
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_593296 = formData.getOrDefault("AlarmNames")
  valid_593296 = validateParameter(valid_593296, JArray, required = true, default = nil)
  if valid_593296 != nil:
    section.add "AlarmNames", valid_593296
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593297: Call_PostEnableAlarmActions_593284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_593297.validator(path, query, header, formData, body)
  let scheme = call_593297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593297.url(scheme.get, call_593297.host, call_593297.base,
                         call_593297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593297, url, valid)

proc call*(call_593298: Call_PostEnableAlarmActions_593284; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_593299 = newJObject()
  var formData_593300 = newJObject()
  add(query_593299, "Action", newJString(Action))
  add(query_593299, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_593300.add "AlarmNames", AlarmNames
  result = call_593298.call(nil, query_593299, nil, formData_593300, nil)

var postEnableAlarmActions* = Call_PostEnableAlarmActions_593284(
    name: "postEnableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_PostEnableAlarmActions_593285, base: "/",
    url: url_PostEnableAlarmActions_593286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAlarmActions_593268 = ref object of OpenApiRestCall_592364
proc url_GetEnableAlarmActions_593270(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEnableAlarmActions_593269(path: JsonNode; query: JsonNode;
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
  var valid_593271 = query.getOrDefault("AlarmNames")
  valid_593271 = validateParameter(valid_593271, JArray, required = true, default = nil)
  if valid_593271 != nil:
    section.add "AlarmNames", valid_593271
  var valid_593272 = query.getOrDefault("Action")
  valid_593272 = validateParameter(valid_593272, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_593272 != nil:
    section.add "Action", valid_593272
  var valid_593273 = query.getOrDefault("Version")
  valid_593273 = validateParameter(valid_593273, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593273 != nil:
    section.add "Version", valid_593273
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
  var valid_593274 = header.getOrDefault("X-Amz-Signature")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Signature", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Content-Sha256", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Date")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Date", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Credential")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Credential", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Security-Token")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Security-Token", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Algorithm")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Algorithm", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-SignedHeaders", valid_593280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593281: Call_GetEnableAlarmActions_593268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_593281.validator(path, query, header, formData, body)
  let scheme = call_593281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593281.url(scheme.get, call_593281.host, call_593281.base,
                         call_593281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593281, url, valid)

proc call*(call_593282: Call_GetEnableAlarmActions_593268; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593283 = newJObject()
  if AlarmNames != nil:
    query_593283.add "AlarmNames", AlarmNames
  add(query_593283, "Action", newJString(Action))
  add(query_593283, "Version", newJString(Version))
  result = call_593282.call(nil, query_593283, nil, nil, nil)

var getEnableAlarmActions* = Call_GetEnableAlarmActions_593268(
    name: "getEnableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_GetEnableAlarmActions_593269, base: "/",
    url: url_GetEnableAlarmActions_593270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetDashboard_593317 = ref object of OpenApiRestCall_592364
proc url_PostGetDashboard_593319(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetDashboard_593318(path: JsonNode; query: JsonNode;
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
  var valid_593320 = query.getOrDefault("Action")
  valid_593320 = validateParameter(valid_593320, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_593320 != nil:
    section.add "Action", valid_593320
  var valid_593321 = query.getOrDefault("Version")
  valid_593321 = validateParameter(valid_593321, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593321 != nil:
    section.add "Version", valid_593321
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
  var valid_593322 = header.getOrDefault("X-Amz-Signature")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Signature", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Content-Sha256", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Date")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Date", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Credential")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Credential", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Security-Token")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Security-Token", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-Algorithm")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Algorithm", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-SignedHeaders", valid_593328
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_593329 = formData.getOrDefault("DashboardName")
  valid_593329 = validateParameter(valid_593329, JString, required = true,
                                 default = nil)
  if valid_593329 != nil:
    section.add "DashboardName", valid_593329
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593330: Call_PostGetDashboard_593317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_593330.validator(path, query, header, formData, body)
  let scheme = call_593330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593330.url(scheme.get, call_593330.host, call_593330.base,
                         call_593330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593330, url, valid)

proc call*(call_593331: Call_PostGetDashboard_593317; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## postGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593332 = newJObject()
  var formData_593333 = newJObject()
  add(formData_593333, "DashboardName", newJString(DashboardName))
  add(query_593332, "Action", newJString(Action))
  add(query_593332, "Version", newJString(Version))
  result = call_593331.call(nil, query_593332, nil, formData_593333, nil)

var postGetDashboard* = Call_PostGetDashboard_593317(name: "postGetDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_PostGetDashboard_593318,
    base: "/", url: url_PostGetDashboard_593319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetDashboard_593301 = ref object of OpenApiRestCall_592364
proc url_GetGetDashboard_593303(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetDashboard_593302(path: JsonNode; query: JsonNode;
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
  var valid_593304 = query.getOrDefault("Action")
  valid_593304 = validateParameter(valid_593304, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_593304 != nil:
    section.add "Action", valid_593304
  var valid_593305 = query.getOrDefault("DashboardName")
  valid_593305 = validateParameter(valid_593305, JString, required = true,
                                 default = nil)
  if valid_593305 != nil:
    section.add "DashboardName", valid_593305
  var valid_593306 = query.getOrDefault("Version")
  valid_593306 = validateParameter(valid_593306, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593306 != nil:
    section.add "Version", valid_593306
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
  var valid_593307 = header.getOrDefault("X-Amz-Signature")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Signature", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Content-Sha256", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Date")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Date", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Credential")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Credential", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Security-Token")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Security-Token", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-Algorithm")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Algorithm", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-SignedHeaders", valid_593313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593314: Call_GetGetDashboard_593301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_593314.validator(path, query, header, formData, body)
  let scheme = call_593314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593314.url(scheme.get, call_593314.host, call_593314.base,
                         call_593314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593314, url, valid)

proc call*(call_593315: Call_GetGetDashboard_593301; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## getGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Version: string (required)
  var query_593316 = newJObject()
  add(query_593316, "Action", newJString(Action))
  add(query_593316, "DashboardName", newJString(DashboardName))
  add(query_593316, "Version", newJString(Version))
  result = call_593315.call(nil, query_593316, nil, nil, nil)

var getGetDashboard* = Call_GetGetDashboard_593301(name: "getGetDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_GetGetDashboard_593302,
    base: "/", url: url_GetGetDashboard_593303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricData_593355 = ref object of OpenApiRestCall_592364
proc url_PostGetMetricData_593357(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetMetricData_593356(path: JsonNode; query: JsonNode;
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
  var valid_593358 = query.getOrDefault("Action")
  valid_593358 = validateParameter(valid_593358, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_593358 != nil:
    section.add "Action", valid_593358
  var valid_593359 = query.getOrDefault("Version")
  valid_593359 = validateParameter(valid_593359, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593359 != nil:
    section.add "Version", valid_593359
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
  var valid_593360 = header.getOrDefault("X-Amz-Signature")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-Signature", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-Content-Sha256", valid_593361
  var valid_593362 = header.getOrDefault("X-Amz-Date")
  valid_593362 = validateParameter(valid_593362, JString, required = false,
                                 default = nil)
  if valid_593362 != nil:
    section.add "X-Amz-Date", valid_593362
  var valid_593363 = header.getOrDefault("X-Amz-Credential")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-Credential", valid_593363
  var valid_593364 = header.getOrDefault("X-Amz-Security-Token")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "X-Amz-Security-Token", valid_593364
  var valid_593365 = header.getOrDefault("X-Amz-Algorithm")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "X-Amz-Algorithm", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-SignedHeaders", valid_593366
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
  var valid_593367 = formData.getOrDefault("NextToken")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "NextToken", valid_593367
  var valid_593368 = formData.getOrDefault("ScanBy")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_593368 != nil:
    section.add "ScanBy", valid_593368
  assert formData != nil,
        "formData argument is necessary due to required `EndTime` field"
  var valid_593369 = formData.getOrDefault("EndTime")
  valid_593369 = validateParameter(valid_593369, JString, required = true,
                                 default = nil)
  if valid_593369 != nil:
    section.add "EndTime", valid_593369
  var valid_593370 = formData.getOrDefault("StartTime")
  valid_593370 = validateParameter(valid_593370, JString, required = true,
                                 default = nil)
  if valid_593370 != nil:
    section.add "StartTime", valid_593370
  var valid_593371 = formData.getOrDefault("MetricDataQueries")
  valid_593371 = validateParameter(valid_593371, JArray, required = true, default = nil)
  if valid_593371 != nil:
    section.add "MetricDataQueries", valid_593371
  var valid_593372 = formData.getOrDefault("MaxDatapoints")
  valid_593372 = validateParameter(valid_593372, JInt, required = false, default = nil)
  if valid_593372 != nil:
    section.add "MaxDatapoints", valid_593372
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593373: Call_PostGetMetricData_593355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_593373.validator(path, query, header, formData, body)
  let scheme = call_593373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593373.url(scheme.get, call_593373.host, call_593373.base,
                         call_593373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593373, url, valid)

proc call*(call_593374: Call_PostGetMetricData_593355; EndTime: string;
          StartTime: string; MetricDataQueries: JsonNode; NextToken: string = "";
          ScanBy: string = "TimestampDescending"; Action: string = "GetMetricData";
          Version: string = "2010-08-01"; MaxDatapoints: int = 0): Recallable =
  ## postGetMetricData
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
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
  var query_593375 = newJObject()
  var formData_593376 = newJObject()
  add(formData_593376, "NextToken", newJString(NextToken))
  add(formData_593376, "ScanBy", newJString(ScanBy))
  add(formData_593376, "EndTime", newJString(EndTime))
  add(formData_593376, "StartTime", newJString(StartTime))
  add(query_593375, "Action", newJString(Action))
  add(query_593375, "Version", newJString(Version))
  if MetricDataQueries != nil:
    formData_593376.add "MetricDataQueries", MetricDataQueries
  add(formData_593376, "MaxDatapoints", newJInt(MaxDatapoints))
  result = call_593374.call(nil, query_593375, nil, formData_593376, nil)

var postGetMetricData* = Call_PostGetMetricData_593355(name: "postGetMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_PostGetMetricData_593356,
    base: "/", url: url_PostGetMetricData_593357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricData_593334 = ref object of OpenApiRestCall_592364
proc url_GetGetMetricData_593336(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetMetricData_593335(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
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
  var valid_593337 = query.getOrDefault("NextToken")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "NextToken", valid_593337
  var valid_593338 = query.getOrDefault("MaxDatapoints")
  valid_593338 = validateParameter(valid_593338, JInt, required = false, default = nil)
  if valid_593338 != nil:
    section.add "MaxDatapoints", valid_593338
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593339 = query.getOrDefault("Action")
  valid_593339 = validateParameter(valid_593339, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_593339 != nil:
    section.add "Action", valid_593339
  var valid_593340 = query.getOrDefault("StartTime")
  valid_593340 = validateParameter(valid_593340, JString, required = true,
                                 default = nil)
  if valid_593340 != nil:
    section.add "StartTime", valid_593340
  var valid_593341 = query.getOrDefault("EndTime")
  valid_593341 = validateParameter(valid_593341, JString, required = true,
                                 default = nil)
  if valid_593341 != nil:
    section.add "EndTime", valid_593341
  var valid_593342 = query.getOrDefault("Version")
  valid_593342 = validateParameter(valid_593342, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593342 != nil:
    section.add "Version", valid_593342
  var valid_593343 = query.getOrDefault("MetricDataQueries")
  valid_593343 = validateParameter(valid_593343, JArray, required = true, default = nil)
  if valid_593343 != nil:
    section.add "MetricDataQueries", valid_593343
  var valid_593344 = query.getOrDefault("ScanBy")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_593344 != nil:
    section.add "ScanBy", valid_593344
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
  var valid_593345 = header.getOrDefault("X-Amz-Signature")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-Signature", valid_593345
  var valid_593346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-Content-Sha256", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-Date")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Date", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Credential")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Credential", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Security-Token")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Security-Token", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Algorithm")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Algorithm", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-SignedHeaders", valid_593351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593352: Call_GetGetMetricData_593334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_593352.validator(path, query, header, formData, body)
  let scheme = call_593352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593352.url(scheme.get, call_593352.host, call_593352.base,
                         call_593352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593352, url, valid)

proc call*(call_593353: Call_GetGetMetricData_593334; StartTime: string;
          EndTime: string; MetricDataQueries: JsonNode; NextToken: string = "";
          MaxDatapoints: int = 0; Action: string = "GetMetricData";
          Version: string = "2010-08-01"; ScanBy: string = "TimestampDescending"): Recallable =
  ## getGetMetricData
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
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
  var query_593354 = newJObject()
  add(query_593354, "NextToken", newJString(NextToken))
  add(query_593354, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_593354, "Action", newJString(Action))
  add(query_593354, "StartTime", newJString(StartTime))
  add(query_593354, "EndTime", newJString(EndTime))
  add(query_593354, "Version", newJString(Version))
  if MetricDataQueries != nil:
    query_593354.add "MetricDataQueries", MetricDataQueries
  add(query_593354, "ScanBy", newJString(ScanBy))
  result = call_593353.call(nil, query_593354, nil, nil, nil)

var getGetMetricData* = Call_GetGetMetricData_593334(name: "getGetMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_GetGetMetricData_593335,
    base: "/", url: url_GetGetMetricData_593336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricStatistics_593401 = ref object of OpenApiRestCall_592364
proc url_PostGetMetricStatistics_593403(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetMetricStatistics_593402(path: JsonNode; query: JsonNode;
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
  var valid_593404 = query.getOrDefault("Action")
  valid_593404 = validateParameter(valid_593404, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_593404 != nil:
    section.add "Action", valid_593404
  var valid_593405 = query.getOrDefault("Version")
  valid_593405 = validateParameter(valid_593405, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593405 != nil:
    section.add "Version", valid_593405
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
  var valid_593406 = header.getOrDefault("X-Amz-Signature")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-Signature", valid_593406
  var valid_593407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-Content-Sha256", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-Date")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Date", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-Credential")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Credential", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Security-Token")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Security-Token", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Algorithm")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Algorithm", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-SignedHeaders", valid_593412
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
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   StartTime: JString (required)
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   MetricName: JString (required)
  ##             : The name of the metric, with or without spaces.
  ##   Dimensions: JArray
  ##             : The dimensions. If the metric contains multiple dimensions, you must include a value for each dimension. CloudWatch treats each unique combination of dimensions as a separate metric. If a specific combination of dimensions was not published, you can't retrieve statistics for it. You must specify the same dimensions that were used when the metrics were created. For an example, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#dimension-combinations">Dimension Combinations</a> in the <i>Amazon CloudWatch User Guide</i>. For more information about specifying dimensions, see <a 
  ## href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.
  ##   Namespace: JString (required)
  ##            : The namespace of the metric, with or without spaces.
  section = newJObject()
  var valid_593413 = formData.getOrDefault("Unit")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_593413 != nil:
    section.add "Unit", valid_593413
  assert formData != nil,
        "formData argument is necessary due to required `Period` field"
  var valid_593414 = formData.getOrDefault("Period")
  valid_593414 = validateParameter(valid_593414, JInt, required = true, default = nil)
  if valid_593414 != nil:
    section.add "Period", valid_593414
  var valid_593415 = formData.getOrDefault("Statistics")
  valid_593415 = validateParameter(valid_593415, JArray, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "Statistics", valid_593415
  var valid_593416 = formData.getOrDefault("ExtendedStatistics")
  valid_593416 = validateParameter(valid_593416, JArray, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "ExtendedStatistics", valid_593416
  var valid_593417 = formData.getOrDefault("EndTime")
  valid_593417 = validateParameter(valid_593417, JString, required = true,
                                 default = nil)
  if valid_593417 != nil:
    section.add "EndTime", valid_593417
  var valid_593418 = formData.getOrDefault("StartTime")
  valid_593418 = validateParameter(valid_593418, JString, required = true,
                                 default = nil)
  if valid_593418 != nil:
    section.add "StartTime", valid_593418
  var valid_593419 = formData.getOrDefault("MetricName")
  valid_593419 = validateParameter(valid_593419, JString, required = true,
                                 default = nil)
  if valid_593419 != nil:
    section.add "MetricName", valid_593419
  var valid_593420 = formData.getOrDefault("Dimensions")
  valid_593420 = validateParameter(valid_593420, JArray, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "Dimensions", valid_593420
  var valid_593421 = formData.getOrDefault("Namespace")
  valid_593421 = validateParameter(valid_593421, JString, required = true,
                                 default = nil)
  if valid_593421 != nil:
    section.add "Namespace", valid_593421
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593422: Call_PostGetMetricStatistics_593401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_593422.validator(path, query, header, formData, body)
  let scheme = call_593422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593422.url(scheme.get, call_593422.host, call_593422.base,
                         call_593422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593422, url, valid)

proc call*(call_593423: Call_PostGetMetricStatistics_593401; Period: int;
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
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   StartTime: string (required)
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
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
  var query_593424 = newJObject()
  var formData_593425 = newJObject()
  add(formData_593425, "Unit", newJString(Unit))
  add(formData_593425, "Period", newJInt(Period))
  if Statistics != nil:
    formData_593425.add "Statistics", Statistics
  if ExtendedStatistics != nil:
    formData_593425.add "ExtendedStatistics", ExtendedStatistics
  add(formData_593425, "EndTime", newJString(EndTime))
  add(formData_593425, "StartTime", newJString(StartTime))
  add(formData_593425, "MetricName", newJString(MetricName))
  add(query_593424, "Action", newJString(Action))
  if Dimensions != nil:
    formData_593425.add "Dimensions", Dimensions
  add(formData_593425, "Namespace", newJString(Namespace))
  add(query_593424, "Version", newJString(Version))
  result = call_593423.call(nil, query_593424, nil, formData_593425, nil)

var postGetMetricStatistics* = Call_PostGetMetricStatistics_593401(
    name: "postGetMetricStatistics", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_PostGetMetricStatistics_593402, base: "/",
    url: url_PostGetMetricStatistics_593403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricStatistics_593377 = ref object of OpenApiRestCall_592364
proc url_GetGetMetricStatistics_593379(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetMetricStatistics_593378(path: JsonNode; query: JsonNode;
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
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   EndTime: JString (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Version: JString (required)
  ##   MetricName: JString (required)
  ##             : The name of the metric, with or without spaces.
  section = newJObject()
  var valid_593380 = query.getOrDefault("Unit")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_593380 != nil:
    section.add "Unit", valid_593380
  var valid_593381 = query.getOrDefault("ExtendedStatistics")
  valid_593381 = validateParameter(valid_593381, JArray, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "ExtendedStatistics", valid_593381
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_593382 = query.getOrDefault("Namespace")
  valid_593382 = validateParameter(valid_593382, JString, required = true,
                                 default = nil)
  if valid_593382 != nil:
    section.add "Namespace", valid_593382
  var valid_593383 = query.getOrDefault("Statistics")
  valid_593383 = validateParameter(valid_593383, JArray, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "Statistics", valid_593383
  var valid_593384 = query.getOrDefault("Period")
  valid_593384 = validateParameter(valid_593384, JInt, required = true, default = nil)
  if valid_593384 != nil:
    section.add "Period", valid_593384
  var valid_593385 = query.getOrDefault("Dimensions")
  valid_593385 = validateParameter(valid_593385, JArray, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "Dimensions", valid_593385
  var valid_593386 = query.getOrDefault("Action")
  valid_593386 = validateParameter(valid_593386, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_593386 != nil:
    section.add "Action", valid_593386
  var valid_593387 = query.getOrDefault("StartTime")
  valid_593387 = validateParameter(valid_593387, JString, required = true,
                                 default = nil)
  if valid_593387 != nil:
    section.add "StartTime", valid_593387
  var valid_593388 = query.getOrDefault("EndTime")
  valid_593388 = validateParameter(valid_593388, JString, required = true,
                                 default = nil)
  if valid_593388 != nil:
    section.add "EndTime", valid_593388
  var valid_593389 = query.getOrDefault("Version")
  valid_593389 = validateParameter(valid_593389, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593389 != nil:
    section.add "Version", valid_593389
  var valid_593390 = query.getOrDefault("MetricName")
  valid_593390 = validateParameter(valid_593390, JString, required = true,
                                 default = nil)
  if valid_593390 != nil:
    section.add "MetricName", valid_593390
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
  var valid_593391 = header.getOrDefault("X-Amz-Signature")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Signature", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Content-Sha256", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Date")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Date", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Credential")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Credential", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Security-Token")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Security-Token", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Algorithm")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Algorithm", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-SignedHeaders", valid_593397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593398: Call_GetGetMetricStatistics_593377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_593398.validator(path, query, header, formData, body)
  let scheme = call_593398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593398.url(scheme.get, call_593398.host, call_593398.base,
                         call_593398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593398, url, valid)

proc call*(call_593399: Call_GetGetMetricStatistics_593377; Namespace: string;
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
  ##            : <p>The time stamp that determines the first data point to return. Start times are evaluated relative to the time that CloudWatch receives the request.</p> <p>The value specified is inclusive; results include data points with the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).</p> <p>CloudWatch rounds the specified time stamp as follows:</p> <ul> <li> <p>Start time less than 15 days ago - Round down to the nearest whole minute. For example, 12:32:34 is rounded down to 12:32:00.</p> </li> <li> <p>Start time between 15 and 63 days ago - Round down to the nearest 5-minute clock interval. For example, 12:32:34 is rounded down to 12:30:00.</p> </li> <li> <p>Start time greater than 63 days ago - Round down to the nearest 1-hour clock interval. For example, 12:32:34 is rounded down to 12:00:00.</p> </li> </ul> <p>If you set <code>Period</code> to 5, 10, or 30, the start time of your request is rounded down to the nearest time that corresponds to even 5-, 10-, or 30-second divisions of a minute. For example, if you make a query at (HH:mm:ss) 01:05:23 for the previous 10-second period, the start time of your request is rounded down and you receive data from 01:05:10 to 01:05:20. If you make a query at 15:07:17 for the previous 5 minutes of data, using a period of 5 seconds, you receive data timestamped between 15:02:15 and 15:07:15. </p>
  ##   EndTime: string (required)
  ##          : <p>The time stamp that determines the last data point to return.</p> <p>The value specified is exclusive; results include data points up to the specified time stamp. The time stamp must be in ISO 8601 UTC format (for example, 2016-10-10T23:00:00Z).</p>
  ##   Version: string (required)
  ##   MetricName: string (required)
  ##             : The name of the metric, with or without spaces.
  var query_593400 = newJObject()
  add(query_593400, "Unit", newJString(Unit))
  if ExtendedStatistics != nil:
    query_593400.add "ExtendedStatistics", ExtendedStatistics
  add(query_593400, "Namespace", newJString(Namespace))
  if Statistics != nil:
    query_593400.add "Statistics", Statistics
  add(query_593400, "Period", newJInt(Period))
  if Dimensions != nil:
    query_593400.add "Dimensions", Dimensions
  add(query_593400, "Action", newJString(Action))
  add(query_593400, "StartTime", newJString(StartTime))
  add(query_593400, "EndTime", newJString(EndTime))
  add(query_593400, "Version", newJString(Version))
  add(query_593400, "MetricName", newJString(MetricName))
  result = call_593399.call(nil, query_593400, nil, nil, nil)

var getGetMetricStatistics* = Call_GetGetMetricStatistics_593377(
    name: "getGetMetricStatistics", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_GetGetMetricStatistics_593378, base: "/",
    url: url_GetGetMetricStatistics_593379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricWidgetImage_593443 = ref object of OpenApiRestCall_592364
proc url_PostGetMetricWidgetImage_593445(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetMetricWidgetImage_593444(path: JsonNode; query: JsonNode;
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
  var valid_593446 = query.getOrDefault("Action")
  valid_593446 = validateParameter(valid_593446, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_593446 != nil:
    section.add "Action", valid_593446
  var valid_593447 = query.getOrDefault("Version")
  valid_593447 = validateParameter(valid_593447, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593447 != nil:
    section.add "Version", valid_593447
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
  var valid_593448 = header.getOrDefault("X-Amz-Signature")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Signature", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Content-Sha256", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Date")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Date", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Credential")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Credential", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Security-Token")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Security-Token", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Algorithm")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Algorithm", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-SignedHeaders", valid_593454
  result.add "header", section
  ## parameters in `formData` object:
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MetricWidget` field"
  var valid_593455 = formData.getOrDefault("MetricWidget")
  valid_593455 = validateParameter(valid_593455, JString, required = true,
                                 default = nil)
  if valid_593455 != nil:
    section.add "MetricWidget", valid_593455
  var valid_593456 = formData.getOrDefault("OutputFormat")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "OutputFormat", valid_593456
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593457: Call_PostGetMetricWidgetImage_593443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_593457.validator(path, query, header, formData, body)
  let scheme = call_593457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593457.url(scheme.get, call_593457.host, call_593457.base,
                         call_593457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593457, url, valid)

proc call*(call_593458: Call_PostGetMetricWidgetImage_593443; MetricWidget: string;
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
  var query_593459 = newJObject()
  var formData_593460 = newJObject()
  add(formData_593460, "MetricWidget", newJString(MetricWidget))
  add(formData_593460, "OutputFormat", newJString(OutputFormat))
  add(query_593459, "Action", newJString(Action))
  add(query_593459, "Version", newJString(Version))
  result = call_593458.call(nil, query_593459, nil, formData_593460, nil)

var postGetMetricWidgetImage* = Call_PostGetMetricWidgetImage_593443(
    name: "postGetMetricWidgetImage", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_PostGetMetricWidgetImage_593444, base: "/",
    url: url_PostGetMetricWidgetImage_593445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricWidgetImage_593426 = ref object of OpenApiRestCall_592364
proc url_GetGetMetricWidgetImage_593428(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetMetricWidgetImage_593427(path: JsonNode; query: JsonNode;
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
  var valid_593429 = query.getOrDefault("OutputFormat")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "OutputFormat", valid_593429
  assert query != nil,
        "query argument is necessary due to required `MetricWidget` field"
  var valid_593430 = query.getOrDefault("MetricWidget")
  valid_593430 = validateParameter(valid_593430, JString, required = true,
                                 default = nil)
  if valid_593430 != nil:
    section.add "MetricWidget", valid_593430
  var valid_593431 = query.getOrDefault("Action")
  valid_593431 = validateParameter(valid_593431, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_593431 != nil:
    section.add "Action", valid_593431
  var valid_593432 = query.getOrDefault("Version")
  valid_593432 = validateParameter(valid_593432, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593432 != nil:
    section.add "Version", valid_593432
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
  var valid_593433 = header.getOrDefault("X-Amz-Signature")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Signature", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Content-Sha256", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-Date")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Date", valid_593435
  var valid_593436 = header.getOrDefault("X-Amz-Credential")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Credential", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Security-Token")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Security-Token", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-Algorithm")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Algorithm", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-SignedHeaders", valid_593439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593440: Call_GetGetMetricWidgetImage_593426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_593440.validator(path, query, header, formData, body)
  let scheme = call_593440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593440.url(scheme.get, call_593440.host, call_593440.base,
                         call_593440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593440, url, valid)

proc call*(call_593441: Call_GetGetMetricWidgetImage_593426; MetricWidget: string;
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
  var query_593442 = newJObject()
  add(query_593442, "OutputFormat", newJString(OutputFormat))
  add(query_593442, "MetricWidget", newJString(MetricWidget))
  add(query_593442, "Action", newJString(Action))
  add(query_593442, "Version", newJString(Version))
  result = call_593441.call(nil, query_593442, nil, nil, nil)

var getGetMetricWidgetImage* = Call_GetGetMetricWidgetImage_593426(
    name: "getGetMetricWidgetImage", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_GetGetMetricWidgetImage_593427, base: "/",
    url: url_GetGetMetricWidgetImage_593428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDashboards_593478 = ref object of OpenApiRestCall_592364
proc url_PostListDashboards_593480(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListDashboards_593479(path: JsonNode; query: JsonNode;
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
  var valid_593481 = query.getOrDefault("Action")
  valid_593481 = validateParameter(valid_593481, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_593481 != nil:
    section.add "Action", valid_593481
  var valid_593482 = query.getOrDefault("Version")
  valid_593482 = validateParameter(valid_593482, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593482 != nil:
    section.add "Version", valid_593482
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
  var valid_593483 = header.getOrDefault("X-Amz-Signature")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Signature", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Content-Sha256", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-Date")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Date", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Credential")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Credential", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Security-Token")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Security-Token", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Algorithm")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Algorithm", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-SignedHeaders", valid_593489
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   DashboardNamePrefix: JString
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  section = newJObject()
  var valid_593490 = formData.getOrDefault("NextToken")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "NextToken", valid_593490
  var valid_593491 = formData.getOrDefault("DashboardNamePrefix")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "DashboardNamePrefix", valid_593491
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593492: Call_PostListDashboards_593478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_593492.validator(path, query, header, formData, body)
  let scheme = call_593492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593492.url(scheme.get, call_593492.host, call_593492.base,
                         call_593492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593492, url, valid)

proc call*(call_593493: Call_PostListDashboards_593478; NextToken: string = "";
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
  var query_593494 = newJObject()
  var formData_593495 = newJObject()
  add(formData_593495, "NextToken", newJString(NextToken))
  add(formData_593495, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_593494, "Action", newJString(Action))
  add(query_593494, "Version", newJString(Version))
  result = call_593493.call(nil, query_593494, nil, formData_593495, nil)

var postListDashboards* = Call_PostListDashboards_593478(
    name: "postListDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListDashboards",
    validator: validate_PostListDashboards_593479, base: "/",
    url: url_PostListDashboards_593480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDashboards_593461 = ref object of OpenApiRestCall_592364
proc url_GetListDashboards_593463(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListDashboards_593462(path: JsonNode; query: JsonNode;
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
  var valid_593464 = query.getOrDefault("DashboardNamePrefix")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "DashboardNamePrefix", valid_593464
  var valid_593465 = query.getOrDefault("NextToken")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "NextToken", valid_593465
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593466 = query.getOrDefault("Action")
  valid_593466 = validateParameter(valid_593466, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_593466 != nil:
    section.add "Action", valid_593466
  var valid_593467 = query.getOrDefault("Version")
  valid_593467 = validateParameter(valid_593467, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593467 != nil:
    section.add "Version", valid_593467
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
  var valid_593468 = header.getOrDefault("X-Amz-Signature")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-Signature", valid_593468
  var valid_593469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Content-Sha256", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-Date")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Date", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-Credential")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Credential", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Security-Token")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Security-Token", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Algorithm")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Algorithm", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-SignedHeaders", valid_593474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593475: Call_GetListDashboards_593461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_593475.validator(path, query, header, formData, body)
  let scheme = call_593475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593475.url(scheme.get, call_593475.host, call_593475.base,
                         call_593475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593475, url, valid)

proc call*(call_593476: Call_GetListDashboards_593461;
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
  var query_593477 = newJObject()
  add(query_593477, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_593477, "NextToken", newJString(NextToken))
  add(query_593477, "Action", newJString(Action))
  add(query_593477, "Version", newJString(Version))
  result = call_593476.call(nil, query_593477, nil, nil, nil)

var getListDashboards* = Call_GetListDashboards_593461(name: "getListDashboards",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListDashboards", validator: validate_GetListDashboards_593462,
    base: "/", url: url_GetListDashboards_593463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListMetrics_593515 = ref object of OpenApiRestCall_592364
proc url_PostListMetrics_593517(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListMetrics_593516(path: JsonNode; query: JsonNode;
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
  var valid_593518 = query.getOrDefault("Action")
  valid_593518 = validateParameter(valid_593518, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_593518 != nil:
    section.add "Action", valid_593518
  var valid_593519 = query.getOrDefault("Version")
  valid_593519 = validateParameter(valid_593519, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593519 != nil:
    section.add "Version", valid_593519
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
  var valid_593520 = header.getOrDefault("X-Amz-Signature")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Signature", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Content-Sha256", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Date")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Date", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-Credential")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Credential", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-Security-Token")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-Security-Token", valid_593524
  var valid_593525 = header.getOrDefault("X-Amz-Algorithm")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-Algorithm", valid_593525
  var valid_593526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "X-Amz-SignedHeaders", valid_593526
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
  var valid_593527 = formData.getOrDefault("NextToken")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "NextToken", valid_593527
  var valid_593528 = formData.getOrDefault("MetricName")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "MetricName", valid_593528
  var valid_593529 = formData.getOrDefault("Dimensions")
  valid_593529 = validateParameter(valid_593529, JArray, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "Dimensions", valid_593529
  var valid_593530 = formData.getOrDefault("Namespace")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "Namespace", valid_593530
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593531: Call_PostListMetrics_593515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_593531.validator(path, query, header, formData, body)
  let scheme = call_593531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593531.url(scheme.get, call_593531.host, call_593531.base,
                         call_593531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593531, url, valid)

proc call*(call_593532: Call_PostListMetrics_593515; NextToken: string = "";
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
  var query_593533 = newJObject()
  var formData_593534 = newJObject()
  add(formData_593534, "NextToken", newJString(NextToken))
  add(formData_593534, "MetricName", newJString(MetricName))
  add(query_593533, "Action", newJString(Action))
  if Dimensions != nil:
    formData_593534.add "Dimensions", Dimensions
  add(formData_593534, "Namespace", newJString(Namespace))
  add(query_593533, "Version", newJString(Version))
  result = call_593532.call(nil, query_593533, nil, formData_593534, nil)

var postListMetrics* = Call_PostListMetrics_593515(name: "postListMetrics",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_PostListMetrics_593516,
    base: "/", url: url_PostListMetrics_593517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListMetrics_593496 = ref object of OpenApiRestCall_592364
proc url_GetListMetrics_593498(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListMetrics_593497(path: JsonNode; query: JsonNode;
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
  var valid_593499 = query.getOrDefault("NextToken")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "NextToken", valid_593499
  var valid_593500 = query.getOrDefault("Namespace")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "Namespace", valid_593500
  var valid_593501 = query.getOrDefault("Dimensions")
  valid_593501 = validateParameter(valid_593501, JArray, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "Dimensions", valid_593501
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593502 = query.getOrDefault("Action")
  valid_593502 = validateParameter(valid_593502, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_593502 != nil:
    section.add "Action", valid_593502
  var valid_593503 = query.getOrDefault("Version")
  valid_593503 = validateParameter(valid_593503, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593503 != nil:
    section.add "Version", valid_593503
  var valid_593504 = query.getOrDefault("MetricName")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "MetricName", valid_593504
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
  var valid_593505 = header.getOrDefault("X-Amz-Signature")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Signature", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-Content-Sha256", valid_593506
  var valid_593507 = header.getOrDefault("X-Amz-Date")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-Date", valid_593507
  var valid_593508 = header.getOrDefault("X-Amz-Credential")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "X-Amz-Credential", valid_593508
  var valid_593509 = header.getOrDefault("X-Amz-Security-Token")
  valid_593509 = validateParameter(valid_593509, JString, required = false,
                                 default = nil)
  if valid_593509 != nil:
    section.add "X-Amz-Security-Token", valid_593509
  var valid_593510 = header.getOrDefault("X-Amz-Algorithm")
  valid_593510 = validateParameter(valid_593510, JString, required = false,
                                 default = nil)
  if valid_593510 != nil:
    section.add "X-Amz-Algorithm", valid_593510
  var valid_593511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593511 = validateParameter(valid_593511, JString, required = false,
                                 default = nil)
  if valid_593511 != nil:
    section.add "X-Amz-SignedHeaders", valid_593511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593512: Call_GetListMetrics_593496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_593512.validator(path, query, header, formData, body)
  let scheme = call_593512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593512.url(scheme.get, call_593512.host, call_593512.base,
                         call_593512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593512, url, valid)

proc call*(call_593513: Call_GetListMetrics_593496; NextToken: string = "";
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
  var query_593514 = newJObject()
  add(query_593514, "NextToken", newJString(NextToken))
  add(query_593514, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_593514.add "Dimensions", Dimensions
  add(query_593514, "Action", newJString(Action))
  add(query_593514, "Version", newJString(Version))
  add(query_593514, "MetricName", newJString(MetricName))
  result = call_593513.call(nil, query_593514, nil, nil, nil)

var getListMetrics* = Call_GetListMetrics_593496(name: "getListMetrics",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_GetListMetrics_593497,
    base: "/", url: url_GetListMetrics_593498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_593551 = ref object of OpenApiRestCall_592364
proc url_PostListTagsForResource_593553(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_593552(path: JsonNode; query: JsonNode;
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
  var valid_593554 = query.getOrDefault("Action")
  valid_593554 = validateParameter(valid_593554, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_593554 != nil:
    section.add "Action", valid_593554
  var valid_593555 = query.getOrDefault("Version")
  valid_593555 = validateParameter(valid_593555, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593555 != nil:
    section.add "Version", valid_593555
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
  var valid_593556 = header.getOrDefault("X-Amz-Signature")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Signature", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-Content-Sha256", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-Date")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-Date", valid_593558
  var valid_593559 = header.getOrDefault("X-Amz-Credential")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-Credential", valid_593559
  var valid_593560 = header.getOrDefault("X-Amz-Security-Token")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-Security-Token", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-Algorithm")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-Algorithm", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-SignedHeaders", valid_593562
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceARN` field"
  var valid_593563 = formData.getOrDefault("ResourceARN")
  valid_593563 = validateParameter(valid_593563, JString, required = true,
                                 default = nil)
  if valid_593563 != nil:
    section.add "ResourceARN", valid_593563
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593564: Call_PostListTagsForResource_593551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_593564.validator(path, query, header, formData, body)
  let scheme = call_593564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593564.url(scheme.get, call_593564.host, call_593564.base,
                         call_593564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593564, url, valid)

proc call*(call_593565: Call_PostListTagsForResource_593551; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## postListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  var query_593566 = newJObject()
  var formData_593567 = newJObject()
  add(query_593566, "Action", newJString(Action))
  add(query_593566, "Version", newJString(Version))
  add(formData_593567, "ResourceARN", newJString(ResourceARN))
  result = call_593565.call(nil, query_593566, nil, formData_593567, nil)

var postListTagsForResource* = Call_PostListTagsForResource_593551(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_593552, base: "/",
    url: url_PostListTagsForResource_593553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_593535 = ref object of OpenApiRestCall_592364
proc url_GetListTagsForResource_593537(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_593536(path: JsonNode; query: JsonNode;
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
  var valid_593538 = query.getOrDefault("Action")
  valid_593538 = validateParameter(valid_593538, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_593538 != nil:
    section.add "Action", valid_593538
  var valid_593539 = query.getOrDefault("ResourceARN")
  valid_593539 = validateParameter(valid_593539, JString, required = true,
                                 default = nil)
  if valid_593539 != nil:
    section.add "ResourceARN", valid_593539
  var valid_593540 = query.getOrDefault("Version")
  valid_593540 = validateParameter(valid_593540, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593540 != nil:
    section.add "Version", valid_593540
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
  var valid_593541 = header.getOrDefault("X-Amz-Signature")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "X-Amz-Signature", valid_593541
  var valid_593542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593542 = validateParameter(valid_593542, JString, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "X-Amz-Content-Sha256", valid_593542
  var valid_593543 = header.getOrDefault("X-Amz-Date")
  valid_593543 = validateParameter(valid_593543, JString, required = false,
                                 default = nil)
  if valid_593543 != nil:
    section.add "X-Amz-Date", valid_593543
  var valid_593544 = header.getOrDefault("X-Amz-Credential")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-Credential", valid_593544
  var valid_593545 = header.getOrDefault("X-Amz-Security-Token")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "X-Amz-Security-Token", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-Algorithm")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-Algorithm", valid_593546
  var valid_593547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-SignedHeaders", valid_593547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593548: Call_GetListTagsForResource_593535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_593548.validator(path, query, header, formData, body)
  let scheme = call_593548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593548.url(scheme.get, call_593548.host, call_593548.base,
                         call_593548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593548, url, valid)

proc call*(call_593549: Call_GetListTagsForResource_593535; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## getListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_593550 = newJObject()
  add(query_593550, "Action", newJString(Action))
  add(query_593550, "ResourceARN", newJString(ResourceARN))
  add(query_593550, "Version", newJString(Version))
  result = call_593549.call(nil, query_593550, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_593535(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_593536, base: "/",
    url: url_GetListTagsForResource_593537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAnomalyDetector_593589 = ref object of OpenApiRestCall_592364
proc url_PostPutAnomalyDetector_593591(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutAnomalyDetector_593590(path: JsonNode; query: JsonNode;
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
  var valid_593592 = query.getOrDefault("Action")
  valid_593592 = validateParameter(valid_593592, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_593592 != nil:
    section.add "Action", valid_593592
  var valid_593593 = query.getOrDefault("Version")
  valid_593593 = validateParameter(valid_593593, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593593 != nil:
    section.add "Version", valid_593593
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
  var valid_593594 = header.getOrDefault("X-Amz-Signature")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-Signature", valid_593594
  var valid_593595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593595 = validateParameter(valid_593595, JString, required = false,
                                 default = nil)
  if valid_593595 != nil:
    section.add "X-Amz-Content-Sha256", valid_593595
  var valid_593596 = header.getOrDefault("X-Amz-Date")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Date", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-Credential")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-Credential", valid_593597
  var valid_593598 = header.getOrDefault("X-Amz-Security-Token")
  valid_593598 = validateParameter(valid_593598, JString, required = false,
                                 default = nil)
  if valid_593598 != nil:
    section.add "X-Amz-Security-Token", valid_593598
  var valid_593599 = header.getOrDefault("X-Amz-Algorithm")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Algorithm", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-SignedHeaders", valid_593600
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
  var valid_593601 = formData.getOrDefault("Stat")
  valid_593601 = validateParameter(valid_593601, JString, required = true,
                                 default = nil)
  if valid_593601 != nil:
    section.add "Stat", valid_593601
  var valid_593602 = formData.getOrDefault("Configuration.MetricTimezone")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "Configuration.MetricTimezone", valid_593602
  var valid_593603 = formData.getOrDefault("MetricName")
  valid_593603 = validateParameter(valid_593603, JString, required = true,
                                 default = nil)
  if valid_593603 != nil:
    section.add "MetricName", valid_593603
  var valid_593604 = formData.getOrDefault("Dimensions")
  valid_593604 = validateParameter(valid_593604, JArray, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "Dimensions", valid_593604
  var valid_593605 = formData.getOrDefault("Namespace")
  valid_593605 = validateParameter(valid_593605, JString, required = true,
                                 default = nil)
  if valid_593605 != nil:
    section.add "Namespace", valid_593605
  var valid_593606 = formData.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_593606 = validateParameter(valid_593606, JArray, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_593606
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593607: Call_PostPutAnomalyDetector_593589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_593607.validator(path, query, header, formData, body)
  let scheme = call_593607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593607.url(scheme.get, call_593607.host, call_593607.base,
                         call_593607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593607, url, valid)

proc call*(call_593608: Call_PostPutAnomalyDetector_593589; Stat: string;
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
  var query_593609 = newJObject()
  var formData_593610 = newJObject()
  add(formData_593610, "Stat", newJString(Stat))
  add(formData_593610, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  add(formData_593610, "MetricName", newJString(MetricName))
  add(query_593609, "Action", newJString(Action))
  if Dimensions != nil:
    formData_593610.add "Dimensions", Dimensions
  add(formData_593610, "Namespace", newJString(Namespace))
  if ConfigurationExcludedTimeRanges != nil:
    formData_593610.add "Configuration.ExcludedTimeRanges",
                       ConfigurationExcludedTimeRanges
  add(query_593609, "Version", newJString(Version))
  result = call_593608.call(nil, query_593609, nil, formData_593610, nil)

var postPutAnomalyDetector* = Call_PostPutAnomalyDetector_593589(
    name: "postPutAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_PostPutAnomalyDetector_593590, base: "/",
    url: url_PostPutAnomalyDetector_593591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAnomalyDetector_593568 = ref object of OpenApiRestCall_592364
proc url_GetPutAnomalyDetector_593570(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutAnomalyDetector_593569(path: JsonNode; query: JsonNode;
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
  var valid_593571 = query.getOrDefault("Namespace")
  valid_593571 = validateParameter(valid_593571, JString, required = true,
                                 default = nil)
  if valid_593571 != nil:
    section.add "Namespace", valid_593571
  var valid_593572 = query.getOrDefault("Configuration.MetricTimezone")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "Configuration.MetricTimezone", valid_593572
  var valid_593573 = query.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_593573 = validateParameter(valid_593573, JArray, required = false,
                                 default = nil)
  if valid_593573 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_593573
  var valid_593574 = query.getOrDefault("Dimensions")
  valid_593574 = validateParameter(valid_593574, JArray, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "Dimensions", valid_593574
  var valid_593575 = query.getOrDefault("Action")
  valid_593575 = validateParameter(valid_593575, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_593575 != nil:
    section.add "Action", valid_593575
  var valid_593576 = query.getOrDefault("Version")
  valid_593576 = validateParameter(valid_593576, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593576 != nil:
    section.add "Version", valid_593576
  var valid_593577 = query.getOrDefault("MetricName")
  valid_593577 = validateParameter(valid_593577, JString, required = true,
                                 default = nil)
  if valid_593577 != nil:
    section.add "MetricName", valid_593577
  var valid_593578 = query.getOrDefault("Stat")
  valid_593578 = validateParameter(valid_593578, JString, required = true,
                                 default = nil)
  if valid_593578 != nil:
    section.add "Stat", valid_593578
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
  var valid_593579 = header.getOrDefault("X-Amz-Signature")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "X-Amz-Signature", valid_593579
  var valid_593580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-Content-Sha256", valid_593580
  var valid_593581 = header.getOrDefault("X-Amz-Date")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-Date", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-Credential")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-Credential", valid_593582
  var valid_593583 = header.getOrDefault("X-Amz-Security-Token")
  valid_593583 = validateParameter(valid_593583, JString, required = false,
                                 default = nil)
  if valid_593583 != nil:
    section.add "X-Amz-Security-Token", valid_593583
  var valid_593584 = header.getOrDefault("X-Amz-Algorithm")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Algorithm", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-SignedHeaders", valid_593585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593586: Call_GetPutAnomalyDetector_593568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_593586.validator(path, query, header, formData, body)
  let scheme = call_593586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593586.url(scheme.get, call_593586.host, call_593586.base,
                         call_593586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593586, url, valid)

proc call*(call_593587: Call_GetPutAnomalyDetector_593568; Namespace: string;
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
  var query_593588 = newJObject()
  add(query_593588, "Namespace", newJString(Namespace))
  add(query_593588, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  if ConfigurationExcludedTimeRanges != nil:
    query_593588.add "Configuration.ExcludedTimeRanges",
                    ConfigurationExcludedTimeRanges
  if Dimensions != nil:
    query_593588.add "Dimensions", Dimensions
  add(query_593588, "Action", newJString(Action))
  add(query_593588, "Version", newJString(Version))
  add(query_593588, "MetricName", newJString(MetricName))
  add(query_593588, "Stat", newJString(Stat))
  result = call_593587.call(nil, query_593588, nil, nil, nil)

var getPutAnomalyDetector* = Call_GetPutAnomalyDetector_593568(
    name: "getPutAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_GetPutAnomalyDetector_593569, base: "/",
    url: url_GetPutAnomalyDetector_593570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutDashboard_593628 = ref object of OpenApiRestCall_592364
proc url_PostPutDashboard_593630(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutDashboard_593629(path: JsonNode; query: JsonNode;
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
  var valid_593631 = query.getOrDefault("Action")
  valid_593631 = validateParameter(valid_593631, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_593631 != nil:
    section.add "Action", valid_593631
  var valid_593632 = query.getOrDefault("Version")
  valid_593632 = validateParameter(valid_593632, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593632 != nil:
    section.add "Version", valid_593632
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
  var valid_593633 = header.getOrDefault("X-Amz-Signature")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Signature", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-Content-Sha256", valid_593634
  var valid_593635 = header.getOrDefault("X-Amz-Date")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "X-Amz-Date", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-Credential")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-Credential", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-Security-Token")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Security-Token", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-Algorithm")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-Algorithm", valid_593638
  var valid_593639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-SignedHeaders", valid_593639
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_593640 = formData.getOrDefault("DashboardName")
  valid_593640 = validateParameter(valid_593640, JString, required = true,
                                 default = nil)
  if valid_593640 != nil:
    section.add "DashboardName", valid_593640
  var valid_593641 = formData.getOrDefault("DashboardBody")
  valid_593641 = validateParameter(valid_593641, JString, required = true,
                                 default = nil)
  if valid_593641 != nil:
    section.add "DashboardBody", valid_593641
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593642: Call_PostPutDashboard_593628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_593642.validator(path, query, header, formData, body)
  let scheme = call_593642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593642.url(scheme.get, call_593642.host, call_593642.base,
                         call_593642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593642, url, valid)

proc call*(call_593643: Call_PostPutDashboard_593628; DashboardName: string;
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
  var query_593644 = newJObject()
  var formData_593645 = newJObject()
  add(formData_593645, "DashboardName", newJString(DashboardName))
  add(query_593644, "Action", newJString(Action))
  add(formData_593645, "DashboardBody", newJString(DashboardBody))
  add(query_593644, "Version", newJString(Version))
  result = call_593643.call(nil, query_593644, nil, formData_593645, nil)

var postPutDashboard* = Call_PostPutDashboard_593628(name: "postPutDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_PostPutDashboard_593629,
    base: "/", url: url_PostPutDashboard_593630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutDashboard_593611 = ref object of OpenApiRestCall_592364
proc url_GetPutDashboard_593613(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutDashboard_593612(path: JsonNode; query: JsonNode;
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
  var valid_593614 = query.getOrDefault("DashboardBody")
  valid_593614 = validateParameter(valid_593614, JString, required = true,
                                 default = nil)
  if valid_593614 != nil:
    section.add "DashboardBody", valid_593614
  var valid_593615 = query.getOrDefault("Action")
  valid_593615 = validateParameter(valid_593615, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_593615 != nil:
    section.add "Action", valid_593615
  var valid_593616 = query.getOrDefault("DashboardName")
  valid_593616 = validateParameter(valid_593616, JString, required = true,
                                 default = nil)
  if valid_593616 != nil:
    section.add "DashboardName", valid_593616
  var valid_593617 = query.getOrDefault("Version")
  valid_593617 = validateParameter(valid_593617, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593617 != nil:
    section.add "Version", valid_593617
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
  var valid_593618 = header.getOrDefault("X-Amz-Signature")
  valid_593618 = validateParameter(valid_593618, JString, required = false,
                                 default = nil)
  if valid_593618 != nil:
    section.add "X-Amz-Signature", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Content-Sha256", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Date")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Date", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Credential")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Credential", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Security-Token")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Security-Token", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-Algorithm")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Algorithm", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-SignedHeaders", valid_593624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593625: Call_GetPutDashboard_593611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_593625.validator(path, query, header, formData, body)
  let scheme = call_593625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593625.url(scheme.get, call_593625.host, call_593625.base,
                         call_593625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593625, url, valid)

proc call*(call_593626: Call_GetPutDashboard_593611; DashboardBody: string;
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
  var query_593627 = newJObject()
  add(query_593627, "DashboardBody", newJString(DashboardBody))
  add(query_593627, "Action", newJString(Action))
  add(query_593627, "DashboardName", newJString(DashboardName))
  add(query_593627, "Version", newJString(Version))
  result = call_593626.call(nil, query_593627, nil, nil, nil)

var getPutDashboard* = Call_GetPutDashboard_593611(name: "getPutDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_GetPutDashboard_593612,
    base: "/", url: url_GetPutDashboard_593613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricAlarm_593683 = ref object of OpenApiRestCall_592364
proc url_PostPutMetricAlarm_593685(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutMetricAlarm_593684(path: JsonNode; query: JsonNode;
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
  var valid_593686 = query.getOrDefault("Action")
  valid_593686 = validateParameter(valid_593686, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_593686 != nil:
    section.add "Action", valid_593686
  var valid_593687 = query.getOrDefault("Version")
  valid_593687 = validateParameter(valid_593687, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593687 != nil:
    section.add "Version", valid_593687
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
  var valid_593688 = header.getOrDefault("X-Amz-Signature")
  valid_593688 = validateParameter(valid_593688, JString, required = false,
                                 default = nil)
  if valid_593688 != nil:
    section.add "X-Amz-Signature", valid_593688
  var valid_593689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593689 = validateParameter(valid_593689, JString, required = false,
                                 default = nil)
  if valid_593689 != nil:
    section.add "X-Amz-Content-Sha256", valid_593689
  var valid_593690 = header.getOrDefault("X-Amz-Date")
  valid_593690 = validateParameter(valid_593690, JString, required = false,
                                 default = nil)
  if valid_593690 != nil:
    section.add "X-Amz-Date", valid_593690
  var valid_593691 = header.getOrDefault("X-Amz-Credential")
  valid_593691 = validateParameter(valid_593691, JString, required = false,
                                 default = nil)
  if valid_593691 != nil:
    section.add "X-Amz-Credential", valid_593691
  var valid_593692 = header.getOrDefault("X-Amz-Security-Token")
  valid_593692 = validateParameter(valid_593692, JString, required = false,
                                 default = nil)
  if valid_593692 != nil:
    section.add "X-Amz-Security-Token", valid_593692
  var valid_593693 = header.getOrDefault("X-Amz-Algorithm")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Algorithm", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-SignedHeaders", valid_593694
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
  ##                    : The number of datapoints that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
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
  var valid_593695 = formData.getOrDefault("ActionsEnabled")
  valid_593695 = validateParameter(valid_593695, JBool, required = false, default = nil)
  if valid_593695 != nil:
    section.add "ActionsEnabled", valid_593695
  var valid_593696 = formData.getOrDefault("AlarmDescription")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "AlarmDescription", valid_593696
  assert formData != nil,
        "formData argument is necessary due to required `AlarmName` field"
  var valid_593697 = formData.getOrDefault("AlarmName")
  valid_593697 = validateParameter(valid_593697, JString, required = true,
                                 default = nil)
  if valid_593697 != nil:
    section.add "AlarmName", valid_593697
  var valid_593698 = formData.getOrDefault("ThresholdMetricId")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "ThresholdMetricId", valid_593698
  var valid_593699 = formData.getOrDefault("Unit")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_593699 != nil:
    section.add "Unit", valid_593699
  var valid_593700 = formData.getOrDefault("Period")
  valid_593700 = validateParameter(valid_593700, JInt, required = false, default = nil)
  if valid_593700 != nil:
    section.add "Period", valid_593700
  var valid_593701 = formData.getOrDefault("AlarmActions")
  valid_593701 = validateParameter(valid_593701, JArray, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "AlarmActions", valid_593701
  var valid_593702 = formData.getOrDefault("ComparisonOperator")
  valid_593702 = validateParameter(valid_593702, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_593702 != nil:
    section.add "ComparisonOperator", valid_593702
  var valid_593703 = formData.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_593703 = validateParameter(valid_593703, JString, required = false,
                                 default = nil)
  if valid_593703 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_593703
  var valid_593704 = formData.getOrDefault("OKActions")
  valid_593704 = validateParameter(valid_593704, JArray, required = false,
                                 default = nil)
  if valid_593704 != nil:
    section.add "OKActions", valid_593704
  var valid_593705 = formData.getOrDefault("Statistic")
  valid_593705 = validateParameter(valid_593705, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_593705 != nil:
    section.add "Statistic", valid_593705
  var valid_593706 = formData.getOrDefault("TreatMissingData")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "TreatMissingData", valid_593706
  var valid_593707 = formData.getOrDefault("InsufficientDataActions")
  valid_593707 = validateParameter(valid_593707, JArray, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "InsufficientDataActions", valid_593707
  var valid_593708 = formData.getOrDefault("DatapointsToAlarm")
  valid_593708 = validateParameter(valid_593708, JInt, required = false, default = nil)
  if valid_593708 != nil:
    section.add "DatapointsToAlarm", valid_593708
  var valid_593709 = formData.getOrDefault("MetricName")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "MetricName", valid_593709
  var valid_593710 = formData.getOrDefault("Dimensions")
  valid_593710 = validateParameter(valid_593710, JArray, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "Dimensions", valid_593710
  var valid_593711 = formData.getOrDefault("Tags")
  valid_593711 = validateParameter(valid_593711, JArray, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "Tags", valid_593711
  var valid_593712 = formData.getOrDefault("Namespace")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "Namespace", valid_593712
  var valid_593713 = formData.getOrDefault("ExtendedStatistic")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "ExtendedStatistic", valid_593713
  var valid_593714 = formData.getOrDefault("EvaluationPeriods")
  valid_593714 = validateParameter(valid_593714, JInt, required = true, default = nil)
  if valid_593714 != nil:
    section.add "EvaluationPeriods", valid_593714
  var valid_593715 = formData.getOrDefault("Threshold")
  valid_593715 = validateParameter(valid_593715, JFloat, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "Threshold", valid_593715
  var valid_593716 = formData.getOrDefault("Metrics")
  valid_593716 = validateParameter(valid_593716, JArray, required = false,
                                 default = nil)
  if valid_593716 != nil:
    section.add "Metrics", valid_593716
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593717: Call_PostPutMetricAlarm_593683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_593717.validator(path, query, header, formData, body)
  let scheme = call_593717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593717.url(scheme.get, call_593717.host, call_593717.base,
                         call_593717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593717, url, valid)

proc call*(call_593718: Call_PostPutMetricAlarm_593683; AlarmName: string;
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
  ##                    : The number of datapoints that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
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
  var query_593719 = newJObject()
  var formData_593720 = newJObject()
  add(formData_593720, "ActionsEnabled", newJBool(ActionsEnabled))
  add(formData_593720, "AlarmDescription", newJString(AlarmDescription))
  add(formData_593720, "AlarmName", newJString(AlarmName))
  add(formData_593720, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(formData_593720, "Unit", newJString(Unit))
  add(formData_593720, "Period", newJInt(Period))
  if AlarmActions != nil:
    formData_593720.add "AlarmActions", AlarmActions
  add(formData_593720, "ComparisonOperator", newJString(ComparisonOperator))
  add(formData_593720, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  if OKActions != nil:
    formData_593720.add "OKActions", OKActions
  add(formData_593720, "Statistic", newJString(Statistic))
  add(formData_593720, "TreatMissingData", newJString(TreatMissingData))
  if InsufficientDataActions != nil:
    formData_593720.add "InsufficientDataActions", InsufficientDataActions
  add(formData_593720, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(formData_593720, "MetricName", newJString(MetricName))
  add(query_593719, "Action", newJString(Action))
  if Dimensions != nil:
    formData_593720.add "Dimensions", Dimensions
  if Tags != nil:
    formData_593720.add "Tags", Tags
  add(formData_593720, "Namespace", newJString(Namespace))
  add(formData_593720, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_593719, "Version", newJString(Version))
  add(formData_593720, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(formData_593720, "Threshold", newJFloat(Threshold))
  if Metrics != nil:
    formData_593720.add "Metrics", Metrics
  result = call_593718.call(nil, query_593719, nil, formData_593720, nil)

var postPutMetricAlarm* = Call_PostPutMetricAlarm_593683(
    name: "postPutMetricAlarm", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutMetricAlarm",
    validator: validate_PostPutMetricAlarm_593684, base: "/",
    url: url_PostPutMetricAlarm_593685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricAlarm_593646 = ref object of OpenApiRestCall_592364
proc url_GetPutMetricAlarm_593648(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutMetricAlarm_593647(path: JsonNode; query: JsonNode;
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
  ##                    : The number of datapoints that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
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
  var valid_593649 = query.getOrDefault("InsufficientDataActions")
  valid_593649 = validateParameter(valid_593649, JArray, required = false,
                                 default = nil)
  if valid_593649 != nil:
    section.add "InsufficientDataActions", valid_593649
  var valid_593650 = query.getOrDefault("Statistic")
  valid_593650 = validateParameter(valid_593650, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_593650 != nil:
    section.add "Statistic", valid_593650
  var valid_593651 = query.getOrDefault("AlarmDescription")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "AlarmDescription", valid_593651
  var valid_593652 = query.getOrDefault("Unit")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_593652 != nil:
    section.add "Unit", valid_593652
  var valid_593653 = query.getOrDefault("DatapointsToAlarm")
  valid_593653 = validateParameter(valid_593653, JInt, required = false, default = nil)
  if valid_593653 != nil:
    section.add "DatapointsToAlarm", valid_593653
  var valid_593654 = query.getOrDefault("Threshold")
  valid_593654 = validateParameter(valid_593654, JFloat, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "Threshold", valid_593654
  var valid_593655 = query.getOrDefault("Tags")
  valid_593655 = validateParameter(valid_593655, JArray, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "Tags", valid_593655
  var valid_593656 = query.getOrDefault("ThresholdMetricId")
  valid_593656 = validateParameter(valid_593656, JString, required = false,
                                 default = nil)
  if valid_593656 != nil:
    section.add "ThresholdMetricId", valid_593656
  var valid_593657 = query.getOrDefault("Namespace")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "Namespace", valid_593657
  var valid_593658 = query.getOrDefault("TreatMissingData")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "TreatMissingData", valid_593658
  var valid_593659 = query.getOrDefault("ExtendedStatistic")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "ExtendedStatistic", valid_593659
  var valid_593660 = query.getOrDefault("OKActions")
  valid_593660 = validateParameter(valid_593660, JArray, required = false,
                                 default = nil)
  if valid_593660 != nil:
    section.add "OKActions", valid_593660
  var valid_593661 = query.getOrDefault("Dimensions")
  valid_593661 = validateParameter(valid_593661, JArray, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "Dimensions", valid_593661
  var valid_593662 = query.getOrDefault("Period")
  valid_593662 = validateParameter(valid_593662, JInt, required = false, default = nil)
  if valid_593662 != nil:
    section.add "Period", valid_593662
  assert query != nil,
        "query argument is necessary due to required `AlarmName` field"
  var valid_593663 = query.getOrDefault("AlarmName")
  valid_593663 = validateParameter(valid_593663, JString, required = true,
                                 default = nil)
  if valid_593663 != nil:
    section.add "AlarmName", valid_593663
  var valid_593664 = query.getOrDefault("Action")
  valid_593664 = validateParameter(valid_593664, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_593664 != nil:
    section.add "Action", valid_593664
  var valid_593665 = query.getOrDefault("EvaluationPeriods")
  valid_593665 = validateParameter(valid_593665, JInt, required = true, default = nil)
  if valid_593665 != nil:
    section.add "EvaluationPeriods", valid_593665
  var valid_593666 = query.getOrDefault("ActionsEnabled")
  valid_593666 = validateParameter(valid_593666, JBool, required = false, default = nil)
  if valid_593666 != nil:
    section.add "ActionsEnabled", valid_593666
  var valid_593667 = query.getOrDefault("ComparisonOperator")
  valid_593667 = validateParameter(valid_593667, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_593667 != nil:
    section.add "ComparisonOperator", valid_593667
  var valid_593668 = query.getOrDefault("AlarmActions")
  valid_593668 = validateParameter(valid_593668, JArray, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "AlarmActions", valid_593668
  var valid_593669 = query.getOrDefault("Metrics")
  valid_593669 = validateParameter(valid_593669, JArray, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "Metrics", valid_593669
  var valid_593670 = query.getOrDefault("Version")
  valid_593670 = validateParameter(valid_593670, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593670 != nil:
    section.add "Version", valid_593670
  var valid_593671 = query.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_593671 = validateParameter(valid_593671, JString, required = false,
                                 default = nil)
  if valid_593671 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_593671
  var valid_593672 = query.getOrDefault("MetricName")
  valid_593672 = validateParameter(valid_593672, JString, required = false,
                                 default = nil)
  if valid_593672 != nil:
    section.add "MetricName", valid_593672
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
  var valid_593673 = header.getOrDefault("X-Amz-Signature")
  valid_593673 = validateParameter(valid_593673, JString, required = false,
                                 default = nil)
  if valid_593673 != nil:
    section.add "X-Amz-Signature", valid_593673
  var valid_593674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Content-Sha256", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Date")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Date", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-Credential")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Credential", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Security-Token")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Security-Token", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-Algorithm")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-Algorithm", valid_593678
  var valid_593679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "X-Amz-SignedHeaders", valid_593679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593680: Call_GetPutMetricAlarm_593646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_593680.validator(path, query, header, formData, body)
  let scheme = call_593680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593680.url(scheme.get, call_593680.host, call_593680.base,
                         call_593680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593680, url, valid)

proc call*(call_593681: Call_GetPutMetricAlarm_593646; AlarmName: string;
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
  ##                    : The number of datapoints that must be breaching to trigger the alarm. This is used only if you are setting an "M out of N" alarm. In that case, this value is the M. For more information, see <a 
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
  var query_593682 = newJObject()
  if InsufficientDataActions != nil:
    query_593682.add "InsufficientDataActions", InsufficientDataActions
  add(query_593682, "Statistic", newJString(Statistic))
  add(query_593682, "AlarmDescription", newJString(AlarmDescription))
  add(query_593682, "Unit", newJString(Unit))
  add(query_593682, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(query_593682, "Threshold", newJFloat(Threshold))
  if Tags != nil:
    query_593682.add "Tags", Tags
  add(query_593682, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_593682, "Namespace", newJString(Namespace))
  add(query_593682, "TreatMissingData", newJString(TreatMissingData))
  add(query_593682, "ExtendedStatistic", newJString(ExtendedStatistic))
  if OKActions != nil:
    query_593682.add "OKActions", OKActions
  if Dimensions != nil:
    query_593682.add "Dimensions", Dimensions
  add(query_593682, "Period", newJInt(Period))
  add(query_593682, "AlarmName", newJString(AlarmName))
  add(query_593682, "Action", newJString(Action))
  add(query_593682, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(query_593682, "ActionsEnabled", newJBool(ActionsEnabled))
  add(query_593682, "ComparisonOperator", newJString(ComparisonOperator))
  if AlarmActions != nil:
    query_593682.add "AlarmActions", AlarmActions
  if Metrics != nil:
    query_593682.add "Metrics", Metrics
  add(query_593682, "Version", newJString(Version))
  add(query_593682, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  add(query_593682, "MetricName", newJString(MetricName))
  result = call_593681.call(nil, query_593682, nil, nil, nil)

var getPutMetricAlarm* = Call_GetPutMetricAlarm_593646(name: "getPutMetricAlarm",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricAlarm", validator: validate_GetPutMetricAlarm_593647,
    base: "/", url: url_GetPutMetricAlarm_593648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricData_593738 = ref object of OpenApiRestCall_592364
proc url_PostPutMetricData_593740(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutMetricData_593739(path: JsonNode; query: JsonNode;
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
  var valid_593741 = query.getOrDefault("Action")
  valid_593741 = validateParameter(valid_593741, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_593741 != nil:
    section.add "Action", valid_593741
  var valid_593742 = query.getOrDefault("Version")
  valid_593742 = validateParameter(valid_593742, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593742 != nil:
    section.add "Version", valid_593742
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
  var valid_593743 = header.getOrDefault("X-Amz-Signature")
  valid_593743 = validateParameter(valid_593743, JString, required = false,
                                 default = nil)
  if valid_593743 != nil:
    section.add "X-Amz-Signature", valid_593743
  var valid_593744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593744 = validateParameter(valid_593744, JString, required = false,
                                 default = nil)
  if valid_593744 != nil:
    section.add "X-Amz-Content-Sha256", valid_593744
  var valid_593745 = header.getOrDefault("X-Amz-Date")
  valid_593745 = validateParameter(valid_593745, JString, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "X-Amz-Date", valid_593745
  var valid_593746 = header.getOrDefault("X-Amz-Credential")
  valid_593746 = validateParameter(valid_593746, JString, required = false,
                                 default = nil)
  if valid_593746 != nil:
    section.add "X-Amz-Credential", valid_593746
  var valid_593747 = header.getOrDefault("X-Amz-Security-Token")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "X-Amz-Security-Token", valid_593747
  var valid_593748 = header.getOrDefault("X-Amz-Algorithm")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "X-Amz-Algorithm", valid_593748
  var valid_593749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593749 = validateParameter(valid_593749, JString, required = false,
                                 default = nil)
  if valid_593749 != nil:
    section.add "X-Amz-SignedHeaders", valid_593749
  result.add "header", section
  ## parameters in `formData` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Namespace` field"
  var valid_593750 = formData.getOrDefault("Namespace")
  valid_593750 = validateParameter(valid_593750, JString, required = true,
                                 default = nil)
  if valid_593750 != nil:
    section.add "Namespace", valid_593750
  var valid_593751 = formData.getOrDefault("MetricData")
  valid_593751 = validateParameter(valid_593751, JArray, required = true, default = nil)
  if valid_593751 != nil:
    section.add "MetricData", valid_593751
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593752: Call_PostPutMetricData_593738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_593752.validator(path, query, header, formData, body)
  let scheme = call_593752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593752.url(scheme.get, call_593752.host, call_593752.base,
                         call_593752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593752, url, valid)

proc call*(call_593753: Call_PostPutMetricData_593738; Namespace: string;
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
  var query_593754 = newJObject()
  var formData_593755 = newJObject()
  add(query_593754, "Action", newJString(Action))
  add(formData_593755, "Namespace", newJString(Namespace))
  if MetricData != nil:
    formData_593755.add "MetricData", MetricData
  add(query_593754, "Version", newJString(Version))
  result = call_593753.call(nil, query_593754, nil, formData_593755, nil)

var postPutMetricData* = Call_PostPutMetricData_593738(name: "postPutMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_PostPutMetricData_593739,
    base: "/", url: url_PostPutMetricData_593740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricData_593721 = ref object of OpenApiRestCall_592364
proc url_GetPutMetricData_593723(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutMetricData_593722(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_593724 = query.getOrDefault("Namespace")
  valid_593724 = validateParameter(valid_593724, JString, required = true,
                                 default = nil)
  if valid_593724 != nil:
    section.add "Namespace", valid_593724
  var valid_593725 = query.getOrDefault("Action")
  valid_593725 = validateParameter(valid_593725, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_593725 != nil:
    section.add "Action", valid_593725
  var valid_593726 = query.getOrDefault("Version")
  valid_593726 = validateParameter(valid_593726, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593726 != nil:
    section.add "Version", valid_593726
  var valid_593727 = query.getOrDefault("MetricData")
  valid_593727 = validateParameter(valid_593727, JArray, required = true, default = nil)
  if valid_593727 != nil:
    section.add "MetricData", valid_593727
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
  var valid_593728 = header.getOrDefault("X-Amz-Signature")
  valid_593728 = validateParameter(valid_593728, JString, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "X-Amz-Signature", valid_593728
  var valid_593729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "X-Amz-Content-Sha256", valid_593729
  var valid_593730 = header.getOrDefault("X-Amz-Date")
  valid_593730 = validateParameter(valid_593730, JString, required = false,
                                 default = nil)
  if valid_593730 != nil:
    section.add "X-Amz-Date", valid_593730
  var valid_593731 = header.getOrDefault("X-Amz-Credential")
  valid_593731 = validateParameter(valid_593731, JString, required = false,
                                 default = nil)
  if valid_593731 != nil:
    section.add "X-Amz-Credential", valid_593731
  var valid_593732 = header.getOrDefault("X-Amz-Security-Token")
  valid_593732 = validateParameter(valid_593732, JString, required = false,
                                 default = nil)
  if valid_593732 != nil:
    section.add "X-Amz-Security-Token", valid_593732
  var valid_593733 = header.getOrDefault("X-Amz-Algorithm")
  valid_593733 = validateParameter(valid_593733, JString, required = false,
                                 default = nil)
  if valid_593733 != nil:
    section.add "X-Amz-Algorithm", valid_593733
  var valid_593734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593734 = validateParameter(valid_593734, JString, required = false,
                                 default = nil)
  if valid_593734 != nil:
    section.add "X-Amz-SignedHeaders", valid_593734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593735: Call_GetPutMetricData_593721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_593735.validator(path, query, header, formData, body)
  let scheme = call_593735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593735.url(scheme.get, call_593735.host, call_593735.base,
                         call_593735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593735, url, valid)

proc call*(call_593736: Call_GetPutMetricData_593721; Namespace: string;
          MetricData: JsonNode; Action: string = "PutMetricData";
          Version: string = "2010-08-01"): Recallable =
  ## getPutMetricData
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ##   Namespace: string (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  var query_593737 = newJObject()
  add(query_593737, "Namespace", newJString(Namespace))
  add(query_593737, "Action", newJString(Action))
  add(query_593737, "Version", newJString(Version))
  if MetricData != nil:
    query_593737.add "MetricData", MetricData
  result = call_593736.call(nil, query_593737, nil, nil, nil)

var getPutMetricData* = Call_GetPutMetricData_593721(name: "getPutMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_GetPutMetricData_593722,
    base: "/", url: url_GetPutMetricData_593723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetAlarmState_593775 = ref object of OpenApiRestCall_592364
proc url_PostSetAlarmState_593777(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetAlarmState_593776(path: JsonNode; query: JsonNode;
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
  var valid_593778 = query.getOrDefault("Action")
  valid_593778 = validateParameter(valid_593778, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_593778 != nil:
    section.add "Action", valid_593778
  var valid_593779 = query.getOrDefault("Version")
  valid_593779 = validateParameter(valid_593779, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593779 != nil:
    section.add "Version", valid_593779
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
  var valid_593780 = header.getOrDefault("X-Amz-Signature")
  valid_593780 = validateParameter(valid_593780, JString, required = false,
                                 default = nil)
  if valid_593780 != nil:
    section.add "X-Amz-Signature", valid_593780
  var valid_593781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593781 = validateParameter(valid_593781, JString, required = false,
                                 default = nil)
  if valid_593781 != nil:
    section.add "X-Amz-Content-Sha256", valid_593781
  var valid_593782 = header.getOrDefault("X-Amz-Date")
  valid_593782 = validateParameter(valid_593782, JString, required = false,
                                 default = nil)
  if valid_593782 != nil:
    section.add "X-Amz-Date", valid_593782
  var valid_593783 = header.getOrDefault("X-Amz-Credential")
  valid_593783 = validateParameter(valid_593783, JString, required = false,
                                 default = nil)
  if valid_593783 != nil:
    section.add "X-Amz-Credential", valid_593783
  var valid_593784 = header.getOrDefault("X-Amz-Security-Token")
  valid_593784 = validateParameter(valid_593784, JString, required = false,
                                 default = nil)
  if valid_593784 != nil:
    section.add "X-Amz-Security-Token", valid_593784
  var valid_593785 = header.getOrDefault("X-Amz-Algorithm")
  valid_593785 = validateParameter(valid_593785, JString, required = false,
                                 default = nil)
  if valid_593785 != nil:
    section.add "X-Amz-Algorithm", valid_593785
  var valid_593786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "X-Amz-SignedHeaders", valid_593786
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
  var valid_593787 = formData.getOrDefault("AlarmName")
  valid_593787 = validateParameter(valid_593787, JString, required = true,
                                 default = nil)
  if valid_593787 != nil:
    section.add "AlarmName", valid_593787
  var valid_593788 = formData.getOrDefault("StateValue")
  valid_593788 = validateParameter(valid_593788, JString, required = true,
                                 default = newJString("OK"))
  if valid_593788 != nil:
    section.add "StateValue", valid_593788
  var valid_593789 = formData.getOrDefault("StateReason")
  valid_593789 = validateParameter(valid_593789, JString, required = true,
                                 default = nil)
  if valid_593789 != nil:
    section.add "StateReason", valid_593789
  var valid_593790 = formData.getOrDefault("StateReasonData")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "StateReasonData", valid_593790
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593791: Call_PostSetAlarmState_593775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_593791.validator(path, query, header, formData, body)
  let scheme = call_593791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593791.url(scheme.get, call_593791.host, call_593791.base,
                         call_593791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593791, url, valid)

proc call*(call_593792: Call_PostSetAlarmState_593775; AlarmName: string;
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
  var query_593793 = newJObject()
  var formData_593794 = newJObject()
  add(formData_593794, "AlarmName", newJString(AlarmName))
  add(formData_593794, "StateValue", newJString(StateValue))
  add(formData_593794, "StateReason", newJString(StateReason))
  add(formData_593794, "StateReasonData", newJString(StateReasonData))
  add(query_593793, "Action", newJString(Action))
  add(query_593793, "Version", newJString(Version))
  result = call_593792.call(nil, query_593793, nil, formData_593794, nil)

var postSetAlarmState* = Call_PostSetAlarmState_593775(name: "postSetAlarmState",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_PostSetAlarmState_593776,
    base: "/", url: url_PostSetAlarmState_593777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetAlarmState_593756 = ref object of OpenApiRestCall_592364
proc url_GetSetAlarmState_593758(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetAlarmState_593757(path: JsonNode; query: JsonNode;
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
  var valid_593759 = query.getOrDefault("StateReason")
  valid_593759 = validateParameter(valid_593759, JString, required = true,
                                 default = nil)
  if valid_593759 != nil:
    section.add "StateReason", valid_593759
  var valid_593760 = query.getOrDefault("StateValue")
  valid_593760 = validateParameter(valid_593760, JString, required = true,
                                 default = newJString("OK"))
  if valid_593760 != nil:
    section.add "StateValue", valid_593760
  var valid_593761 = query.getOrDefault("Action")
  valid_593761 = validateParameter(valid_593761, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_593761 != nil:
    section.add "Action", valid_593761
  var valid_593762 = query.getOrDefault("AlarmName")
  valid_593762 = validateParameter(valid_593762, JString, required = true,
                                 default = nil)
  if valid_593762 != nil:
    section.add "AlarmName", valid_593762
  var valid_593763 = query.getOrDefault("StateReasonData")
  valid_593763 = validateParameter(valid_593763, JString, required = false,
                                 default = nil)
  if valid_593763 != nil:
    section.add "StateReasonData", valid_593763
  var valid_593764 = query.getOrDefault("Version")
  valid_593764 = validateParameter(valid_593764, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593764 != nil:
    section.add "Version", valid_593764
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
  var valid_593765 = header.getOrDefault("X-Amz-Signature")
  valid_593765 = validateParameter(valid_593765, JString, required = false,
                                 default = nil)
  if valid_593765 != nil:
    section.add "X-Amz-Signature", valid_593765
  var valid_593766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593766 = validateParameter(valid_593766, JString, required = false,
                                 default = nil)
  if valid_593766 != nil:
    section.add "X-Amz-Content-Sha256", valid_593766
  var valid_593767 = header.getOrDefault("X-Amz-Date")
  valid_593767 = validateParameter(valid_593767, JString, required = false,
                                 default = nil)
  if valid_593767 != nil:
    section.add "X-Amz-Date", valid_593767
  var valid_593768 = header.getOrDefault("X-Amz-Credential")
  valid_593768 = validateParameter(valid_593768, JString, required = false,
                                 default = nil)
  if valid_593768 != nil:
    section.add "X-Amz-Credential", valid_593768
  var valid_593769 = header.getOrDefault("X-Amz-Security-Token")
  valid_593769 = validateParameter(valid_593769, JString, required = false,
                                 default = nil)
  if valid_593769 != nil:
    section.add "X-Amz-Security-Token", valid_593769
  var valid_593770 = header.getOrDefault("X-Amz-Algorithm")
  valid_593770 = validateParameter(valid_593770, JString, required = false,
                                 default = nil)
  if valid_593770 != nil:
    section.add "X-Amz-Algorithm", valid_593770
  var valid_593771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-SignedHeaders", valid_593771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593772: Call_GetSetAlarmState_593756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_593772.validator(path, query, header, formData, body)
  let scheme = call_593772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593772.url(scheme.get, call_593772.host, call_593772.base,
                         call_593772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593772, url, valid)

proc call*(call_593773: Call_GetSetAlarmState_593756; StateReason: string;
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
  var query_593774 = newJObject()
  add(query_593774, "StateReason", newJString(StateReason))
  add(query_593774, "StateValue", newJString(StateValue))
  add(query_593774, "Action", newJString(Action))
  add(query_593774, "AlarmName", newJString(AlarmName))
  add(query_593774, "StateReasonData", newJString(StateReasonData))
  add(query_593774, "Version", newJString(Version))
  result = call_593773.call(nil, query_593774, nil, nil, nil)

var getSetAlarmState* = Call_GetSetAlarmState_593756(name: "getSetAlarmState",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_GetSetAlarmState_593757,
    base: "/", url: url_GetSetAlarmState_593758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_593812 = ref object of OpenApiRestCall_592364
proc url_PostTagResource_593814(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostTagResource_593813(path: JsonNode; query: JsonNode;
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
  var valid_593815 = query.getOrDefault("Action")
  valid_593815 = validateParameter(valid_593815, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_593815 != nil:
    section.add "Action", valid_593815
  var valid_593816 = query.getOrDefault("Version")
  valid_593816 = validateParameter(valid_593816, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593816 != nil:
    section.add "Version", valid_593816
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
  var valid_593817 = header.getOrDefault("X-Amz-Signature")
  valid_593817 = validateParameter(valid_593817, JString, required = false,
                                 default = nil)
  if valid_593817 != nil:
    section.add "X-Amz-Signature", valid_593817
  var valid_593818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593818 = validateParameter(valid_593818, JString, required = false,
                                 default = nil)
  if valid_593818 != nil:
    section.add "X-Amz-Content-Sha256", valid_593818
  var valid_593819 = header.getOrDefault("X-Amz-Date")
  valid_593819 = validateParameter(valid_593819, JString, required = false,
                                 default = nil)
  if valid_593819 != nil:
    section.add "X-Amz-Date", valid_593819
  var valid_593820 = header.getOrDefault("X-Amz-Credential")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "X-Amz-Credential", valid_593820
  var valid_593821 = header.getOrDefault("X-Amz-Security-Token")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "X-Amz-Security-Token", valid_593821
  var valid_593822 = header.getOrDefault("X-Amz-Algorithm")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "X-Amz-Algorithm", valid_593822
  var valid_593823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593823 = validateParameter(valid_593823, JString, required = false,
                                 default = nil)
  if valid_593823 != nil:
    section.add "X-Amz-SignedHeaders", valid_593823
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
  var valid_593824 = formData.getOrDefault("Tags")
  valid_593824 = validateParameter(valid_593824, JArray, required = true, default = nil)
  if valid_593824 != nil:
    section.add "Tags", valid_593824
  var valid_593825 = formData.getOrDefault("ResourceARN")
  valid_593825 = validateParameter(valid_593825, JString, required = true,
                                 default = nil)
  if valid_593825 != nil:
    section.add "ResourceARN", valid_593825
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593826: Call_PostTagResource_593812; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_593826.validator(path, query, header, formData, body)
  let scheme = call_593826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593826.url(scheme.get, call_593826.host, call_593826.base,
                         call_593826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593826, url, valid)

proc call*(call_593827: Call_PostTagResource_593812; Tags: JsonNode;
          ResourceARN: string; Action: string = "TagResource";
          Version: string = "2010-08-01"): Recallable =
  ## postTagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the resource.
  ##   Version: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you're adding tags to. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  var query_593828 = newJObject()
  var formData_593829 = newJObject()
  add(query_593828, "Action", newJString(Action))
  if Tags != nil:
    formData_593829.add "Tags", Tags
  add(query_593828, "Version", newJString(Version))
  add(formData_593829, "ResourceARN", newJString(ResourceARN))
  result = call_593827.call(nil, query_593828, nil, formData_593829, nil)

var postTagResource* = Call_PostTagResource_593812(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_593813,
    base: "/", url: url_PostTagResource_593814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_593795 = ref object of OpenApiRestCall_592364
proc url_GetTagResource_593797(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTagResource_593796(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the resource.
  ##   Action: JString (required)
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you're adding tags to. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_593798 = query.getOrDefault("Tags")
  valid_593798 = validateParameter(valid_593798, JArray, required = true, default = nil)
  if valid_593798 != nil:
    section.add "Tags", valid_593798
  var valid_593799 = query.getOrDefault("Action")
  valid_593799 = validateParameter(valid_593799, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_593799 != nil:
    section.add "Action", valid_593799
  var valid_593800 = query.getOrDefault("ResourceARN")
  valid_593800 = validateParameter(valid_593800, JString, required = true,
                                 default = nil)
  if valid_593800 != nil:
    section.add "ResourceARN", valid_593800
  var valid_593801 = query.getOrDefault("Version")
  valid_593801 = validateParameter(valid_593801, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593801 != nil:
    section.add "Version", valid_593801
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
  var valid_593802 = header.getOrDefault("X-Amz-Signature")
  valid_593802 = validateParameter(valid_593802, JString, required = false,
                                 default = nil)
  if valid_593802 != nil:
    section.add "X-Amz-Signature", valid_593802
  var valid_593803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593803 = validateParameter(valid_593803, JString, required = false,
                                 default = nil)
  if valid_593803 != nil:
    section.add "X-Amz-Content-Sha256", valid_593803
  var valid_593804 = header.getOrDefault("X-Amz-Date")
  valid_593804 = validateParameter(valid_593804, JString, required = false,
                                 default = nil)
  if valid_593804 != nil:
    section.add "X-Amz-Date", valid_593804
  var valid_593805 = header.getOrDefault("X-Amz-Credential")
  valid_593805 = validateParameter(valid_593805, JString, required = false,
                                 default = nil)
  if valid_593805 != nil:
    section.add "X-Amz-Credential", valid_593805
  var valid_593806 = header.getOrDefault("X-Amz-Security-Token")
  valid_593806 = validateParameter(valid_593806, JString, required = false,
                                 default = nil)
  if valid_593806 != nil:
    section.add "X-Amz-Security-Token", valid_593806
  var valid_593807 = header.getOrDefault("X-Amz-Algorithm")
  valid_593807 = validateParameter(valid_593807, JString, required = false,
                                 default = nil)
  if valid_593807 != nil:
    section.add "X-Amz-Algorithm", valid_593807
  var valid_593808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593808 = validateParameter(valid_593808, JString, required = false,
                                 default = nil)
  if valid_593808 != nil:
    section.add "X-Amz-SignedHeaders", valid_593808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593809: Call_GetTagResource_593795; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_593809.validator(path, query, header, formData, body)
  let scheme = call_593809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593809.url(scheme.get, call_593809.host, call_593809.base,
                         call_593809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593809, url, valid)

proc call*(call_593810: Call_GetTagResource_593795; Tags: JsonNode;
          ResourceARN: string; Action: string = "TagResource";
          Version: string = "2010-08-01"): Recallable =
  ## getTagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. In CloudWatch, alarms can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ##   Tags: JArray (required)
  ##       : The list of key-value pairs to associate with the resource.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you're adding tags to. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_593811 = newJObject()
  if Tags != nil:
    query_593811.add "Tags", Tags
  add(query_593811, "Action", newJString(Action))
  add(query_593811, "ResourceARN", newJString(ResourceARN))
  add(query_593811, "Version", newJString(Version))
  result = call_593810.call(nil, query_593811, nil, nil, nil)

var getTagResource* = Call_GetTagResource_593795(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_593796,
    base: "/", url: url_GetTagResource_593797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_593847 = ref object of OpenApiRestCall_592364
proc url_PostUntagResource_593849(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUntagResource_593848(path: JsonNode; query: JsonNode;
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
  var valid_593850 = query.getOrDefault("Action")
  valid_593850 = validateParameter(valid_593850, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_593850 != nil:
    section.add "Action", valid_593850
  var valid_593851 = query.getOrDefault("Version")
  valid_593851 = validateParameter(valid_593851, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593851 != nil:
    section.add "Version", valid_593851
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
  var valid_593852 = header.getOrDefault("X-Amz-Signature")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-Signature", valid_593852
  var valid_593853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-Content-Sha256", valid_593853
  var valid_593854 = header.getOrDefault("X-Amz-Date")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-Date", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Credential")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Credential", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Security-Token")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Security-Token", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Algorithm")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Algorithm", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-SignedHeaders", valid_593858
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
  var valid_593859 = formData.getOrDefault("TagKeys")
  valid_593859 = validateParameter(valid_593859, JArray, required = true, default = nil)
  if valid_593859 != nil:
    section.add "TagKeys", valid_593859
  var valid_593860 = formData.getOrDefault("ResourceARN")
  valid_593860 = validateParameter(valid_593860, JString, required = true,
                                 default = nil)
  if valid_593860 != nil:
    section.add "ResourceARN", valid_593860
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593861: Call_PostUntagResource_593847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_593861.validator(path, query, header, formData, body)
  let scheme = call_593861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593861.url(scheme.get, call_593861.host, call_593861.base,
                         call_593861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593861, url, valid)

proc call*(call_593862: Call_PostUntagResource_593847; TagKeys: JsonNode;
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
  var query_593863 = newJObject()
  var formData_593864 = newJObject()
  if TagKeys != nil:
    formData_593864.add "TagKeys", TagKeys
  add(query_593863, "Action", newJString(Action))
  add(query_593863, "Version", newJString(Version))
  add(formData_593864, "ResourceARN", newJString(ResourceARN))
  result = call_593862.call(nil, query_593863, nil, formData_593864, nil)

var postUntagResource* = Call_PostUntagResource_593847(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_593848,
    base: "/", url: url_PostUntagResource_593849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_593830 = ref object of OpenApiRestCall_592364
proc url_GetUntagResource_593832(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUntagResource_593831(path: JsonNode; query: JsonNode;
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
  var valid_593833 = query.getOrDefault("TagKeys")
  valid_593833 = validateParameter(valid_593833, JArray, required = true, default = nil)
  if valid_593833 != nil:
    section.add "TagKeys", valid_593833
  var valid_593834 = query.getOrDefault("Action")
  valid_593834 = validateParameter(valid_593834, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_593834 != nil:
    section.add "Action", valid_593834
  var valid_593835 = query.getOrDefault("ResourceARN")
  valid_593835 = validateParameter(valid_593835, JString, required = true,
                                 default = nil)
  if valid_593835 != nil:
    section.add "ResourceARN", valid_593835
  var valid_593836 = query.getOrDefault("Version")
  valid_593836 = validateParameter(valid_593836, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_593836 != nil:
    section.add "Version", valid_593836
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
  var valid_593837 = header.getOrDefault("X-Amz-Signature")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Signature", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-Content-Sha256", valid_593838
  var valid_593839 = header.getOrDefault("X-Amz-Date")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-Date", valid_593839
  var valid_593840 = header.getOrDefault("X-Amz-Credential")
  valid_593840 = validateParameter(valid_593840, JString, required = false,
                                 default = nil)
  if valid_593840 != nil:
    section.add "X-Amz-Credential", valid_593840
  var valid_593841 = header.getOrDefault("X-Amz-Security-Token")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-Security-Token", valid_593841
  var valid_593842 = header.getOrDefault("X-Amz-Algorithm")
  valid_593842 = validateParameter(valid_593842, JString, required = false,
                                 default = nil)
  if valid_593842 != nil:
    section.add "X-Amz-Algorithm", valid_593842
  var valid_593843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "X-Amz-SignedHeaders", valid_593843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593844: Call_GetUntagResource_593830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_593844.validator(path, query, header, formData, body)
  let scheme = call_593844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593844.url(scheme.get, call_593844.host, call_593844.base,
                         call_593844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593844, url, valid)

proc call*(call_593845: Call_GetUntagResource_593830; TagKeys: JsonNode;
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
  var query_593846 = newJObject()
  if TagKeys != nil:
    query_593846.add "TagKeys", TagKeys
  add(query_593846, "Action", newJString(Action))
  add(query_593846, "ResourceARN", newJString(ResourceARN))
  add(query_593846, "Version", newJString(Version))
  result = call_593845.call(nil, query_593846, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_593830(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_593831,
    base: "/", url: url_GetUntagResource_593832,
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
