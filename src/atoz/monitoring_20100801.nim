
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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
  Call_PostDeleteAlarms_590974 = ref object of OpenApiRestCall_590364
proc url_PostDeleteAlarms_590976(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAlarms_590975(path: JsonNode; query: JsonNode;
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
  var valid_590977 = query.getOrDefault("Action")
  valid_590977 = validateParameter(valid_590977, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_590977 != nil:
    section.add "Action", valid_590977
  var valid_590978 = query.getOrDefault("Version")
  valid_590978 = validateParameter(valid_590978, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_590978 != nil:
    section.add "Version", valid_590978
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
  var valid_590979 = header.getOrDefault("X-Amz-Signature")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Signature", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Content-Sha256", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Date")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Date", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-Credential")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-Credential", valid_590982
  var valid_590983 = header.getOrDefault("X-Amz-Security-Token")
  valid_590983 = validateParameter(valid_590983, JString, required = false,
                                 default = nil)
  if valid_590983 != nil:
    section.add "X-Amz-Security-Token", valid_590983
  var valid_590984 = header.getOrDefault("X-Amz-Algorithm")
  valid_590984 = validateParameter(valid_590984, JString, required = false,
                                 default = nil)
  if valid_590984 != nil:
    section.add "X-Amz-Algorithm", valid_590984
  var valid_590985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590985 = validateParameter(valid_590985, JString, required = false,
                                 default = nil)
  if valid_590985 != nil:
    section.add "X-Amz-SignedHeaders", valid_590985
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_590986 = formData.getOrDefault("AlarmNames")
  valid_590986 = validateParameter(valid_590986, JArray, required = true, default = nil)
  if valid_590986 != nil:
    section.add "AlarmNames", valid_590986
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590987: Call_PostDeleteAlarms_590974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_590987.validator(path, query, header, formData, body)
  let scheme = call_590987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590987.url(scheme.get, call_590987.host, call_590987.base,
                         call_590987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590987, url, valid)

proc call*(call_590988: Call_PostDeleteAlarms_590974; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  var query_590989 = newJObject()
  var formData_590990 = newJObject()
  add(query_590989, "Action", newJString(Action))
  add(query_590989, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_590990.add "AlarmNames", AlarmNames
  result = call_590988.call(nil, query_590989, nil, formData_590990, nil)

var postDeleteAlarms* = Call_PostDeleteAlarms_590974(name: "postDeleteAlarms",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_PostDeleteAlarms_590975,
    base: "/", url: url_PostDeleteAlarms_590976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAlarms_590703 = ref object of OpenApiRestCall_590364
proc url_GetDeleteAlarms_590705(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAlarms_590704(path: JsonNode; query: JsonNode;
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
  var valid_590817 = query.getOrDefault("AlarmNames")
  valid_590817 = validateParameter(valid_590817, JArray, required = true, default = nil)
  if valid_590817 != nil:
    section.add "AlarmNames", valid_590817
  var valid_590831 = query.getOrDefault("Action")
  valid_590831 = validateParameter(valid_590831, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_590831 != nil:
    section.add "Action", valid_590831
  var valid_590832 = query.getOrDefault("Version")
  valid_590832 = validateParameter(valid_590832, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_590832 != nil:
    section.add "Version", valid_590832
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
  var valid_590833 = header.getOrDefault("X-Amz-Signature")
  valid_590833 = validateParameter(valid_590833, JString, required = false,
                                 default = nil)
  if valid_590833 != nil:
    section.add "X-Amz-Signature", valid_590833
  var valid_590834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590834 = validateParameter(valid_590834, JString, required = false,
                                 default = nil)
  if valid_590834 != nil:
    section.add "X-Amz-Content-Sha256", valid_590834
  var valid_590835 = header.getOrDefault("X-Amz-Date")
  valid_590835 = validateParameter(valid_590835, JString, required = false,
                                 default = nil)
  if valid_590835 != nil:
    section.add "X-Amz-Date", valid_590835
  var valid_590836 = header.getOrDefault("X-Amz-Credential")
  valid_590836 = validateParameter(valid_590836, JString, required = false,
                                 default = nil)
  if valid_590836 != nil:
    section.add "X-Amz-Credential", valid_590836
  var valid_590837 = header.getOrDefault("X-Amz-Security-Token")
  valid_590837 = validateParameter(valid_590837, JString, required = false,
                                 default = nil)
  if valid_590837 != nil:
    section.add "X-Amz-Security-Token", valid_590837
  var valid_590838 = header.getOrDefault("X-Amz-Algorithm")
  valid_590838 = validateParameter(valid_590838, JString, required = false,
                                 default = nil)
  if valid_590838 != nil:
    section.add "X-Amz-Algorithm", valid_590838
  var valid_590839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590839 = validateParameter(valid_590839, JString, required = false,
                                 default = nil)
  if valid_590839 != nil:
    section.add "X-Amz-SignedHeaders", valid_590839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590862: Call_GetDeleteAlarms_590703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_590862.validator(path, query, header, formData, body)
  let scheme = call_590862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590862.url(scheme.get, call_590862.host, call_590862.base,
                         call_590862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590862, url, valid)

proc call*(call_590933: Call_GetDeleteAlarms_590703; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_590934 = newJObject()
  if AlarmNames != nil:
    query_590934.add "AlarmNames", AlarmNames
  add(query_590934, "Action", newJString(Action))
  add(query_590934, "Version", newJString(Version))
  result = call_590933.call(nil, query_590934, nil, nil, nil)

var getDeleteAlarms* = Call_GetDeleteAlarms_590703(name: "getDeleteAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_GetDeleteAlarms_590704,
    base: "/", url: url_GetDeleteAlarms_590705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnomalyDetector_591010 = ref object of OpenApiRestCall_590364
proc url_PostDeleteAnomalyDetector_591012(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAnomalyDetector_591011(path: JsonNode; query: JsonNode;
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
  var valid_591013 = query.getOrDefault("Action")
  valid_591013 = validateParameter(valid_591013, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_591013 != nil:
    section.add "Action", valid_591013
  var valid_591014 = query.getOrDefault("Version")
  valid_591014 = validateParameter(valid_591014, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591014 != nil:
    section.add "Version", valid_591014
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
  var valid_591015 = header.getOrDefault("X-Amz-Signature")
  valid_591015 = validateParameter(valid_591015, JString, required = false,
                                 default = nil)
  if valid_591015 != nil:
    section.add "X-Amz-Signature", valid_591015
  var valid_591016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591016 = validateParameter(valid_591016, JString, required = false,
                                 default = nil)
  if valid_591016 != nil:
    section.add "X-Amz-Content-Sha256", valid_591016
  var valid_591017 = header.getOrDefault("X-Amz-Date")
  valid_591017 = validateParameter(valid_591017, JString, required = false,
                                 default = nil)
  if valid_591017 != nil:
    section.add "X-Amz-Date", valid_591017
  var valid_591018 = header.getOrDefault("X-Amz-Credential")
  valid_591018 = validateParameter(valid_591018, JString, required = false,
                                 default = nil)
  if valid_591018 != nil:
    section.add "X-Amz-Credential", valid_591018
  var valid_591019 = header.getOrDefault("X-Amz-Security-Token")
  valid_591019 = validateParameter(valid_591019, JString, required = false,
                                 default = nil)
  if valid_591019 != nil:
    section.add "X-Amz-Security-Token", valid_591019
  var valid_591020 = header.getOrDefault("X-Amz-Algorithm")
  valid_591020 = validateParameter(valid_591020, JString, required = false,
                                 default = nil)
  if valid_591020 != nil:
    section.add "X-Amz-Algorithm", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-SignedHeaders", valid_591021
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
  var valid_591022 = formData.getOrDefault("Stat")
  valid_591022 = validateParameter(valid_591022, JString, required = true,
                                 default = nil)
  if valid_591022 != nil:
    section.add "Stat", valid_591022
  var valid_591023 = formData.getOrDefault("MetricName")
  valid_591023 = validateParameter(valid_591023, JString, required = true,
                                 default = nil)
  if valid_591023 != nil:
    section.add "MetricName", valid_591023
  var valid_591024 = formData.getOrDefault("Dimensions")
  valid_591024 = validateParameter(valid_591024, JArray, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "Dimensions", valid_591024
  var valid_591025 = formData.getOrDefault("Namespace")
  valid_591025 = validateParameter(valid_591025, JString, required = true,
                                 default = nil)
  if valid_591025 != nil:
    section.add "Namespace", valid_591025
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591026: Call_PostDeleteAnomalyDetector_591010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_591026.validator(path, query, header, formData, body)
  let scheme = call_591026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591026.url(scheme.get, call_591026.host, call_591026.base,
                         call_591026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591026, url, valid)

proc call*(call_591027: Call_PostDeleteAnomalyDetector_591010; Stat: string;
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
  var query_591028 = newJObject()
  var formData_591029 = newJObject()
  add(formData_591029, "Stat", newJString(Stat))
  add(formData_591029, "MetricName", newJString(MetricName))
  add(query_591028, "Action", newJString(Action))
  if Dimensions != nil:
    formData_591029.add "Dimensions", Dimensions
  add(formData_591029, "Namespace", newJString(Namespace))
  add(query_591028, "Version", newJString(Version))
  result = call_591027.call(nil, query_591028, nil, formData_591029, nil)

var postDeleteAnomalyDetector* = Call_PostDeleteAnomalyDetector_591010(
    name: "postDeleteAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_PostDeleteAnomalyDetector_591011, base: "/",
    url: url_PostDeleteAnomalyDetector_591012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnomalyDetector_590991 = ref object of OpenApiRestCall_590364
proc url_GetDeleteAnomalyDetector_590993(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAnomalyDetector_590992(path: JsonNode; query: JsonNode;
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
  var valid_590994 = query.getOrDefault("Namespace")
  valid_590994 = validateParameter(valid_590994, JString, required = true,
                                 default = nil)
  if valid_590994 != nil:
    section.add "Namespace", valid_590994
  var valid_590995 = query.getOrDefault("Dimensions")
  valid_590995 = validateParameter(valid_590995, JArray, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "Dimensions", valid_590995
  var valid_590996 = query.getOrDefault("Action")
  valid_590996 = validateParameter(valid_590996, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_590996 != nil:
    section.add "Action", valid_590996
  var valid_590997 = query.getOrDefault("Version")
  valid_590997 = validateParameter(valid_590997, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_590997 != nil:
    section.add "Version", valid_590997
  var valid_590998 = query.getOrDefault("MetricName")
  valid_590998 = validateParameter(valid_590998, JString, required = true,
                                 default = nil)
  if valid_590998 != nil:
    section.add "MetricName", valid_590998
  var valid_590999 = query.getOrDefault("Stat")
  valid_590999 = validateParameter(valid_590999, JString, required = true,
                                 default = nil)
  if valid_590999 != nil:
    section.add "Stat", valid_590999
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
  var valid_591000 = header.getOrDefault("X-Amz-Signature")
  valid_591000 = validateParameter(valid_591000, JString, required = false,
                                 default = nil)
  if valid_591000 != nil:
    section.add "X-Amz-Signature", valid_591000
  var valid_591001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591001 = validateParameter(valid_591001, JString, required = false,
                                 default = nil)
  if valid_591001 != nil:
    section.add "X-Amz-Content-Sha256", valid_591001
  var valid_591002 = header.getOrDefault("X-Amz-Date")
  valid_591002 = validateParameter(valid_591002, JString, required = false,
                                 default = nil)
  if valid_591002 != nil:
    section.add "X-Amz-Date", valid_591002
  var valid_591003 = header.getOrDefault("X-Amz-Credential")
  valid_591003 = validateParameter(valid_591003, JString, required = false,
                                 default = nil)
  if valid_591003 != nil:
    section.add "X-Amz-Credential", valid_591003
  var valid_591004 = header.getOrDefault("X-Amz-Security-Token")
  valid_591004 = validateParameter(valid_591004, JString, required = false,
                                 default = nil)
  if valid_591004 != nil:
    section.add "X-Amz-Security-Token", valid_591004
  var valid_591005 = header.getOrDefault("X-Amz-Algorithm")
  valid_591005 = validateParameter(valid_591005, JString, required = false,
                                 default = nil)
  if valid_591005 != nil:
    section.add "X-Amz-Algorithm", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-SignedHeaders", valid_591006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591007: Call_GetDeleteAnomalyDetector_590991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_591007.validator(path, query, header, formData, body)
  let scheme = call_591007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591007.url(scheme.get, call_591007.host, call_591007.base,
                         call_591007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591007, url, valid)

proc call*(call_591008: Call_GetDeleteAnomalyDetector_590991; Namespace: string;
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
  var query_591009 = newJObject()
  add(query_591009, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_591009.add "Dimensions", Dimensions
  add(query_591009, "Action", newJString(Action))
  add(query_591009, "Version", newJString(Version))
  add(query_591009, "MetricName", newJString(MetricName))
  add(query_591009, "Stat", newJString(Stat))
  result = call_591008.call(nil, query_591009, nil, nil, nil)

var getDeleteAnomalyDetector* = Call_GetDeleteAnomalyDetector_590991(
    name: "getDeleteAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_GetDeleteAnomalyDetector_590992, base: "/",
    url: url_GetDeleteAnomalyDetector_590993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDashboards_591046 = ref object of OpenApiRestCall_590364
proc url_PostDeleteDashboards_591048(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDashboards_591047(path: JsonNode; query: JsonNode;
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
  var valid_591049 = query.getOrDefault("Action")
  valid_591049 = validateParameter(valid_591049, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_591049 != nil:
    section.add "Action", valid_591049
  var valid_591050 = query.getOrDefault("Version")
  valid_591050 = validateParameter(valid_591050, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591050 != nil:
    section.add "Version", valid_591050
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
  var valid_591051 = header.getOrDefault("X-Amz-Signature")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-Signature", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Content-Sha256", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Date")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Date", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Credential")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Credential", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Security-Token")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Security-Token", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Algorithm")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Algorithm", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-SignedHeaders", valid_591057
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardNames` field"
  var valid_591058 = formData.getOrDefault("DashboardNames")
  valid_591058 = validateParameter(valid_591058, JArray, required = true, default = nil)
  if valid_591058 != nil:
    section.add "DashboardNames", valid_591058
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591059: Call_PostDeleteDashboards_591046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_591059.validator(path, query, header, formData, body)
  let scheme = call_591059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591059.url(scheme.get, call_591059.host, call_591059.base,
                         call_591059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591059, url, valid)

proc call*(call_591060: Call_PostDeleteDashboards_591046; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_591061 = newJObject()
  var formData_591062 = newJObject()
  if DashboardNames != nil:
    formData_591062.add "DashboardNames", DashboardNames
  add(query_591061, "Action", newJString(Action))
  add(query_591061, "Version", newJString(Version))
  result = call_591060.call(nil, query_591061, nil, formData_591062, nil)

var postDeleteDashboards* = Call_PostDeleteDashboards_591046(
    name: "postDeleteDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_PostDeleteDashboards_591047, base: "/",
    url: url_PostDeleteDashboards_591048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDashboards_591030 = ref object of OpenApiRestCall_590364
proc url_GetDeleteDashboards_591032(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDashboards_591031(path: JsonNode; query: JsonNode;
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
  var valid_591033 = query.getOrDefault("DashboardNames")
  valid_591033 = validateParameter(valid_591033, JArray, required = true, default = nil)
  if valid_591033 != nil:
    section.add "DashboardNames", valid_591033
  var valid_591034 = query.getOrDefault("Action")
  valid_591034 = validateParameter(valid_591034, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_591034 != nil:
    section.add "Action", valid_591034
  var valid_591035 = query.getOrDefault("Version")
  valid_591035 = validateParameter(valid_591035, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591035 != nil:
    section.add "Version", valid_591035
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
  var valid_591036 = header.getOrDefault("X-Amz-Signature")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Signature", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Content-Sha256", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Date")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Date", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Credential")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Credential", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Security-Token")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Security-Token", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Algorithm")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Algorithm", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-SignedHeaders", valid_591042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591043: Call_GetDeleteDashboards_591030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_591043.validator(path, query, header, formData, body)
  let scheme = call_591043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591043.url(scheme.get, call_591043.host, call_591043.base,
                         call_591043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591043, url, valid)

proc call*(call_591044: Call_GetDeleteDashboards_591030; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_591045 = newJObject()
  if DashboardNames != nil:
    query_591045.add "DashboardNames", DashboardNames
  add(query_591045, "Action", newJString(Action))
  add(query_591045, "Version", newJString(Version))
  result = call_591044.call(nil, query_591045, nil, nil, nil)

var getDeleteDashboards* = Call_GetDeleteDashboards_591030(
    name: "getDeleteDashboards", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_GetDeleteDashboards_591031, base: "/",
    url: url_GetDeleteDashboards_591032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmHistory_591084 = ref object of OpenApiRestCall_590364
proc url_PostDescribeAlarmHistory_591086(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAlarmHistory_591085(path: JsonNode; query: JsonNode;
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
  var valid_591087 = query.getOrDefault("Action")
  valid_591087 = validateParameter(valid_591087, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_591087 != nil:
    section.add "Action", valid_591087
  var valid_591088 = query.getOrDefault("Version")
  valid_591088 = validateParameter(valid_591088, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591088 != nil:
    section.add "Version", valid_591088
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
  var valid_591089 = header.getOrDefault("X-Amz-Signature")
  valid_591089 = validateParameter(valid_591089, JString, required = false,
                                 default = nil)
  if valid_591089 != nil:
    section.add "X-Amz-Signature", valid_591089
  var valid_591090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591090 = validateParameter(valid_591090, JString, required = false,
                                 default = nil)
  if valid_591090 != nil:
    section.add "X-Amz-Content-Sha256", valid_591090
  var valid_591091 = header.getOrDefault("X-Amz-Date")
  valid_591091 = validateParameter(valid_591091, JString, required = false,
                                 default = nil)
  if valid_591091 != nil:
    section.add "X-Amz-Date", valid_591091
  var valid_591092 = header.getOrDefault("X-Amz-Credential")
  valid_591092 = validateParameter(valid_591092, JString, required = false,
                                 default = nil)
  if valid_591092 != nil:
    section.add "X-Amz-Credential", valid_591092
  var valid_591093 = header.getOrDefault("X-Amz-Security-Token")
  valid_591093 = validateParameter(valid_591093, JString, required = false,
                                 default = nil)
  if valid_591093 != nil:
    section.add "X-Amz-Security-Token", valid_591093
  var valid_591094 = header.getOrDefault("X-Amz-Algorithm")
  valid_591094 = validateParameter(valid_591094, JString, required = false,
                                 default = nil)
  if valid_591094 != nil:
    section.add "X-Amz-Algorithm", valid_591094
  var valid_591095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591095 = validateParameter(valid_591095, JString, required = false,
                                 default = nil)
  if valid_591095 != nil:
    section.add "X-Amz-SignedHeaders", valid_591095
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
  var valid_591096 = formData.getOrDefault("AlarmName")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "AlarmName", valid_591096
  var valid_591097 = formData.getOrDefault("HistoryItemType")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_591097 != nil:
    section.add "HistoryItemType", valid_591097
  var valid_591098 = formData.getOrDefault("MaxRecords")
  valid_591098 = validateParameter(valid_591098, JInt, required = false, default = nil)
  if valid_591098 != nil:
    section.add "MaxRecords", valid_591098
  var valid_591099 = formData.getOrDefault("EndDate")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "EndDate", valid_591099
  var valid_591100 = formData.getOrDefault("NextToken")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "NextToken", valid_591100
  var valid_591101 = formData.getOrDefault("StartDate")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "StartDate", valid_591101
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591102: Call_PostDescribeAlarmHistory_591084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_591102.validator(path, query, header, formData, body)
  let scheme = call_591102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591102.url(scheme.get, call_591102.host, call_591102.base,
                         call_591102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591102, url, valid)

proc call*(call_591103: Call_PostDescribeAlarmHistory_591084;
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
  var query_591104 = newJObject()
  var formData_591105 = newJObject()
  add(formData_591105, "AlarmName", newJString(AlarmName))
  add(formData_591105, "HistoryItemType", newJString(HistoryItemType))
  add(formData_591105, "MaxRecords", newJInt(MaxRecords))
  add(formData_591105, "EndDate", newJString(EndDate))
  add(formData_591105, "NextToken", newJString(NextToken))
  add(formData_591105, "StartDate", newJString(StartDate))
  add(query_591104, "Action", newJString(Action))
  add(query_591104, "Version", newJString(Version))
  result = call_591103.call(nil, query_591104, nil, formData_591105, nil)

var postDescribeAlarmHistory* = Call_PostDescribeAlarmHistory_591084(
    name: "postDescribeAlarmHistory", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_PostDescribeAlarmHistory_591085, base: "/",
    url: url_PostDescribeAlarmHistory_591086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmHistory_591063 = ref object of OpenApiRestCall_590364
proc url_GetDescribeAlarmHistory_591065(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAlarmHistory_591064(path: JsonNode; query: JsonNode;
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
  var valid_591066 = query.getOrDefault("EndDate")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "EndDate", valid_591066
  var valid_591067 = query.getOrDefault("NextToken")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "NextToken", valid_591067
  var valid_591068 = query.getOrDefault("HistoryItemType")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_591068 != nil:
    section.add "HistoryItemType", valid_591068
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_591069 = query.getOrDefault("Action")
  valid_591069 = validateParameter(valid_591069, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_591069 != nil:
    section.add "Action", valid_591069
  var valid_591070 = query.getOrDefault("AlarmName")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "AlarmName", valid_591070
  var valid_591071 = query.getOrDefault("StartDate")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "StartDate", valid_591071
  var valid_591072 = query.getOrDefault("Version")
  valid_591072 = validateParameter(valid_591072, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591072 != nil:
    section.add "Version", valid_591072
  var valid_591073 = query.getOrDefault("MaxRecords")
  valid_591073 = validateParameter(valid_591073, JInt, required = false, default = nil)
  if valid_591073 != nil:
    section.add "MaxRecords", valid_591073
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
  var valid_591074 = header.getOrDefault("X-Amz-Signature")
  valid_591074 = validateParameter(valid_591074, JString, required = false,
                                 default = nil)
  if valid_591074 != nil:
    section.add "X-Amz-Signature", valid_591074
  var valid_591075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591075 = validateParameter(valid_591075, JString, required = false,
                                 default = nil)
  if valid_591075 != nil:
    section.add "X-Amz-Content-Sha256", valid_591075
  var valid_591076 = header.getOrDefault("X-Amz-Date")
  valid_591076 = validateParameter(valid_591076, JString, required = false,
                                 default = nil)
  if valid_591076 != nil:
    section.add "X-Amz-Date", valid_591076
  var valid_591077 = header.getOrDefault("X-Amz-Credential")
  valid_591077 = validateParameter(valid_591077, JString, required = false,
                                 default = nil)
  if valid_591077 != nil:
    section.add "X-Amz-Credential", valid_591077
  var valid_591078 = header.getOrDefault("X-Amz-Security-Token")
  valid_591078 = validateParameter(valid_591078, JString, required = false,
                                 default = nil)
  if valid_591078 != nil:
    section.add "X-Amz-Security-Token", valid_591078
  var valid_591079 = header.getOrDefault("X-Amz-Algorithm")
  valid_591079 = validateParameter(valid_591079, JString, required = false,
                                 default = nil)
  if valid_591079 != nil:
    section.add "X-Amz-Algorithm", valid_591079
  var valid_591080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591080 = validateParameter(valid_591080, JString, required = false,
                                 default = nil)
  if valid_591080 != nil:
    section.add "X-Amz-SignedHeaders", valid_591080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591081: Call_GetDescribeAlarmHistory_591063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_591081.validator(path, query, header, formData, body)
  let scheme = call_591081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591081.url(scheme.get, call_591081.host, call_591081.base,
                         call_591081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591081, url, valid)

proc call*(call_591082: Call_GetDescribeAlarmHistory_591063; EndDate: string = "";
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
  var query_591083 = newJObject()
  add(query_591083, "EndDate", newJString(EndDate))
  add(query_591083, "NextToken", newJString(NextToken))
  add(query_591083, "HistoryItemType", newJString(HistoryItemType))
  add(query_591083, "Action", newJString(Action))
  add(query_591083, "AlarmName", newJString(AlarmName))
  add(query_591083, "StartDate", newJString(StartDate))
  add(query_591083, "Version", newJString(Version))
  add(query_591083, "MaxRecords", newJInt(MaxRecords))
  result = call_591082.call(nil, query_591083, nil, nil, nil)

var getDescribeAlarmHistory* = Call_GetDescribeAlarmHistory_591063(
    name: "getDescribeAlarmHistory", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_GetDescribeAlarmHistory_591064, base: "/",
    url: url_GetDescribeAlarmHistory_591065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarms_591127 = ref object of OpenApiRestCall_590364
proc url_PostDescribeAlarms_591129(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAlarms_591128(path: JsonNode; query: JsonNode;
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
  var valid_591130 = query.getOrDefault("Action")
  valid_591130 = validateParameter(valid_591130, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_591130 != nil:
    section.add "Action", valid_591130
  var valid_591131 = query.getOrDefault("Version")
  valid_591131 = validateParameter(valid_591131, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591131 != nil:
    section.add "Version", valid_591131
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
  var valid_591132 = header.getOrDefault("X-Amz-Signature")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-Signature", valid_591132
  var valid_591133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591133 = validateParameter(valid_591133, JString, required = false,
                                 default = nil)
  if valid_591133 != nil:
    section.add "X-Amz-Content-Sha256", valid_591133
  var valid_591134 = header.getOrDefault("X-Amz-Date")
  valid_591134 = validateParameter(valid_591134, JString, required = false,
                                 default = nil)
  if valid_591134 != nil:
    section.add "X-Amz-Date", valid_591134
  var valid_591135 = header.getOrDefault("X-Amz-Credential")
  valid_591135 = validateParameter(valid_591135, JString, required = false,
                                 default = nil)
  if valid_591135 != nil:
    section.add "X-Amz-Credential", valid_591135
  var valid_591136 = header.getOrDefault("X-Amz-Security-Token")
  valid_591136 = validateParameter(valid_591136, JString, required = false,
                                 default = nil)
  if valid_591136 != nil:
    section.add "X-Amz-Security-Token", valid_591136
  var valid_591137 = header.getOrDefault("X-Amz-Algorithm")
  valid_591137 = validateParameter(valid_591137, JString, required = false,
                                 default = nil)
  if valid_591137 != nil:
    section.add "X-Amz-Algorithm", valid_591137
  var valid_591138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591138 = validateParameter(valid_591138, JString, required = false,
                                 default = nil)
  if valid_591138 != nil:
    section.add "X-Amz-SignedHeaders", valid_591138
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
  var valid_591139 = formData.getOrDefault("AlarmNamePrefix")
  valid_591139 = validateParameter(valid_591139, JString, required = false,
                                 default = nil)
  if valid_591139 != nil:
    section.add "AlarmNamePrefix", valid_591139
  var valid_591140 = formData.getOrDefault("StateValue")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = newJString("OK"))
  if valid_591140 != nil:
    section.add "StateValue", valid_591140
  var valid_591141 = formData.getOrDefault("NextToken")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "NextToken", valid_591141
  var valid_591142 = formData.getOrDefault("MaxRecords")
  valid_591142 = validateParameter(valid_591142, JInt, required = false, default = nil)
  if valid_591142 != nil:
    section.add "MaxRecords", valid_591142
  var valid_591143 = formData.getOrDefault("ActionPrefix")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "ActionPrefix", valid_591143
  var valid_591144 = formData.getOrDefault("AlarmNames")
  valid_591144 = validateParameter(valid_591144, JArray, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "AlarmNames", valid_591144
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591145: Call_PostDescribeAlarms_591127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_591145.validator(path, query, header, formData, body)
  let scheme = call_591145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591145.url(scheme.get, call_591145.host, call_591145.base,
                         call_591145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591145, url, valid)

proc call*(call_591146: Call_PostDescribeAlarms_591127;
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
  var query_591147 = newJObject()
  var formData_591148 = newJObject()
  add(formData_591148, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(formData_591148, "StateValue", newJString(StateValue))
  add(formData_591148, "NextToken", newJString(NextToken))
  add(formData_591148, "MaxRecords", newJInt(MaxRecords))
  add(query_591147, "Action", newJString(Action))
  add(formData_591148, "ActionPrefix", newJString(ActionPrefix))
  add(query_591147, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_591148.add "AlarmNames", AlarmNames
  result = call_591146.call(nil, query_591147, nil, formData_591148, nil)

var postDescribeAlarms* = Call_PostDescribeAlarms_591127(
    name: "postDescribeAlarms", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarms",
    validator: validate_PostDescribeAlarms_591128, base: "/",
    url: url_PostDescribeAlarms_591129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarms_591106 = ref object of OpenApiRestCall_590364
proc url_GetDescribeAlarms_591108(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAlarms_591107(path: JsonNode; query: JsonNode;
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
  var valid_591109 = query.getOrDefault("StateValue")
  valid_591109 = validateParameter(valid_591109, JString, required = false,
                                 default = newJString("OK"))
  if valid_591109 != nil:
    section.add "StateValue", valid_591109
  var valid_591110 = query.getOrDefault("ActionPrefix")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "ActionPrefix", valid_591110
  var valid_591111 = query.getOrDefault("NextToken")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "NextToken", valid_591111
  var valid_591112 = query.getOrDefault("AlarmNamePrefix")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "AlarmNamePrefix", valid_591112
  var valid_591113 = query.getOrDefault("AlarmNames")
  valid_591113 = validateParameter(valid_591113, JArray, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "AlarmNames", valid_591113
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_591114 = query.getOrDefault("Action")
  valid_591114 = validateParameter(valid_591114, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_591114 != nil:
    section.add "Action", valid_591114
  var valid_591115 = query.getOrDefault("Version")
  valid_591115 = validateParameter(valid_591115, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591115 != nil:
    section.add "Version", valid_591115
  var valid_591116 = query.getOrDefault("MaxRecords")
  valid_591116 = validateParameter(valid_591116, JInt, required = false, default = nil)
  if valid_591116 != nil:
    section.add "MaxRecords", valid_591116
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
  var valid_591117 = header.getOrDefault("X-Amz-Signature")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-Signature", valid_591117
  var valid_591118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591118 = validateParameter(valid_591118, JString, required = false,
                                 default = nil)
  if valid_591118 != nil:
    section.add "X-Amz-Content-Sha256", valid_591118
  var valid_591119 = header.getOrDefault("X-Amz-Date")
  valid_591119 = validateParameter(valid_591119, JString, required = false,
                                 default = nil)
  if valid_591119 != nil:
    section.add "X-Amz-Date", valid_591119
  var valid_591120 = header.getOrDefault("X-Amz-Credential")
  valid_591120 = validateParameter(valid_591120, JString, required = false,
                                 default = nil)
  if valid_591120 != nil:
    section.add "X-Amz-Credential", valid_591120
  var valid_591121 = header.getOrDefault("X-Amz-Security-Token")
  valid_591121 = validateParameter(valid_591121, JString, required = false,
                                 default = nil)
  if valid_591121 != nil:
    section.add "X-Amz-Security-Token", valid_591121
  var valid_591122 = header.getOrDefault("X-Amz-Algorithm")
  valid_591122 = validateParameter(valid_591122, JString, required = false,
                                 default = nil)
  if valid_591122 != nil:
    section.add "X-Amz-Algorithm", valid_591122
  var valid_591123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591123 = validateParameter(valid_591123, JString, required = false,
                                 default = nil)
  if valid_591123 != nil:
    section.add "X-Amz-SignedHeaders", valid_591123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591124: Call_GetDescribeAlarms_591106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_591124.validator(path, query, header, formData, body)
  let scheme = call_591124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591124.url(scheme.get, call_591124.host, call_591124.base,
                         call_591124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591124, url, valid)

proc call*(call_591125: Call_GetDescribeAlarms_591106; StateValue: string = "OK";
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
  var query_591126 = newJObject()
  add(query_591126, "StateValue", newJString(StateValue))
  add(query_591126, "ActionPrefix", newJString(ActionPrefix))
  add(query_591126, "NextToken", newJString(NextToken))
  add(query_591126, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  if AlarmNames != nil:
    query_591126.add "AlarmNames", AlarmNames
  add(query_591126, "Action", newJString(Action))
  add(query_591126, "Version", newJString(Version))
  add(query_591126, "MaxRecords", newJInt(MaxRecords))
  result = call_591125.call(nil, query_591126, nil, nil, nil)

var getDescribeAlarms* = Call_GetDescribeAlarms_591106(name: "getDescribeAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DescribeAlarms", validator: validate_GetDescribeAlarms_591107,
    base: "/", url: url_GetDescribeAlarms_591108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmsForMetric_591171 = ref object of OpenApiRestCall_590364
proc url_PostDescribeAlarmsForMetric_591173(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAlarmsForMetric_591172(path: JsonNode; query: JsonNode;
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
  var valid_591174 = query.getOrDefault("Action")
  valid_591174 = validateParameter(valid_591174, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_591174 != nil:
    section.add "Action", valid_591174
  var valid_591175 = query.getOrDefault("Version")
  valid_591175 = validateParameter(valid_591175, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591175 != nil:
    section.add "Version", valid_591175
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
  var valid_591176 = header.getOrDefault("X-Amz-Signature")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Signature", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-Content-Sha256", valid_591177
  var valid_591178 = header.getOrDefault("X-Amz-Date")
  valid_591178 = validateParameter(valid_591178, JString, required = false,
                                 default = nil)
  if valid_591178 != nil:
    section.add "X-Amz-Date", valid_591178
  var valid_591179 = header.getOrDefault("X-Amz-Credential")
  valid_591179 = validateParameter(valid_591179, JString, required = false,
                                 default = nil)
  if valid_591179 != nil:
    section.add "X-Amz-Credential", valid_591179
  var valid_591180 = header.getOrDefault("X-Amz-Security-Token")
  valid_591180 = validateParameter(valid_591180, JString, required = false,
                                 default = nil)
  if valid_591180 != nil:
    section.add "X-Amz-Security-Token", valid_591180
  var valid_591181 = header.getOrDefault("X-Amz-Algorithm")
  valid_591181 = validateParameter(valid_591181, JString, required = false,
                                 default = nil)
  if valid_591181 != nil:
    section.add "X-Amz-Algorithm", valid_591181
  var valid_591182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591182 = validateParameter(valid_591182, JString, required = false,
                                 default = nil)
  if valid_591182 != nil:
    section.add "X-Amz-SignedHeaders", valid_591182
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
  var valid_591183 = formData.getOrDefault("Unit")
  valid_591183 = validateParameter(valid_591183, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_591183 != nil:
    section.add "Unit", valid_591183
  var valid_591184 = formData.getOrDefault("Period")
  valid_591184 = validateParameter(valid_591184, JInt, required = false, default = nil)
  if valid_591184 != nil:
    section.add "Period", valid_591184
  var valid_591185 = formData.getOrDefault("Statistic")
  valid_591185 = validateParameter(valid_591185, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_591185 != nil:
    section.add "Statistic", valid_591185
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_591186 = formData.getOrDefault("MetricName")
  valid_591186 = validateParameter(valid_591186, JString, required = true,
                                 default = nil)
  if valid_591186 != nil:
    section.add "MetricName", valid_591186
  var valid_591187 = formData.getOrDefault("Dimensions")
  valid_591187 = validateParameter(valid_591187, JArray, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "Dimensions", valid_591187
  var valid_591188 = formData.getOrDefault("Namespace")
  valid_591188 = validateParameter(valid_591188, JString, required = true,
                                 default = nil)
  if valid_591188 != nil:
    section.add "Namespace", valid_591188
  var valid_591189 = formData.getOrDefault("ExtendedStatistic")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "ExtendedStatistic", valid_591189
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591190: Call_PostDescribeAlarmsForMetric_591171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_591190.validator(path, query, header, formData, body)
  let scheme = call_591190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591190.url(scheme.get, call_591190.host, call_591190.base,
                         call_591190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591190, url, valid)

proc call*(call_591191: Call_PostDescribeAlarmsForMetric_591171;
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
  var query_591192 = newJObject()
  var formData_591193 = newJObject()
  add(formData_591193, "Unit", newJString(Unit))
  add(formData_591193, "Period", newJInt(Period))
  add(formData_591193, "Statistic", newJString(Statistic))
  add(formData_591193, "MetricName", newJString(MetricName))
  add(query_591192, "Action", newJString(Action))
  if Dimensions != nil:
    formData_591193.add "Dimensions", Dimensions
  add(formData_591193, "Namespace", newJString(Namespace))
  add(formData_591193, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_591192, "Version", newJString(Version))
  result = call_591191.call(nil, query_591192, nil, formData_591193, nil)

var postDescribeAlarmsForMetric* = Call_PostDescribeAlarmsForMetric_591171(
    name: "postDescribeAlarmsForMetric", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_PostDescribeAlarmsForMetric_591172, base: "/",
    url: url_PostDescribeAlarmsForMetric_591173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmsForMetric_591149 = ref object of OpenApiRestCall_590364
proc url_GetDescribeAlarmsForMetric_591151(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAlarmsForMetric_591150(path: JsonNode; query: JsonNode;
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
  var valid_591152 = query.getOrDefault("Statistic")
  valid_591152 = validateParameter(valid_591152, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_591152 != nil:
    section.add "Statistic", valid_591152
  var valid_591153 = query.getOrDefault("Unit")
  valid_591153 = validateParameter(valid_591153, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_591153 != nil:
    section.add "Unit", valid_591153
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_591154 = query.getOrDefault("Namespace")
  valid_591154 = validateParameter(valid_591154, JString, required = true,
                                 default = nil)
  if valid_591154 != nil:
    section.add "Namespace", valid_591154
  var valid_591155 = query.getOrDefault("ExtendedStatistic")
  valid_591155 = validateParameter(valid_591155, JString, required = false,
                                 default = nil)
  if valid_591155 != nil:
    section.add "ExtendedStatistic", valid_591155
  var valid_591156 = query.getOrDefault("Period")
  valid_591156 = validateParameter(valid_591156, JInt, required = false, default = nil)
  if valid_591156 != nil:
    section.add "Period", valid_591156
  var valid_591157 = query.getOrDefault("Dimensions")
  valid_591157 = validateParameter(valid_591157, JArray, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "Dimensions", valid_591157
  var valid_591158 = query.getOrDefault("Action")
  valid_591158 = validateParameter(valid_591158, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_591158 != nil:
    section.add "Action", valid_591158
  var valid_591159 = query.getOrDefault("Version")
  valid_591159 = validateParameter(valid_591159, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591159 != nil:
    section.add "Version", valid_591159
  var valid_591160 = query.getOrDefault("MetricName")
  valid_591160 = validateParameter(valid_591160, JString, required = true,
                                 default = nil)
  if valid_591160 != nil:
    section.add "MetricName", valid_591160
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
  var valid_591161 = header.getOrDefault("X-Amz-Signature")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-Signature", valid_591161
  var valid_591162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591162 = validateParameter(valid_591162, JString, required = false,
                                 default = nil)
  if valid_591162 != nil:
    section.add "X-Amz-Content-Sha256", valid_591162
  var valid_591163 = header.getOrDefault("X-Amz-Date")
  valid_591163 = validateParameter(valid_591163, JString, required = false,
                                 default = nil)
  if valid_591163 != nil:
    section.add "X-Amz-Date", valid_591163
  var valid_591164 = header.getOrDefault("X-Amz-Credential")
  valid_591164 = validateParameter(valid_591164, JString, required = false,
                                 default = nil)
  if valid_591164 != nil:
    section.add "X-Amz-Credential", valid_591164
  var valid_591165 = header.getOrDefault("X-Amz-Security-Token")
  valid_591165 = validateParameter(valid_591165, JString, required = false,
                                 default = nil)
  if valid_591165 != nil:
    section.add "X-Amz-Security-Token", valid_591165
  var valid_591166 = header.getOrDefault("X-Amz-Algorithm")
  valid_591166 = validateParameter(valid_591166, JString, required = false,
                                 default = nil)
  if valid_591166 != nil:
    section.add "X-Amz-Algorithm", valid_591166
  var valid_591167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591167 = validateParameter(valid_591167, JString, required = false,
                                 default = nil)
  if valid_591167 != nil:
    section.add "X-Amz-SignedHeaders", valid_591167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591168: Call_GetDescribeAlarmsForMetric_591149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_591168.validator(path, query, header, formData, body)
  let scheme = call_591168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591168.url(scheme.get, call_591168.host, call_591168.base,
                         call_591168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591168, url, valid)

proc call*(call_591169: Call_GetDescribeAlarmsForMetric_591149; Namespace: string;
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
  var query_591170 = newJObject()
  add(query_591170, "Statistic", newJString(Statistic))
  add(query_591170, "Unit", newJString(Unit))
  add(query_591170, "Namespace", newJString(Namespace))
  add(query_591170, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_591170, "Period", newJInt(Period))
  if Dimensions != nil:
    query_591170.add "Dimensions", Dimensions
  add(query_591170, "Action", newJString(Action))
  add(query_591170, "Version", newJString(Version))
  add(query_591170, "MetricName", newJString(MetricName))
  result = call_591169.call(nil, query_591170, nil, nil, nil)

var getDescribeAlarmsForMetric* = Call_GetDescribeAlarmsForMetric_591149(
    name: "getDescribeAlarmsForMetric", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_GetDescribeAlarmsForMetric_591150, base: "/",
    url: url_GetDescribeAlarmsForMetric_591151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnomalyDetectors_591214 = ref object of OpenApiRestCall_590364
proc url_PostDescribeAnomalyDetectors_591216(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAnomalyDetectors_591215(path: JsonNode; query: JsonNode;
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
  var valid_591217 = query.getOrDefault("Action")
  valid_591217 = validateParameter(valid_591217, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_591217 != nil:
    section.add "Action", valid_591217
  var valid_591218 = query.getOrDefault("Version")
  valid_591218 = validateParameter(valid_591218, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591218 != nil:
    section.add "Version", valid_591218
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
  var valid_591219 = header.getOrDefault("X-Amz-Signature")
  valid_591219 = validateParameter(valid_591219, JString, required = false,
                                 default = nil)
  if valid_591219 != nil:
    section.add "X-Amz-Signature", valid_591219
  var valid_591220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591220 = validateParameter(valid_591220, JString, required = false,
                                 default = nil)
  if valid_591220 != nil:
    section.add "X-Amz-Content-Sha256", valid_591220
  var valid_591221 = header.getOrDefault("X-Amz-Date")
  valid_591221 = validateParameter(valid_591221, JString, required = false,
                                 default = nil)
  if valid_591221 != nil:
    section.add "X-Amz-Date", valid_591221
  var valid_591222 = header.getOrDefault("X-Amz-Credential")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "X-Amz-Credential", valid_591222
  var valid_591223 = header.getOrDefault("X-Amz-Security-Token")
  valid_591223 = validateParameter(valid_591223, JString, required = false,
                                 default = nil)
  if valid_591223 != nil:
    section.add "X-Amz-Security-Token", valid_591223
  var valid_591224 = header.getOrDefault("X-Amz-Algorithm")
  valid_591224 = validateParameter(valid_591224, JString, required = false,
                                 default = nil)
  if valid_591224 != nil:
    section.add "X-Amz-Algorithm", valid_591224
  var valid_591225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591225 = validateParameter(valid_591225, JString, required = false,
                                 default = nil)
  if valid_591225 != nil:
    section.add "X-Amz-SignedHeaders", valid_591225
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
  var valid_591226 = formData.getOrDefault("NextToken")
  valid_591226 = validateParameter(valid_591226, JString, required = false,
                                 default = nil)
  if valid_591226 != nil:
    section.add "NextToken", valid_591226
  var valid_591227 = formData.getOrDefault("MetricName")
  valid_591227 = validateParameter(valid_591227, JString, required = false,
                                 default = nil)
  if valid_591227 != nil:
    section.add "MetricName", valid_591227
  var valid_591228 = formData.getOrDefault("Dimensions")
  valid_591228 = validateParameter(valid_591228, JArray, required = false,
                                 default = nil)
  if valid_591228 != nil:
    section.add "Dimensions", valid_591228
  var valid_591229 = formData.getOrDefault("Namespace")
  valid_591229 = validateParameter(valid_591229, JString, required = false,
                                 default = nil)
  if valid_591229 != nil:
    section.add "Namespace", valid_591229
  var valid_591230 = formData.getOrDefault("MaxResults")
  valid_591230 = validateParameter(valid_591230, JInt, required = false, default = nil)
  if valid_591230 != nil:
    section.add "MaxResults", valid_591230
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591231: Call_PostDescribeAnomalyDetectors_591214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_591231.validator(path, query, header, formData, body)
  let scheme = call_591231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591231.url(scheme.get, call_591231.host, call_591231.base,
                         call_591231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591231, url, valid)

proc call*(call_591232: Call_PostDescribeAnomalyDetectors_591214;
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
  var query_591233 = newJObject()
  var formData_591234 = newJObject()
  add(formData_591234, "NextToken", newJString(NextToken))
  add(formData_591234, "MetricName", newJString(MetricName))
  add(query_591233, "Action", newJString(Action))
  if Dimensions != nil:
    formData_591234.add "Dimensions", Dimensions
  add(formData_591234, "Namespace", newJString(Namespace))
  add(query_591233, "Version", newJString(Version))
  add(formData_591234, "MaxResults", newJInt(MaxResults))
  result = call_591232.call(nil, query_591233, nil, formData_591234, nil)

var postDescribeAnomalyDetectors* = Call_PostDescribeAnomalyDetectors_591214(
    name: "postDescribeAnomalyDetectors", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_PostDescribeAnomalyDetectors_591215, base: "/",
    url: url_PostDescribeAnomalyDetectors_591216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnomalyDetectors_591194 = ref object of OpenApiRestCall_590364
proc url_GetDescribeAnomalyDetectors_591196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAnomalyDetectors_591195(path: JsonNode; query: JsonNode;
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
  var valid_591197 = query.getOrDefault("MaxResults")
  valid_591197 = validateParameter(valid_591197, JInt, required = false, default = nil)
  if valid_591197 != nil:
    section.add "MaxResults", valid_591197
  var valid_591198 = query.getOrDefault("NextToken")
  valid_591198 = validateParameter(valid_591198, JString, required = false,
                                 default = nil)
  if valid_591198 != nil:
    section.add "NextToken", valid_591198
  var valid_591199 = query.getOrDefault("Namespace")
  valid_591199 = validateParameter(valid_591199, JString, required = false,
                                 default = nil)
  if valid_591199 != nil:
    section.add "Namespace", valid_591199
  var valid_591200 = query.getOrDefault("Dimensions")
  valid_591200 = validateParameter(valid_591200, JArray, required = false,
                                 default = nil)
  if valid_591200 != nil:
    section.add "Dimensions", valid_591200
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_591201 = query.getOrDefault("Action")
  valid_591201 = validateParameter(valid_591201, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_591201 != nil:
    section.add "Action", valid_591201
  var valid_591202 = query.getOrDefault("Version")
  valid_591202 = validateParameter(valid_591202, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591202 != nil:
    section.add "Version", valid_591202
  var valid_591203 = query.getOrDefault("MetricName")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "MetricName", valid_591203
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
  var valid_591204 = header.getOrDefault("X-Amz-Signature")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "X-Amz-Signature", valid_591204
  var valid_591205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "X-Amz-Content-Sha256", valid_591205
  var valid_591206 = header.getOrDefault("X-Amz-Date")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-Date", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-Credential")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-Credential", valid_591207
  var valid_591208 = header.getOrDefault("X-Amz-Security-Token")
  valid_591208 = validateParameter(valid_591208, JString, required = false,
                                 default = nil)
  if valid_591208 != nil:
    section.add "X-Amz-Security-Token", valid_591208
  var valid_591209 = header.getOrDefault("X-Amz-Algorithm")
  valid_591209 = validateParameter(valid_591209, JString, required = false,
                                 default = nil)
  if valid_591209 != nil:
    section.add "X-Amz-Algorithm", valid_591209
  var valid_591210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591210 = validateParameter(valid_591210, JString, required = false,
                                 default = nil)
  if valid_591210 != nil:
    section.add "X-Amz-SignedHeaders", valid_591210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591211: Call_GetDescribeAnomalyDetectors_591194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_591211.validator(path, query, header, formData, body)
  let scheme = call_591211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591211.url(scheme.get, call_591211.host, call_591211.base,
                         call_591211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591211, url, valid)

proc call*(call_591212: Call_GetDescribeAnomalyDetectors_591194;
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
  var query_591213 = newJObject()
  add(query_591213, "MaxResults", newJInt(MaxResults))
  add(query_591213, "NextToken", newJString(NextToken))
  add(query_591213, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_591213.add "Dimensions", Dimensions
  add(query_591213, "Action", newJString(Action))
  add(query_591213, "Version", newJString(Version))
  add(query_591213, "MetricName", newJString(MetricName))
  result = call_591212.call(nil, query_591213, nil, nil, nil)

var getDescribeAnomalyDetectors* = Call_GetDescribeAnomalyDetectors_591194(
    name: "getDescribeAnomalyDetectors", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_GetDescribeAnomalyDetectors_591195, base: "/",
    url: url_GetDescribeAnomalyDetectors_591196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAlarmActions_591251 = ref object of OpenApiRestCall_590364
proc url_PostDisableAlarmActions_591253(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDisableAlarmActions_591252(path: JsonNode; query: JsonNode;
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
  var valid_591254 = query.getOrDefault("Action")
  valid_591254 = validateParameter(valid_591254, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_591254 != nil:
    section.add "Action", valid_591254
  var valid_591255 = query.getOrDefault("Version")
  valid_591255 = validateParameter(valid_591255, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591255 != nil:
    section.add "Version", valid_591255
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
  var valid_591256 = header.getOrDefault("X-Amz-Signature")
  valid_591256 = validateParameter(valid_591256, JString, required = false,
                                 default = nil)
  if valid_591256 != nil:
    section.add "X-Amz-Signature", valid_591256
  var valid_591257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591257 = validateParameter(valid_591257, JString, required = false,
                                 default = nil)
  if valid_591257 != nil:
    section.add "X-Amz-Content-Sha256", valid_591257
  var valid_591258 = header.getOrDefault("X-Amz-Date")
  valid_591258 = validateParameter(valid_591258, JString, required = false,
                                 default = nil)
  if valid_591258 != nil:
    section.add "X-Amz-Date", valid_591258
  var valid_591259 = header.getOrDefault("X-Amz-Credential")
  valid_591259 = validateParameter(valid_591259, JString, required = false,
                                 default = nil)
  if valid_591259 != nil:
    section.add "X-Amz-Credential", valid_591259
  var valid_591260 = header.getOrDefault("X-Amz-Security-Token")
  valid_591260 = validateParameter(valid_591260, JString, required = false,
                                 default = nil)
  if valid_591260 != nil:
    section.add "X-Amz-Security-Token", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-Algorithm")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-Algorithm", valid_591261
  var valid_591262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591262 = validateParameter(valid_591262, JString, required = false,
                                 default = nil)
  if valid_591262 != nil:
    section.add "X-Amz-SignedHeaders", valid_591262
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_591263 = formData.getOrDefault("AlarmNames")
  valid_591263 = validateParameter(valid_591263, JArray, required = true, default = nil)
  if valid_591263 != nil:
    section.add "AlarmNames", valid_591263
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591264: Call_PostDisableAlarmActions_591251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_591264.validator(path, query, header, formData, body)
  let scheme = call_591264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591264.url(scheme.get, call_591264.host, call_591264.base,
                         call_591264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591264, url, valid)

proc call*(call_591265: Call_PostDisableAlarmActions_591251; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_591266 = newJObject()
  var formData_591267 = newJObject()
  add(query_591266, "Action", newJString(Action))
  add(query_591266, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_591267.add "AlarmNames", AlarmNames
  result = call_591265.call(nil, query_591266, nil, formData_591267, nil)

var postDisableAlarmActions* = Call_PostDisableAlarmActions_591251(
    name: "postDisableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_PostDisableAlarmActions_591252, base: "/",
    url: url_PostDisableAlarmActions_591253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAlarmActions_591235 = ref object of OpenApiRestCall_590364
proc url_GetDisableAlarmActions_591237(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDisableAlarmActions_591236(path: JsonNode; query: JsonNode;
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
  var valid_591238 = query.getOrDefault("AlarmNames")
  valid_591238 = validateParameter(valid_591238, JArray, required = true, default = nil)
  if valid_591238 != nil:
    section.add "AlarmNames", valid_591238
  var valid_591239 = query.getOrDefault("Action")
  valid_591239 = validateParameter(valid_591239, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_591239 != nil:
    section.add "Action", valid_591239
  var valid_591240 = query.getOrDefault("Version")
  valid_591240 = validateParameter(valid_591240, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591240 != nil:
    section.add "Version", valid_591240
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
  var valid_591241 = header.getOrDefault("X-Amz-Signature")
  valid_591241 = validateParameter(valid_591241, JString, required = false,
                                 default = nil)
  if valid_591241 != nil:
    section.add "X-Amz-Signature", valid_591241
  var valid_591242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amz-Content-Sha256", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-Date")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-Date", valid_591243
  var valid_591244 = header.getOrDefault("X-Amz-Credential")
  valid_591244 = validateParameter(valid_591244, JString, required = false,
                                 default = nil)
  if valid_591244 != nil:
    section.add "X-Amz-Credential", valid_591244
  var valid_591245 = header.getOrDefault("X-Amz-Security-Token")
  valid_591245 = validateParameter(valid_591245, JString, required = false,
                                 default = nil)
  if valid_591245 != nil:
    section.add "X-Amz-Security-Token", valid_591245
  var valid_591246 = header.getOrDefault("X-Amz-Algorithm")
  valid_591246 = validateParameter(valid_591246, JString, required = false,
                                 default = nil)
  if valid_591246 != nil:
    section.add "X-Amz-Algorithm", valid_591246
  var valid_591247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591247 = validateParameter(valid_591247, JString, required = false,
                                 default = nil)
  if valid_591247 != nil:
    section.add "X-Amz-SignedHeaders", valid_591247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591248: Call_GetDisableAlarmActions_591235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_591248.validator(path, query, header, formData, body)
  let scheme = call_591248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591248.url(scheme.get, call_591248.host, call_591248.base,
                         call_591248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591248, url, valid)

proc call*(call_591249: Call_GetDisableAlarmActions_591235; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_591250 = newJObject()
  if AlarmNames != nil:
    query_591250.add "AlarmNames", AlarmNames
  add(query_591250, "Action", newJString(Action))
  add(query_591250, "Version", newJString(Version))
  result = call_591249.call(nil, query_591250, nil, nil, nil)

var getDisableAlarmActions* = Call_GetDisableAlarmActions_591235(
    name: "getDisableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_GetDisableAlarmActions_591236, base: "/",
    url: url_GetDisableAlarmActions_591237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAlarmActions_591284 = ref object of OpenApiRestCall_590364
proc url_PostEnableAlarmActions_591286(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostEnableAlarmActions_591285(path: JsonNode; query: JsonNode;
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
  var valid_591287 = query.getOrDefault("Action")
  valid_591287 = validateParameter(valid_591287, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_591287 != nil:
    section.add "Action", valid_591287
  var valid_591288 = query.getOrDefault("Version")
  valid_591288 = validateParameter(valid_591288, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591288 != nil:
    section.add "Version", valid_591288
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
  var valid_591289 = header.getOrDefault("X-Amz-Signature")
  valid_591289 = validateParameter(valid_591289, JString, required = false,
                                 default = nil)
  if valid_591289 != nil:
    section.add "X-Amz-Signature", valid_591289
  var valid_591290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591290 = validateParameter(valid_591290, JString, required = false,
                                 default = nil)
  if valid_591290 != nil:
    section.add "X-Amz-Content-Sha256", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Date")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Date", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-Credential")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Credential", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Security-Token")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Security-Token", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-Algorithm")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-Algorithm", valid_591294
  var valid_591295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591295 = validateParameter(valid_591295, JString, required = false,
                                 default = nil)
  if valid_591295 != nil:
    section.add "X-Amz-SignedHeaders", valid_591295
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_591296 = formData.getOrDefault("AlarmNames")
  valid_591296 = validateParameter(valid_591296, JArray, required = true, default = nil)
  if valid_591296 != nil:
    section.add "AlarmNames", valid_591296
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591297: Call_PostEnableAlarmActions_591284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_591297.validator(path, query, header, formData, body)
  let scheme = call_591297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591297.url(scheme.get, call_591297.host, call_591297.base,
                         call_591297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591297, url, valid)

proc call*(call_591298: Call_PostEnableAlarmActions_591284; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_591299 = newJObject()
  var formData_591300 = newJObject()
  add(query_591299, "Action", newJString(Action))
  add(query_591299, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_591300.add "AlarmNames", AlarmNames
  result = call_591298.call(nil, query_591299, nil, formData_591300, nil)

var postEnableAlarmActions* = Call_PostEnableAlarmActions_591284(
    name: "postEnableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_PostEnableAlarmActions_591285, base: "/",
    url: url_PostEnableAlarmActions_591286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAlarmActions_591268 = ref object of OpenApiRestCall_590364
proc url_GetEnableAlarmActions_591270(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEnableAlarmActions_591269(path: JsonNode; query: JsonNode;
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
  var valid_591271 = query.getOrDefault("AlarmNames")
  valid_591271 = validateParameter(valid_591271, JArray, required = true, default = nil)
  if valid_591271 != nil:
    section.add "AlarmNames", valid_591271
  var valid_591272 = query.getOrDefault("Action")
  valid_591272 = validateParameter(valid_591272, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_591272 != nil:
    section.add "Action", valid_591272
  var valid_591273 = query.getOrDefault("Version")
  valid_591273 = validateParameter(valid_591273, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591273 != nil:
    section.add "Version", valid_591273
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
  var valid_591274 = header.getOrDefault("X-Amz-Signature")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "X-Amz-Signature", valid_591274
  var valid_591275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591275 = validateParameter(valid_591275, JString, required = false,
                                 default = nil)
  if valid_591275 != nil:
    section.add "X-Amz-Content-Sha256", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-Date")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Date", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-Credential")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-Credential", valid_591277
  var valid_591278 = header.getOrDefault("X-Amz-Security-Token")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Security-Token", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-Algorithm")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-Algorithm", valid_591279
  var valid_591280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591280 = validateParameter(valid_591280, JString, required = false,
                                 default = nil)
  if valid_591280 != nil:
    section.add "X-Amz-SignedHeaders", valid_591280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591281: Call_GetEnableAlarmActions_591268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_591281.validator(path, query, header, formData, body)
  let scheme = call_591281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591281.url(scheme.get, call_591281.host, call_591281.base,
                         call_591281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591281, url, valid)

proc call*(call_591282: Call_GetEnableAlarmActions_591268; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_591283 = newJObject()
  if AlarmNames != nil:
    query_591283.add "AlarmNames", AlarmNames
  add(query_591283, "Action", newJString(Action))
  add(query_591283, "Version", newJString(Version))
  result = call_591282.call(nil, query_591283, nil, nil, nil)

var getEnableAlarmActions* = Call_GetEnableAlarmActions_591268(
    name: "getEnableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_GetEnableAlarmActions_591269, base: "/",
    url: url_GetEnableAlarmActions_591270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetDashboard_591317 = ref object of OpenApiRestCall_590364
proc url_PostGetDashboard_591319(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetDashboard_591318(path: JsonNode; query: JsonNode;
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
  var valid_591320 = query.getOrDefault("Action")
  valid_591320 = validateParameter(valid_591320, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_591320 != nil:
    section.add "Action", valid_591320
  var valid_591321 = query.getOrDefault("Version")
  valid_591321 = validateParameter(valid_591321, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591321 != nil:
    section.add "Version", valid_591321
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
  var valid_591322 = header.getOrDefault("X-Amz-Signature")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-Signature", valid_591322
  var valid_591323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591323 = validateParameter(valid_591323, JString, required = false,
                                 default = nil)
  if valid_591323 != nil:
    section.add "X-Amz-Content-Sha256", valid_591323
  var valid_591324 = header.getOrDefault("X-Amz-Date")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-Date", valid_591324
  var valid_591325 = header.getOrDefault("X-Amz-Credential")
  valid_591325 = validateParameter(valid_591325, JString, required = false,
                                 default = nil)
  if valid_591325 != nil:
    section.add "X-Amz-Credential", valid_591325
  var valid_591326 = header.getOrDefault("X-Amz-Security-Token")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-Security-Token", valid_591326
  var valid_591327 = header.getOrDefault("X-Amz-Algorithm")
  valid_591327 = validateParameter(valid_591327, JString, required = false,
                                 default = nil)
  if valid_591327 != nil:
    section.add "X-Amz-Algorithm", valid_591327
  var valid_591328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591328 = validateParameter(valid_591328, JString, required = false,
                                 default = nil)
  if valid_591328 != nil:
    section.add "X-Amz-SignedHeaders", valid_591328
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_591329 = formData.getOrDefault("DashboardName")
  valid_591329 = validateParameter(valid_591329, JString, required = true,
                                 default = nil)
  if valid_591329 != nil:
    section.add "DashboardName", valid_591329
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591330: Call_PostGetDashboard_591317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_591330.validator(path, query, header, formData, body)
  let scheme = call_591330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591330.url(scheme.get, call_591330.host, call_591330.base,
                         call_591330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591330, url, valid)

proc call*(call_591331: Call_PostGetDashboard_591317; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## postGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_591332 = newJObject()
  var formData_591333 = newJObject()
  add(formData_591333, "DashboardName", newJString(DashboardName))
  add(query_591332, "Action", newJString(Action))
  add(query_591332, "Version", newJString(Version))
  result = call_591331.call(nil, query_591332, nil, formData_591333, nil)

var postGetDashboard* = Call_PostGetDashboard_591317(name: "postGetDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_PostGetDashboard_591318,
    base: "/", url: url_PostGetDashboard_591319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetDashboard_591301 = ref object of OpenApiRestCall_590364
proc url_GetGetDashboard_591303(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetDashboard_591302(path: JsonNode; query: JsonNode;
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
  var valid_591304 = query.getOrDefault("Action")
  valid_591304 = validateParameter(valid_591304, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_591304 != nil:
    section.add "Action", valid_591304
  var valid_591305 = query.getOrDefault("DashboardName")
  valid_591305 = validateParameter(valid_591305, JString, required = true,
                                 default = nil)
  if valid_591305 != nil:
    section.add "DashboardName", valid_591305
  var valid_591306 = query.getOrDefault("Version")
  valid_591306 = validateParameter(valid_591306, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591306 != nil:
    section.add "Version", valid_591306
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
  var valid_591307 = header.getOrDefault("X-Amz-Signature")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Signature", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-Content-Sha256", valid_591308
  var valid_591309 = header.getOrDefault("X-Amz-Date")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-Date", valid_591309
  var valid_591310 = header.getOrDefault("X-Amz-Credential")
  valid_591310 = validateParameter(valid_591310, JString, required = false,
                                 default = nil)
  if valid_591310 != nil:
    section.add "X-Amz-Credential", valid_591310
  var valid_591311 = header.getOrDefault("X-Amz-Security-Token")
  valid_591311 = validateParameter(valid_591311, JString, required = false,
                                 default = nil)
  if valid_591311 != nil:
    section.add "X-Amz-Security-Token", valid_591311
  var valid_591312 = header.getOrDefault("X-Amz-Algorithm")
  valid_591312 = validateParameter(valid_591312, JString, required = false,
                                 default = nil)
  if valid_591312 != nil:
    section.add "X-Amz-Algorithm", valid_591312
  var valid_591313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591313 = validateParameter(valid_591313, JString, required = false,
                                 default = nil)
  if valid_591313 != nil:
    section.add "X-Amz-SignedHeaders", valid_591313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591314: Call_GetGetDashboard_591301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_591314.validator(path, query, header, formData, body)
  let scheme = call_591314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591314.url(scheme.get, call_591314.host, call_591314.base,
                         call_591314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591314, url, valid)

proc call*(call_591315: Call_GetGetDashboard_591301; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## getGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Version: string (required)
  var query_591316 = newJObject()
  add(query_591316, "Action", newJString(Action))
  add(query_591316, "DashboardName", newJString(DashboardName))
  add(query_591316, "Version", newJString(Version))
  result = call_591315.call(nil, query_591316, nil, nil, nil)

var getGetDashboard* = Call_GetGetDashboard_591301(name: "getGetDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_GetGetDashboard_591302,
    base: "/", url: url_GetGetDashboard_591303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricData_591355 = ref object of OpenApiRestCall_590364
proc url_PostGetMetricData_591357(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetMetricData_591356(path: JsonNode; query: JsonNode;
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
  var valid_591358 = query.getOrDefault("Action")
  valid_591358 = validateParameter(valid_591358, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_591358 != nil:
    section.add "Action", valid_591358
  var valid_591359 = query.getOrDefault("Version")
  valid_591359 = validateParameter(valid_591359, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591359 != nil:
    section.add "Version", valid_591359
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
  var valid_591360 = header.getOrDefault("X-Amz-Signature")
  valid_591360 = validateParameter(valid_591360, JString, required = false,
                                 default = nil)
  if valid_591360 != nil:
    section.add "X-Amz-Signature", valid_591360
  var valid_591361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591361 = validateParameter(valid_591361, JString, required = false,
                                 default = nil)
  if valid_591361 != nil:
    section.add "X-Amz-Content-Sha256", valid_591361
  var valid_591362 = header.getOrDefault("X-Amz-Date")
  valid_591362 = validateParameter(valid_591362, JString, required = false,
                                 default = nil)
  if valid_591362 != nil:
    section.add "X-Amz-Date", valid_591362
  var valid_591363 = header.getOrDefault("X-Amz-Credential")
  valid_591363 = validateParameter(valid_591363, JString, required = false,
                                 default = nil)
  if valid_591363 != nil:
    section.add "X-Amz-Credential", valid_591363
  var valid_591364 = header.getOrDefault("X-Amz-Security-Token")
  valid_591364 = validateParameter(valid_591364, JString, required = false,
                                 default = nil)
  if valid_591364 != nil:
    section.add "X-Amz-Security-Token", valid_591364
  var valid_591365 = header.getOrDefault("X-Amz-Algorithm")
  valid_591365 = validateParameter(valid_591365, JString, required = false,
                                 default = nil)
  if valid_591365 != nil:
    section.add "X-Amz-Algorithm", valid_591365
  var valid_591366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591366 = validateParameter(valid_591366, JString, required = false,
                                 default = nil)
  if valid_591366 != nil:
    section.add "X-Amz-SignedHeaders", valid_591366
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
  var valid_591367 = formData.getOrDefault("NextToken")
  valid_591367 = validateParameter(valid_591367, JString, required = false,
                                 default = nil)
  if valid_591367 != nil:
    section.add "NextToken", valid_591367
  var valid_591368 = formData.getOrDefault("ScanBy")
  valid_591368 = validateParameter(valid_591368, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_591368 != nil:
    section.add "ScanBy", valid_591368
  assert formData != nil,
        "formData argument is necessary due to required `EndTime` field"
  var valid_591369 = formData.getOrDefault("EndTime")
  valid_591369 = validateParameter(valid_591369, JString, required = true,
                                 default = nil)
  if valid_591369 != nil:
    section.add "EndTime", valid_591369
  var valid_591370 = formData.getOrDefault("StartTime")
  valid_591370 = validateParameter(valid_591370, JString, required = true,
                                 default = nil)
  if valid_591370 != nil:
    section.add "StartTime", valid_591370
  var valid_591371 = formData.getOrDefault("MetricDataQueries")
  valid_591371 = validateParameter(valid_591371, JArray, required = true, default = nil)
  if valid_591371 != nil:
    section.add "MetricDataQueries", valid_591371
  var valid_591372 = formData.getOrDefault("MaxDatapoints")
  valid_591372 = validateParameter(valid_591372, JInt, required = false, default = nil)
  if valid_591372 != nil:
    section.add "MaxDatapoints", valid_591372
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591373: Call_PostGetMetricData_591355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_591373.validator(path, query, header, formData, body)
  let scheme = call_591373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591373.url(scheme.get, call_591373.host, call_591373.base,
                         call_591373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591373, url, valid)

proc call*(call_591374: Call_PostGetMetricData_591355; EndTime: string;
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
  var query_591375 = newJObject()
  var formData_591376 = newJObject()
  add(formData_591376, "NextToken", newJString(NextToken))
  add(formData_591376, "ScanBy", newJString(ScanBy))
  add(formData_591376, "EndTime", newJString(EndTime))
  add(formData_591376, "StartTime", newJString(StartTime))
  add(query_591375, "Action", newJString(Action))
  add(query_591375, "Version", newJString(Version))
  if MetricDataQueries != nil:
    formData_591376.add "MetricDataQueries", MetricDataQueries
  add(formData_591376, "MaxDatapoints", newJInt(MaxDatapoints))
  result = call_591374.call(nil, query_591375, nil, formData_591376, nil)

var postGetMetricData* = Call_PostGetMetricData_591355(name: "postGetMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_PostGetMetricData_591356,
    base: "/", url: url_PostGetMetricData_591357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricData_591334 = ref object of OpenApiRestCall_590364
proc url_GetGetMetricData_591336(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetMetricData_591335(path: JsonNode; query: JsonNode;
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
  var valid_591337 = query.getOrDefault("NextToken")
  valid_591337 = validateParameter(valid_591337, JString, required = false,
                                 default = nil)
  if valid_591337 != nil:
    section.add "NextToken", valid_591337
  var valid_591338 = query.getOrDefault("MaxDatapoints")
  valid_591338 = validateParameter(valid_591338, JInt, required = false, default = nil)
  if valid_591338 != nil:
    section.add "MaxDatapoints", valid_591338
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_591339 = query.getOrDefault("Action")
  valid_591339 = validateParameter(valid_591339, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_591339 != nil:
    section.add "Action", valid_591339
  var valid_591340 = query.getOrDefault("StartTime")
  valid_591340 = validateParameter(valid_591340, JString, required = true,
                                 default = nil)
  if valid_591340 != nil:
    section.add "StartTime", valid_591340
  var valid_591341 = query.getOrDefault("EndTime")
  valid_591341 = validateParameter(valid_591341, JString, required = true,
                                 default = nil)
  if valid_591341 != nil:
    section.add "EndTime", valid_591341
  var valid_591342 = query.getOrDefault("Version")
  valid_591342 = validateParameter(valid_591342, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591342 != nil:
    section.add "Version", valid_591342
  var valid_591343 = query.getOrDefault("MetricDataQueries")
  valid_591343 = validateParameter(valid_591343, JArray, required = true, default = nil)
  if valid_591343 != nil:
    section.add "MetricDataQueries", valid_591343
  var valid_591344 = query.getOrDefault("ScanBy")
  valid_591344 = validateParameter(valid_591344, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_591344 != nil:
    section.add "ScanBy", valid_591344
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
  var valid_591345 = header.getOrDefault("X-Amz-Signature")
  valid_591345 = validateParameter(valid_591345, JString, required = false,
                                 default = nil)
  if valid_591345 != nil:
    section.add "X-Amz-Signature", valid_591345
  var valid_591346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591346 = validateParameter(valid_591346, JString, required = false,
                                 default = nil)
  if valid_591346 != nil:
    section.add "X-Amz-Content-Sha256", valid_591346
  var valid_591347 = header.getOrDefault("X-Amz-Date")
  valid_591347 = validateParameter(valid_591347, JString, required = false,
                                 default = nil)
  if valid_591347 != nil:
    section.add "X-Amz-Date", valid_591347
  var valid_591348 = header.getOrDefault("X-Amz-Credential")
  valid_591348 = validateParameter(valid_591348, JString, required = false,
                                 default = nil)
  if valid_591348 != nil:
    section.add "X-Amz-Credential", valid_591348
  var valid_591349 = header.getOrDefault("X-Amz-Security-Token")
  valid_591349 = validateParameter(valid_591349, JString, required = false,
                                 default = nil)
  if valid_591349 != nil:
    section.add "X-Amz-Security-Token", valid_591349
  var valid_591350 = header.getOrDefault("X-Amz-Algorithm")
  valid_591350 = validateParameter(valid_591350, JString, required = false,
                                 default = nil)
  if valid_591350 != nil:
    section.add "X-Amz-Algorithm", valid_591350
  var valid_591351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591351 = validateParameter(valid_591351, JString, required = false,
                                 default = nil)
  if valid_591351 != nil:
    section.add "X-Amz-SignedHeaders", valid_591351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591352: Call_GetGetMetricData_591334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 datapoints. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_591352.validator(path, query, header, formData, body)
  let scheme = call_591352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591352.url(scheme.get, call_591352.host, call_591352.base,
                         call_591352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591352, url, valid)

proc call*(call_591353: Call_GetGetMetricData_591334; StartTime: string;
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
  var query_591354 = newJObject()
  add(query_591354, "NextToken", newJString(NextToken))
  add(query_591354, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_591354, "Action", newJString(Action))
  add(query_591354, "StartTime", newJString(StartTime))
  add(query_591354, "EndTime", newJString(EndTime))
  add(query_591354, "Version", newJString(Version))
  if MetricDataQueries != nil:
    query_591354.add "MetricDataQueries", MetricDataQueries
  add(query_591354, "ScanBy", newJString(ScanBy))
  result = call_591353.call(nil, query_591354, nil, nil, nil)

var getGetMetricData* = Call_GetGetMetricData_591334(name: "getGetMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_GetGetMetricData_591335,
    base: "/", url: url_GetGetMetricData_591336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricStatistics_591401 = ref object of OpenApiRestCall_590364
proc url_PostGetMetricStatistics_591403(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetMetricStatistics_591402(path: JsonNode; query: JsonNode;
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
  var valid_591404 = query.getOrDefault("Action")
  valid_591404 = validateParameter(valid_591404, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_591404 != nil:
    section.add "Action", valid_591404
  var valid_591405 = query.getOrDefault("Version")
  valid_591405 = validateParameter(valid_591405, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591405 != nil:
    section.add "Version", valid_591405
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
  var valid_591406 = header.getOrDefault("X-Amz-Signature")
  valid_591406 = validateParameter(valid_591406, JString, required = false,
                                 default = nil)
  if valid_591406 != nil:
    section.add "X-Amz-Signature", valid_591406
  var valid_591407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591407 = validateParameter(valid_591407, JString, required = false,
                                 default = nil)
  if valid_591407 != nil:
    section.add "X-Amz-Content-Sha256", valid_591407
  var valid_591408 = header.getOrDefault("X-Amz-Date")
  valid_591408 = validateParameter(valid_591408, JString, required = false,
                                 default = nil)
  if valid_591408 != nil:
    section.add "X-Amz-Date", valid_591408
  var valid_591409 = header.getOrDefault("X-Amz-Credential")
  valid_591409 = validateParameter(valid_591409, JString, required = false,
                                 default = nil)
  if valid_591409 != nil:
    section.add "X-Amz-Credential", valid_591409
  var valid_591410 = header.getOrDefault("X-Amz-Security-Token")
  valid_591410 = validateParameter(valid_591410, JString, required = false,
                                 default = nil)
  if valid_591410 != nil:
    section.add "X-Amz-Security-Token", valid_591410
  var valid_591411 = header.getOrDefault("X-Amz-Algorithm")
  valid_591411 = validateParameter(valid_591411, JString, required = false,
                                 default = nil)
  if valid_591411 != nil:
    section.add "X-Amz-Algorithm", valid_591411
  var valid_591412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591412 = validateParameter(valid_591412, JString, required = false,
                                 default = nil)
  if valid_591412 != nil:
    section.add "X-Amz-SignedHeaders", valid_591412
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
  var valid_591413 = formData.getOrDefault("Unit")
  valid_591413 = validateParameter(valid_591413, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_591413 != nil:
    section.add "Unit", valid_591413
  assert formData != nil,
        "formData argument is necessary due to required `Period` field"
  var valid_591414 = formData.getOrDefault("Period")
  valid_591414 = validateParameter(valid_591414, JInt, required = true, default = nil)
  if valid_591414 != nil:
    section.add "Period", valid_591414
  var valid_591415 = formData.getOrDefault("Statistics")
  valid_591415 = validateParameter(valid_591415, JArray, required = false,
                                 default = nil)
  if valid_591415 != nil:
    section.add "Statistics", valid_591415
  var valid_591416 = formData.getOrDefault("ExtendedStatistics")
  valid_591416 = validateParameter(valid_591416, JArray, required = false,
                                 default = nil)
  if valid_591416 != nil:
    section.add "ExtendedStatistics", valid_591416
  var valid_591417 = formData.getOrDefault("EndTime")
  valid_591417 = validateParameter(valid_591417, JString, required = true,
                                 default = nil)
  if valid_591417 != nil:
    section.add "EndTime", valid_591417
  var valid_591418 = formData.getOrDefault("StartTime")
  valid_591418 = validateParameter(valid_591418, JString, required = true,
                                 default = nil)
  if valid_591418 != nil:
    section.add "StartTime", valid_591418
  var valid_591419 = formData.getOrDefault("MetricName")
  valid_591419 = validateParameter(valid_591419, JString, required = true,
                                 default = nil)
  if valid_591419 != nil:
    section.add "MetricName", valid_591419
  var valid_591420 = formData.getOrDefault("Dimensions")
  valid_591420 = validateParameter(valid_591420, JArray, required = false,
                                 default = nil)
  if valid_591420 != nil:
    section.add "Dimensions", valid_591420
  var valid_591421 = formData.getOrDefault("Namespace")
  valid_591421 = validateParameter(valid_591421, JString, required = true,
                                 default = nil)
  if valid_591421 != nil:
    section.add "Namespace", valid_591421
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591422: Call_PostGetMetricStatistics_591401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_591422.validator(path, query, header, formData, body)
  let scheme = call_591422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591422.url(scheme.get, call_591422.host, call_591422.base,
                         call_591422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591422, url, valid)

proc call*(call_591423: Call_PostGetMetricStatistics_591401; Period: int;
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
  var query_591424 = newJObject()
  var formData_591425 = newJObject()
  add(formData_591425, "Unit", newJString(Unit))
  add(formData_591425, "Period", newJInt(Period))
  if Statistics != nil:
    formData_591425.add "Statistics", Statistics
  if ExtendedStatistics != nil:
    formData_591425.add "ExtendedStatistics", ExtendedStatistics
  add(formData_591425, "EndTime", newJString(EndTime))
  add(formData_591425, "StartTime", newJString(StartTime))
  add(formData_591425, "MetricName", newJString(MetricName))
  add(query_591424, "Action", newJString(Action))
  if Dimensions != nil:
    formData_591425.add "Dimensions", Dimensions
  add(formData_591425, "Namespace", newJString(Namespace))
  add(query_591424, "Version", newJString(Version))
  result = call_591423.call(nil, query_591424, nil, formData_591425, nil)

var postGetMetricStatistics* = Call_PostGetMetricStatistics_591401(
    name: "postGetMetricStatistics", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_PostGetMetricStatistics_591402, base: "/",
    url: url_PostGetMetricStatistics_591403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricStatistics_591377 = ref object of OpenApiRestCall_590364
proc url_GetGetMetricStatistics_591379(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetMetricStatistics_591378(path: JsonNode; query: JsonNode;
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
  var valid_591380 = query.getOrDefault("Unit")
  valid_591380 = validateParameter(valid_591380, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_591380 != nil:
    section.add "Unit", valid_591380
  var valid_591381 = query.getOrDefault("ExtendedStatistics")
  valid_591381 = validateParameter(valid_591381, JArray, required = false,
                                 default = nil)
  if valid_591381 != nil:
    section.add "ExtendedStatistics", valid_591381
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_591382 = query.getOrDefault("Namespace")
  valid_591382 = validateParameter(valid_591382, JString, required = true,
                                 default = nil)
  if valid_591382 != nil:
    section.add "Namespace", valid_591382
  var valid_591383 = query.getOrDefault("Statistics")
  valid_591383 = validateParameter(valid_591383, JArray, required = false,
                                 default = nil)
  if valid_591383 != nil:
    section.add "Statistics", valid_591383
  var valid_591384 = query.getOrDefault("Period")
  valid_591384 = validateParameter(valid_591384, JInt, required = true, default = nil)
  if valid_591384 != nil:
    section.add "Period", valid_591384
  var valid_591385 = query.getOrDefault("Dimensions")
  valid_591385 = validateParameter(valid_591385, JArray, required = false,
                                 default = nil)
  if valid_591385 != nil:
    section.add "Dimensions", valid_591385
  var valid_591386 = query.getOrDefault("Action")
  valid_591386 = validateParameter(valid_591386, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_591386 != nil:
    section.add "Action", valid_591386
  var valid_591387 = query.getOrDefault("StartTime")
  valid_591387 = validateParameter(valid_591387, JString, required = true,
                                 default = nil)
  if valid_591387 != nil:
    section.add "StartTime", valid_591387
  var valid_591388 = query.getOrDefault("EndTime")
  valid_591388 = validateParameter(valid_591388, JString, required = true,
                                 default = nil)
  if valid_591388 != nil:
    section.add "EndTime", valid_591388
  var valid_591389 = query.getOrDefault("Version")
  valid_591389 = validateParameter(valid_591389, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591389 != nil:
    section.add "Version", valid_591389
  var valid_591390 = query.getOrDefault("MetricName")
  valid_591390 = validateParameter(valid_591390, JString, required = true,
                                 default = nil)
  if valid_591390 != nil:
    section.add "MetricName", valid_591390
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
  var valid_591391 = header.getOrDefault("X-Amz-Signature")
  valid_591391 = validateParameter(valid_591391, JString, required = false,
                                 default = nil)
  if valid_591391 != nil:
    section.add "X-Amz-Signature", valid_591391
  var valid_591392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591392 = validateParameter(valid_591392, JString, required = false,
                                 default = nil)
  if valid_591392 != nil:
    section.add "X-Amz-Content-Sha256", valid_591392
  var valid_591393 = header.getOrDefault("X-Amz-Date")
  valid_591393 = validateParameter(valid_591393, JString, required = false,
                                 default = nil)
  if valid_591393 != nil:
    section.add "X-Amz-Date", valid_591393
  var valid_591394 = header.getOrDefault("X-Amz-Credential")
  valid_591394 = validateParameter(valid_591394, JString, required = false,
                                 default = nil)
  if valid_591394 != nil:
    section.add "X-Amz-Credential", valid_591394
  var valid_591395 = header.getOrDefault("X-Amz-Security-Token")
  valid_591395 = validateParameter(valid_591395, JString, required = false,
                                 default = nil)
  if valid_591395 != nil:
    section.add "X-Amz-Security-Token", valid_591395
  var valid_591396 = header.getOrDefault("X-Amz-Algorithm")
  valid_591396 = validateParameter(valid_591396, JString, required = false,
                                 default = nil)
  if valid_591396 != nil:
    section.add "X-Amz-Algorithm", valid_591396
  var valid_591397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591397 = validateParameter(valid_591397, JString, required = false,
                                 default = nil)
  if valid_591397 != nil:
    section.add "X-Amz-SignedHeaders", valid_591397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591398: Call_GetGetMetricStatistics_591377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_591398.validator(path, query, header, formData, body)
  let scheme = call_591398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591398.url(scheme.get, call_591398.host, call_591398.base,
                         call_591398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591398, url, valid)

proc call*(call_591399: Call_GetGetMetricStatistics_591377; Namespace: string;
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
  var query_591400 = newJObject()
  add(query_591400, "Unit", newJString(Unit))
  if ExtendedStatistics != nil:
    query_591400.add "ExtendedStatistics", ExtendedStatistics
  add(query_591400, "Namespace", newJString(Namespace))
  if Statistics != nil:
    query_591400.add "Statistics", Statistics
  add(query_591400, "Period", newJInt(Period))
  if Dimensions != nil:
    query_591400.add "Dimensions", Dimensions
  add(query_591400, "Action", newJString(Action))
  add(query_591400, "StartTime", newJString(StartTime))
  add(query_591400, "EndTime", newJString(EndTime))
  add(query_591400, "Version", newJString(Version))
  add(query_591400, "MetricName", newJString(MetricName))
  result = call_591399.call(nil, query_591400, nil, nil, nil)

var getGetMetricStatistics* = Call_GetGetMetricStatistics_591377(
    name: "getGetMetricStatistics", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_GetGetMetricStatistics_591378, base: "/",
    url: url_GetGetMetricStatistics_591379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricWidgetImage_591443 = ref object of OpenApiRestCall_590364
proc url_PostGetMetricWidgetImage_591445(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetMetricWidgetImage_591444(path: JsonNode; query: JsonNode;
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
  var valid_591446 = query.getOrDefault("Action")
  valid_591446 = validateParameter(valid_591446, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_591446 != nil:
    section.add "Action", valid_591446
  var valid_591447 = query.getOrDefault("Version")
  valid_591447 = validateParameter(valid_591447, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591447 != nil:
    section.add "Version", valid_591447
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
  var valid_591448 = header.getOrDefault("X-Amz-Signature")
  valid_591448 = validateParameter(valid_591448, JString, required = false,
                                 default = nil)
  if valid_591448 != nil:
    section.add "X-Amz-Signature", valid_591448
  var valid_591449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591449 = validateParameter(valid_591449, JString, required = false,
                                 default = nil)
  if valid_591449 != nil:
    section.add "X-Amz-Content-Sha256", valid_591449
  var valid_591450 = header.getOrDefault("X-Amz-Date")
  valid_591450 = validateParameter(valid_591450, JString, required = false,
                                 default = nil)
  if valid_591450 != nil:
    section.add "X-Amz-Date", valid_591450
  var valid_591451 = header.getOrDefault("X-Amz-Credential")
  valid_591451 = validateParameter(valid_591451, JString, required = false,
                                 default = nil)
  if valid_591451 != nil:
    section.add "X-Amz-Credential", valid_591451
  var valid_591452 = header.getOrDefault("X-Amz-Security-Token")
  valid_591452 = validateParameter(valid_591452, JString, required = false,
                                 default = nil)
  if valid_591452 != nil:
    section.add "X-Amz-Security-Token", valid_591452
  var valid_591453 = header.getOrDefault("X-Amz-Algorithm")
  valid_591453 = validateParameter(valid_591453, JString, required = false,
                                 default = nil)
  if valid_591453 != nil:
    section.add "X-Amz-Algorithm", valid_591453
  var valid_591454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591454 = validateParameter(valid_591454, JString, required = false,
                                 default = nil)
  if valid_591454 != nil:
    section.add "X-Amz-SignedHeaders", valid_591454
  result.add "header", section
  ## parameters in `formData` object:
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MetricWidget` field"
  var valid_591455 = formData.getOrDefault("MetricWidget")
  valid_591455 = validateParameter(valid_591455, JString, required = true,
                                 default = nil)
  if valid_591455 != nil:
    section.add "MetricWidget", valid_591455
  var valid_591456 = formData.getOrDefault("OutputFormat")
  valid_591456 = validateParameter(valid_591456, JString, required = false,
                                 default = nil)
  if valid_591456 != nil:
    section.add "OutputFormat", valid_591456
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591457: Call_PostGetMetricWidgetImage_591443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_591457.validator(path, query, header, formData, body)
  let scheme = call_591457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591457.url(scheme.get, call_591457.host, call_591457.base,
                         call_591457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591457, url, valid)

proc call*(call_591458: Call_PostGetMetricWidgetImage_591443; MetricWidget: string;
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
  var query_591459 = newJObject()
  var formData_591460 = newJObject()
  add(formData_591460, "MetricWidget", newJString(MetricWidget))
  add(formData_591460, "OutputFormat", newJString(OutputFormat))
  add(query_591459, "Action", newJString(Action))
  add(query_591459, "Version", newJString(Version))
  result = call_591458.call(nil, query_591459, nil, formData_591460, nil)

var postGetMetricWidgetImage* = Call_PostGetMetricWidgetImage_591443(
    name: "postGetMetricWidgetImage", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_PostGetMetricWidgetImage_591444, base: "/",
    url: url_PostGetMetricWidgetImage_591445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricWidgetImage_591426 = ref object of OpenApiRestCall_590364
proc url_GetGetMetricWidgetImage_591428(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetMetricWidgetImage_591427(path: JsonNode; query: JsonNode;
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
  var valid_591429 = query.getOrDefault("OutputFormat")
  valid_591429 = validateParameter(valid_591429, JString, required = false,
                                 default = nil)
  if valid_591429 != nil:
    section.add "OutputFormat", valid_591429
  assert query != nil,
        "query argument is necessary due to required `MetricWidget` field"
  var valid_591430 = query.getOrDefault("MetricWidget")
  valid_591430 = validateParameter(valid_591430, JString, required = true,
                                 default = nil)
  if valid_591430 != nil:
    section.add "MetricWidget", valid_591430
  var valid_591431 = query.getOrDefault("Action")
  valid_591431 = validateParameter(valid_591431, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_591431 != nil:
    section.add "Action", valid_591431
  var valid_591432 = query.getOrDefault("Version")
  valid_591432 = validateParameter(valid_591432, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591432 != nil:
    section.add "Version", valid_591432
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
  var valid_591433 = header.getOrDefault("X-Amz-Signature")
  valid_591433 = validateParameter(valid_591433, JString, required = false,
                                 default = nil)
  if valid_591433 != nil:
    section.add "X-Amz-Signature", valid_591433
  var valid_591434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591434 = validateParameter(valid_591434, JString, required = false,
                                 default = nil)
  if valid_591434 != nil:
    section.add "X-Amz-Content-Sha256", valid_591434
  var valid_591435 = header.getOrDefault("X-Amz-Date")
  valid_591435 = validateParameter(valid_591435, JString, required = false,
                                 default = nil)
  if valid_591435 != nil:
    section.add "X-Amz-Date", valid_591435
  var valid_591436 = header.getOrDefault("X-Amz-Credential")
  valid_591436 = validateParameter(valid_591436, JString, required = false,
                                 default = nil)
  if valid_591436 != nil:
    section.add "X-Amz-Credential", valid_591436
  var valid_591437 = header.getOrDefault("X-Amz-Security-Token")
  valid_591437 = validateParameter(valid_591437, JString, required = false,
                                 default = nil)
  if valid_591437 != nil:
    section.add "X-Amz-Security-Token", valid_591437
  var valid_591438 = header.getOrDefault("X-Amz-Algorithm")
  valid_591438 = validateParameter(valid_591438, JString, required = false,
                                 default = nil)
  if valid_591438 != nil:
    section.add "X-Amz-Algorithm", valid_591438
  var valid_591439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591439 = validateParameter(valid_591439, JString, required = false,
                                 default = nil)
  if valid_591439 != nil:
    section.add "X-Amz-SignedHeaders", valid_591439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591440: Call_GetGetMetricWidgetImage_591426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_591440.validator(path, query, header, formData, body)
  let scheme = call_591440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591440.url(scheme.get, call_591440.host, call_591440.base,
                         call_591440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591440, url, valid)

proc call*(call_591441: Call_GetGetMetricWidgetImage_591426; MetricWidget: string;
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
  var query_591442 = newJObject()
  add(query_591442, "OutputFormat", newJString(OutputFormat))
  add(query_591442, "MetricWidget", newJString(MetricWidget))
  add(query_591442, "Action", newJString(Action))
  add(query_591442, "Version", newJString(Version))
  result = call_591441.call(nil, query_591442, nil, nil, nil)

var getGetMetricWidgetImage* = Call_GetGetMetricWidgetImage_591426(
    name: "getGetMetricWidgetImage", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_GetGetMetricWidgetImage_591427, base: "/",
    url: url_GetGetMetricWidgetImage_591428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDashboards_591478 = ref object of OpenApiRestCall_590364
proc url_PostListDashboards_591480(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListDashboards_591479(path: JsonNode; query: JsonNode;
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
  var valid_591481 = query.getOrDefault("Action")
  valid_591481 = validateParameter(valid_591481, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_591481 != nil:
    section.add "Action", valid_591481
  var valid_591482 = query.getOrDefault("Version")
  valid_591482 = validateParameter(valid_591482, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591482 != nil:
    section.add "Version", valid_591482
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
  var valid_591483 = header.getOrDefault("X-Amz-Signature")
  valid_591483 = validateParameter(valid_591483, JString, required = false,
                                 default = nil)
  if valid_591483 != nil:
    section.add "X-Amz-Signature", valid_591483
  var valid_591484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591484 = validateParameter(valid_591484, JString, required = false,
                                 default = nil)
  if valid_591484 != nil:
    section.add "X-Amz-Content-Sha256", valid_591484
  var valid_591485 = header.getOrDefault("X-Amz-Date")
  valid_591485 = validateParameter(valid_591485, JString, required = false,
                                 default = nil)
  if valid_591485 != nil:
    section.add "X-Amz-Date", valid_591485
  var valid_591486 = header.getOrDefault("X-Amz-Credential")
  valid_591486 = validateParameter(valid_591486, JString, required = false,
                                 default = nil)
  if valid_591486 != nil:
    section.add "X-Amz-Credential", valid_591486
  var valid_591487 = header.getOrDefault("X-Amz-Security-Token")
  valid_591487 = validateParameter(valid_591487, JString, required = false,
                                 default = nil)
  if valid_591487 != nil:
    section.add "X-Amz-Security-Token", valid_591487
  var valid_591488 = header.getOrDefault("X-Amz-Algorithm")
  valid_591488 = validateParameter(valid_591488, JString, required = false,
                                 default = nil)
  if valid_591488 != nil:
    section.add "X-Amz-Algorithm", valid_591488
  var valid_591489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591489 = validateParameter(valid_591489, JString, required = false,
                                 default = nil)
  if valid_591489 != nil:
    section.add "X-Amz-SignedHeaders", valid_591489
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   DashboardNamePrefix: JString
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  section = newJObject()
  var valid_591490 = formData.getOrDefault("NextToken")
  valid_591490 = validateParameter(valid_591490, JString, required = false,
                                 default = nil)
  if valid_591490 != nil:
    section.add "NextToken", valid_591490
  var valid_591491 = formData.getOrDefault("DashboardNamePrefix")
  valid_591491 = validateParameter(valid_591491, JString, required = false,
                                 default = nil)
  if valid_591491 != nil:
    section.add "DashboardNamePrefix", valid_591491
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591492: Call_PostListDashboards_591478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_591492.validator(path, query, header, formData, body)
  let scheme = call_591492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591492.url(scheme.get, call_591492.host, call_591492.base,
                         call_591492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591492, url, valid)

proc call*(call_591493: Call_PostListDashboards_591478; NextToken: string = "";
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
  var query_591494 = newJObject()
  var formData_591495 = newJObject()
  add(formData_591495, "NextToken", newJString(NextToken))
  add(formData_591495, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_591494, "Action", newJString(Action))
  add(query_591494, "Version", newJString(Version))
  result = call_591493.call(nil, query_591494, nil, formData_591495, nil)

var postListDashboards* = Call_PostListDashboards_591478(
    name: "postListDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListDashboards",
    validator: validate_PostListDashboards_591479, base: "/",
    url: url_PostListDashboards_591480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDashboards_591461 = ref object of OpenApiRestCall_590364
proc url_GetListDashboards_591463(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListDashboards_591462(path: JsonNode; query: JsonNode;
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
  var valid_591464 = query.getOrDefault("DashboardNamePrefix")
  valid_591464 = validateParameter(valid_591464, JString, required = false,
                                 default = nil)
  if valid_591464 != nil:
    section.add "DashboardNamePrefix", valid_591464
  var valid_591465 = query.getOrDefault("NextToken")
  valid_591465 = validateParameter(valid_591465, JString, required = false,
                                 default = nil)
  if valid_591465 != nil:
    section.add "NextToken", valid_591465
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_591466 = query.getOrDefault("Action")
  valid_591466 = validateParameter(valid_591466, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_591466 != nil:
    section.add "Action", valid_591466
  var valid_591467 = query.getOrDefault("Version")
  valid_591467 = validateParameter(valid_591467, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591467 != nil:
    section.add "Version", valid_591467
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
  var valid_591468 = header.getOrDefault("X-Amz-Signature")
  valid_591468 = validateParameter(valid_591468, JString, required = false,
                                 default = nil)
  if valid_591468 != nil:
    section.add "X-Amz-Signature", valid_591468
  var valid_591469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591469 = validateParameter(valid_591469, JString, required = false,
                                 default = nil)
  if valid_591469 != nil:
    section.add "X-Amz-Content-Sha256", valid_591469
  var valid_591470 = header.getOrDefault("X-Amz-Date")
  valid_591470 = validateParameter(valid_591470, JString, required = false,
                                 default = nil)
  if valid_591470 != nil:
    section.add "X-Amz-Date", valid_591470
  var valid_591471 = header.getOrDefault("X-Amz-Credential")
  valid_591471 = validateParameter(valid_591471, JString, required = false,
                                 default = nil)
  if valid_591471 != nil:
    section.add "X-Amz-Credential", valid_591471
  var valid_591472 = header.getOrDefault("X-Amz-Security-Token")
  valid_591472 = validateParameter(valid_591472, JString, required = false,
                                 default = nil)
  if valid_591472 != nil:
    section.add "X-Amz-Security-Token", valid_591472
  var valid_591473 = header.getOrDefault("X-Amz-Algorithm")
  valid_591473 = validateParameter(valid_591473, JString, required = false,
                                 default = nil)
  if valid_591473 != nil:
    section.add "X-Amz-Algorithm", valid_591473
  var valid_591474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591474 = validateParameter(valid_591474, JString, required = false,
                                 default = nil)
  if valid_591474 != nil:
    section.add "X-Amz-SignedHeaders", valid_591474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591475: Call_GetListDashboards_591461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_591475.validator(path, query, header, formData, body)
  let scheme = call_591475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591475.url(scheme.get, call_591475.host, call_591475.base,
                         call_591475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591475, url, valid)

proc call*(call_591476: Call_GetListDashboards_591461;
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
  var query_591477 = newJObject()
  add(query_591477, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_591477, "NextToken", newJString(NextToken))
  add(query_591477, "Action", newJString(Action))
  add(query_591477, "Version", newJString(Version))
  result = call_591476.call(nil, query_591477, nil, nil, nil)

var getListDashboards* = Call_GetListDashboards_591461(name: "getListDashboards",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListDashboards", validator: validate_GetListDashboards_591462,
    base: "/", url: url_GetListDashboards_591463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListMetrics_591515 = ref object of OpenApiRestCall_590364
proc url_PostListMetrics_591517(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListMetrics_591516(path: JsonNode; query: JsonNode;
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
  var valid_591518 = query.getOrDefault("Action")
  valid_591518 = validateParameter(valid_591518, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_591518 != nil:
    section.add "Action", valid_591518
  var valid_591519 = query.getOrDefault("Version")
  valid_591519 = validateParameter(valid_591519, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591519 != nil:
    section.add "Version", valid_591519
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
  var valid_591520 = header.getOrDefault("X-Amz-Signature")
  valid_591520 = validateParameter(valid_591520, JString, required = false,
                                 default = nil)
  if valid_591520 != nil:
    section.add "X-Amz-Signature", valid_591520
  var valid_591521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591521 = validateParameter(valid_591521, JString, required = false,
                                 default = nil)
  if valid_591521 != nil:
    section.add "X-Amz-Content-Sha256", valid_591521
  var valid_591522 = header.getOrDefault("X-Amz-Date")
  valid_591522 = validateParameter(valid_591522, JString, required = false,
                                 default = nil)
  if valid_591522 != nil:
    section.add "X-Amz-Date", valid_591522
  var valid_591523 = header.getOrDefault("X-Amz-Credential")
  valid_591523 = validateParameter(valid_591523, JString, required = false,
                                 default = nil)
  if valid_591523 != nil:
    section.add "X-Amz-Credential", valid_591523
  var valid_591524 = header.getOrDefault("X-Amz-Security-Token")
  valid_591524 = validateParameter(valid_591524, JString, required = false,
                                 default = nil)
  if valid_591524 != nil:
    section.add "X-Amz-Security-Token", valid_591524
  var valid_591525 = header.getOrDefault("X-Amz-Algorithm")
  valid_591525 = validateParameter(valid_591525, JString, required = false,
                                 default = nil)
  if valid_591525 != nil:
    section.add "X-Amz-Algorithm", valid_591525
  var valid_591526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591526 = validateParameter(valid_591526, JString, required = false,
                                 default = nil)
  if valid_591526 != nil:
    section.add "X-Amz-SignedHeaders", valid_591526
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
  var valid_591527 = formData.getOrDefault("NextToken")
  valid_591527 = validateParameter(valid_591527, JString, required = false,
                                 default = nil)
  if valid_591527 != nil:
    section.add "NextToken", valid_591527
  var valid_591528 = formData.getOrDefault("MetricName")
  valid_591528 = validateParameter(valid_591528, JString, required = false,
                                 default = nil)
  if valid_591528 != nil:
    section.add "MetricName", valid_591528
  var valid_591529 = formData.getOrDefault("Dimensions")
  valid_591529 = validateParameter(valid_591529, JArray, required = false,
                                 default = nil)
  if valid_591529 != nil:
    section.add "Dimensions", valid_591529
  var valid_591530 = formData.getOrDefault("Namespace")
  valid_591530 = validateParameter(valid_591530, JString, required = false,
                                 default = nil)
  if valid_591530 != nil:
    section.add "Namespace", valid_591530
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591531: Call_PostListMetrics_591515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_591531.validator(path, query, header, formData, body)
  let scheme = call_591531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591531.url(scheme.get, call_591531.host, call_591531.base,
                         call_591531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591531, url, valid)

proc call*(call_591532: Call_PostListMetrics_591515; NextToken: string = "";
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
  var query_591533 = newJObject()
  var formData_591534 = newJObject()
  add(formData_591534, "NextToken", newJString(NextToken))
  add(formData_591534, "MetricName", newJString(MetricName))
  add(query_591533, "Action", newJString(Action))
  if Dimensions != nil:
    formData_591534.add "Dimensions", Dimensions
  add(formData_591534, "Namespace", newJString(Namespace))
  add(query_591533, "Version", newJString(Version))
  result = call_591532.call(nil, query_591533, nil, formData_591534, nil)

var postListMetrics* = Call_PostListMetrics_591515(name: "postListMetrics",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_PostListMetrics_591516,
    base: "/", url: url_PostListMetrics_591517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListMetrics_591496 = ref object of OpenApiRestCall_590364
proc url_GetListMetrics_591498(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListMetrics_591497(path: JsonNode; query: JsonNode;
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
  var valid_591499 = query.getOrDefault("NextToken")
  valid_591499 = validateParameter(valid_591499, JString, required = false,
                                 default = nil)
  if valid_591499 != nil:
    section.add "NextToken", valid_591499
  var valid_591500 = query.getOrDefault("Namespace")
  valid_591500 = validateParameter(valid_591500, JString, required = false,
                                 default = nil)
  if valid_591500 != nil:
    section.add "Namespace", valid_591500
  var valid_591501 = query.getOrDefault("Dimensions")
  valid_591501 = validateParameter(valid_591501, JArray, required = false,
                                 default = nil)
  if valid_591501 != nil:
    section.add "Dimensions", valid_591501
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_591502 = query.getOrDefault("Action")
  valid_591502 = validateParameter(valid_591502, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_591502 != nil:
    section.add "Action", valid_591502
  var valid_591503 = query.getOrDefault("Version")
  valid_591503 = validateParameter(valid_591503, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591503 != nil:
    section.add "Version", valid_591503
  var valid_591504 = query.getOrDefault("MetricName")
  valid_591504 = validateParameter(valid_591504, JString, required = false,
                                 default = nil)
  if valid_591504 != nil:
    section.add "MetricName", valid_591504
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
  var valid_591505 = header.getOrDefault("X-Amz-Signature")
  valid_591505 = validateParameter(valid_591505, JString, required = false,
                                 default = nil)
  if valid_591505 != nil:
    section.add "X-Amz-Signature", valid_591505
  var valid_591506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591506 = validateParameter(valid_591506, JString, required = false,
                                 default = nil)
  if valid_591506 != nil:
    section.add "X-Amz-Content-Sha256", valid_591506
  var valid_591507 = header.getOrDefault("X-Amz-Date")
  valid_591507 = validateParameter(valid_591507, JString, required = false,
                                 default = nil)
  if valid_591507 != nil:
    section.add "X-Amz-Date", valid_591507
  var valid_591508 = header.getOrDefault("X-Amz-Credential")
  valid_591508 = validateParameter(valid_591508, JString, required = false,
                                 default = nil)
  if valid_591508 != nil:
    section.add "X-Amz-Credential", valid_591508
  var valid_591509 = header.getOrDefault("X-Amz-Security-Token")
  valid_591509 = validateParameter(valid_591509, JString, required = false,
                                 default = nil)
  if valid_591509 != nil:
    section.add "X-Amz-Security-Token", valid_591509
  var valid_591510 = header.getOrDefault("X-Amz-Algorithm")
  valid_591510 = validateParameter(valid_591510, JString, required = false,
                                 default = nil)
  if valid_591510 != nil:
    section.add "X-Amz-Algorithm", valid_591510
  var valid_591511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591511 = validateParameter(valid_591511, JString, required = false,
                                 default = nil)
  if valid_591511 != nil:
    section.add "X-Amz-SignedHeaders", valid_591511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591512: Call_GetListMetrics_591496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_591512.validator(path, query, header, formData, body)
  let scheme = call_591512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591512.url(scheme.get, call_591512.host, call_591512.base,
                         call_591512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591512, url, valid)

proc call*(call_591513: Call_GetListMetrics_591496; NextToken: string = "";
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
  var query_591514 = newJObject()
  add(query_591514, "NextToken", newJString(NextToken))
  add(query_591514, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_591514.add "Dimensions", Dimensions
  add(query_591514, "Action", newJString(Action))
  add(query_591514, "Version", newJString(Version))
  add(query_591514, "MetricName", newJString(MetricName))
  result = call_591513.call(nil, query_591514, nil, nil, nil)

var getListMetrics* = Call_GetListMetrics_591496(name: "getListMetrics",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_GetListMetrics_591497,
    base: "/", url: url_GetListMetrics_591498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_591551 = ref object of OpenApiRestCall_590364
proc url_PostListTagsForResource_591553(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_591552(path: JsonNode; query: JsonNode;
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
  var valid_591554 = query.getOrDefault("Action")
  valid_591554 = validateParameter(valid_591554, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_591554 != nil:
    section.add "Action", valid_591554
  var valid_591555 = query.getOrDefault("Version")
  valid_591555 = validateParameter(valid_591555, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591555 != nil:
    section.add "Version", valid_591555
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
  var valid_591556 = header.getOrDefault("X-Amz-Signature")
  valid_591556 = validateParameter(valid_591556, JString, required = false,
                                 default = nil)
  if valid_591556 != nil:
    section.add "X-Amz-Signature", valid_591556
  var valid_591557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591557 = validateParameter(valid_591557, JString, required = false,
                                 default = nil)
  if valid_591557 != nil:
    section.add "X-Amz-Content-Sha256", valid_591557
  var valid_591558 = header.getOrDefault("X-Amz-Date")
  valid_591558 = validateParameter(valid_591558, JString, required = false,
                                 default = nil)
  if valid_591558 != nil:
    section.add "X-Amz-Date", valid_591558
  var valid_591559 = header.getOrDefault("X-Amz-Credential")
  valid_591559 = validateParameter(valid_591559, JString, required = false,
                                 default = nil)
  if valid_591559 != nil:
    section.add "X-Amz-Credential", valid_591559
  var valid_591560 = header.getOrDefault("X-Amz-Security-Token")
  valid_591560 = validateParameter(valid_591560, JString, required = false,
                                 default = nil)
  if valid_591560 != nil:
    section.add "X-Amz-Security-Token", valid_591560
  var valid_591561 = header.getOrDefault("X-Amz-Algorithm")
  valid_591561 = validateParameter(valid_591561, JString, required = false,
                                 default = nil)
  if valid_591561 != nil:
    section.add "X-Amz-Algorithm", valid_591561
  var valid_591562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591562 = validateParameter(valid_591562, JString, required = false,
                                 default = nil)
  if valid_591562 != nil:
    section.add "X-Amz-SignedHeaders", valid_591562
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceARN` field"
  var valid_591563 = formData.getOrDefault("ResourceARN")
  valid_591563 = validateParameter(valid_591563, JString, required = true,
                                 default = nil)
  if valid_591563 != nil:
    section.add "ResourceARN", valid_591563
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591564: Call_PostListTagsForResource_591551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_591564.validator(path, query, header, formData, body)
  let scheme = call_591564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591564.url(scheme.get, call_591564.host, call_591564.base,
                         call_591564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591564, url, valid)

proc call*(call_591565: Call_PostListTagsForResource_591551; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## postListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  var query_591566 = newJObject()
  var formData_591567 = newJObject()
  add(query_591566, "Action", newJString(Action))
  add(query_591566, "Version", newJString(Version))
  add(formData_591567, "ResourceARN", newJString(ResourceARN))
  result = call_591565.call(nil, query_591566, nil, formData_591567, nil)

var postListTagsForResource* = Call_PostListTagsForResource_591551(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_591552, base: "/",
    url: url_PostListTagsForResource_591553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_591535 = ref object of OpenApiRestCall_590364
proc url_GetListTagsForResource_591537(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_591536(path: JsonNode; query: JsonNode;
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
  var valid_591538 = query.getOrDefault("Action")
  valid_591538 = validateParameter(valid_591538, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_591538 != nil:
    section.add "Action", valid_591538
  var valid_591539 = query.getOrDefault("ResourceARN")
  valid_591539 = validateParameter(valid_591539, JString, required = true,
                                 default = nil)
  if valid_591539 != nil:
    section.add "ResourceARN", valid_591539
  var valid_591540 = query.getOrDefault("Version")
  valid_591540 = validateParameter(valid_591540, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591540 != nil:
    section.add "Version", valid_591540
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
  var valid_591541 = header.getOrDefault("X-Amz-Signature")
  valid_591541 = validateParameter(valid_591541, JString, required = false,
                                 default = nil)
  if valid_591541 != nil:
    section.add "X-Amz-Signature", valid_591541
  var valid_591542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591542 = validateParameter(valid_591542, JString, required = false,
                                 default = nil)
  if valid_591542 != nil:
    section.add "X-Amz-Content-Sha256", valid_591542
  var valid_591543 = header.getOrDefault("X-Amz-Date")
  valid_591543 = validateParameter(valid_591543, JString, required = false,
                                 default = nil)
  if valid_591543 != nil:
    section.add "X-Amz-Date", valid_591543
  var valid_591544 = header.getOrDefault("X-Amz-Credential")
  valid_591544 = validateParameter(valid_591544, JString, required = false,
                                 default = nil)
  if valid_591544 != nil:
    section.add "X-Amz-Credential", valid_591544
  var valid_591545 = header.getOrDefault("X-Amz-Security-Token")
  valid_591545 = validateParameter(valid_591545, JString, required = false,
                                 default = nil)
  if valid_591545 != nil:
    section.add "X-Amz-Security-Token", valid_591545
  var valid_591546 = header.getOrDefault("X-Amz-Algorithm")
  valid_591546 = validateParameter(valid_591546, JString, required = false,
                                 default = nil)
  if valid_591546 != nil:
    section.add "X-Amz-Algorithm", valid_591546
  var valid_591547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591547 = validateParameter(valid_591547, JString, required = false,
                                 default = nil)
  if valid_591547 != nil:
    section.add "X-Amz-SignedHeaders", valid_591547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591548: Call_GetListTagsForResource_591535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_591548.validator(path, query, header, formData, body)
  let scheme = call_591548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591548.url(scheme.get, call_591548.host, call_591548.base,
                         call_591548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591548, url, valid)

proc call*(call_591549: Call_GetListTagsForResource_591535; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## getListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_591550 = newJObject()
  add(query_591550, "Action", newJString(Action))
  add(query_591550, "ResourceARN", newJString(ResourceARN))
  add(query_591550, "Version", newJString(Version))
  result = call_591549.call(nil, query_591550, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_591535(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_591536, base: "/",
    url: url_GetListTagsForResource_591537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAnomalyDetector_591589 = ref object of OpenApiRestCall_590364
proc url_PostPutAnomalyDetector_591591(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutAnomalyDetector_591590(path: JsonNode; query: JsonNode;
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
  var valid_591592 = query.getOrDefault("Action")
  valid_591592 = validateParameter(valid_591592, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_591592 != nil:
    section.add "Action", valid_591592
  var valid_591593 = query.getOrDefault("Version")
  valid_591593 = validateParameter(valid_591593, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591593 != nil:
    section.add "Version", valid_591593
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
  var valid_591594 = header.getOrDefault("X-Amz-Signature")
  valid_591594 = validateParameter(valid_591594, JString, required = false,
                                 default = nil)
  if valid_591594 != nil:
    section.add "X-Amz-Signature", valid_591594
  var valid_591595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591595 = validateParameter(valid_591595, JString, required = false,
                                 default = nil)
  if valid_591595 != nil:
    section.add "X-Amz-Content-Sha256", valid_591595
  var valid_591596 = header.getOrDefault("X-Amz-Date")
  valid_591596 = validateParameter(valid_591596, JString, required = false,
                                 default = nil)
  if valid_591596 != nil:
    section.add "X-Amz-Date", valid_591596
  var valid_591597 = header.getOrDefault("X-Amz-Credential")
  valid_591597 = validateParameter(valid_591597, JString, required = false,
                                 default = nil)
  if valid_591597 != nil:
    section.add "X-Amz-Credential", valid_591597
  var valid_591598 = header.getOrDefault("X-Amz-Security-Token")
  valid_591598 = validateParameter(valid_591598, JString, required = false,
                                 default = nil)
  if valid_591598 != nil:
    section.add "X-Amz-Security-Token", valid_591598
  var valid_591599 = header.getOrDefault("X-Amz-Algorithm")
  valid_591599 = validateParameter(valid_591599, JString, required = false,
                                 default = nil)
  if valid_591599 != nil:
    section.add "X-Amz-Algorithm", valid_591599
  var valid_591600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591600 = validateParameter(valid_591600, JString, required = false,
                                 default = nil)
  if valid_591600 != nil:
    section.add "X-Amz-SignedHeaders", valid_591600
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
  var valid_591601 = formData.getOrDefault("Stat")
  valid_591601 = validateParameter(valid_591601, JString, required = true,
                                 default = nil)
  if valid_591601 != nil:
    section.add "Stat", valid_591601
  var valid_591602 = formData.getOrDefault("Configuration.MetricTimezone")
  valid_591602 = validateParameter(valid_591602, JString, required = false,
                                 default = nil)
  if valid_591602 != nil:
    section.add "Configuration.MetricTimezone", valid_591602
  var valid_591603 = formData.getOrDefault("MetricName")
  valid_591603 = validateParameter(valid_591603, JString, required = true,
                                 default = nil)
  if valid_591603 != nil:
    section.add "MetricName", valid_591603
  var valid_591604 = formData.getOrDefault("Dimensions")
  valid_591604 = validateParameter(valid_591604, JArray, required = false,
                                 default = nil)
  if valid_591604 != nil:
    section.add "Dimensions", valid_591604
  var valid_591605 = formData.getOrDefault("Namespace")
  valid_591605 = validateParameter(valid_591605, JString, required = true,
                                 default = nil)
  if valid_591605 != nil:
    section.add "Namespace", valid_591605
  var valid_591606 = formData.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_591606 = validateParameter(valid_591606, JArray, required = false,
                                 default = nil)
  if valid_591606 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_591606
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591607: Call_PostPutAnomalyDetector_591589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_591607.validator(path, query, header, formData, body)
  let scheme = call_591607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591607.url(scheme.get, call_591607.host, call_591607.base,
                         call_591607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591607, url, valid)

proc call*(call_591608: Call_PostPutAnomalyDetector_591589; Stat: string;
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
  var query_591609 = newJObject()
  var formData_591610 = newJObject()
  add(formData_591610, "Stat", newJString(Stat))
  add(formData_591610, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  add(formData_591610, "MetricName", newJString(MetricName))
  add(query_591609, "Action", newJString(Action))
  if Dimensions != nil:
    formData_591610.add "Dimensions", Dimensions
  add(formData_591610, "Namespace", newJString(Namespace))
  if ConfigurationExcludedTimeRanges != nil:
    formData_591610.add "Configuration.ExcludedTimeRanges",
                       ConfigurationExcludedTimeRanges
  add(query_591609, "Version", newJString(Version))
  result = call_591608.call(nil, query_591609, nil, formData_591610, nil)

var postPutAnomalyDetector* = Call_PostPutAnomalyDetector_591589(
    name: "postPutAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_PostPutAnomalyDetector_591590, base: "/",
    url: url_PostPutAnomalyDetector_591591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAnomalyDetector_591568 = ref object of OpenApiRestCall_590364
proc url_GetPutAnomalyDetector_591570(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutAnomalyDetector_591569(path: JsonNode; query: JsonNode;
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
  var valid_591571 = query.getOrDefault("Namespace")
  valid_591571 = validateParameter(valid_591571, JString, required = true,
                                 default = nil)
  if valid_591571 != nil:
    section.add "Namespace", valid_591571
  var valid_591572 = query.getOrDefault("Configuration.MetricTimezone")
  valid_591572 = validateParameter(valid_591572, JString, required = false,
                                 default = nil)
  if valid_591572 != nil:
    section.add "Configuration.MetricTimezone", valid_591572
  var valid_591573 = query.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_591573 = validateParameter(valid_591573, JArray, required = false,
                                 default = nil)
  if valid_591573 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_591573
  var valid_591574 = query.getOrDefault("Dimensions")
  valid_591574 = validateParameter(valid_591574, JArray, required = false,
                                 default = nil)
  if valid_591574 != nil:
    section.add "Dimensions", valid_591574
  var valid_591575 = query.getOrDefault("Action")
  valid_591575 = validateParameter(valid_591575, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_591575 != nil:
    section.add "Action", valid_591575
  var valid_591576 = query.getOrDefault("Version")
  valid_591576 = validateParameter(valid_591576, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591576 != nil:
    section.add "Version", valid_591576
  var valid_591577 = query.getOrDefault("MetricName")
  valid_591577 = validateParameter(valid_591577, JString, required = true,
                                 default = nil)
  if valid_591577 != nil:
    section.add "MetricName", valid_591577
  var valid_591578 = query.getOrDefault("Stat")
  valid_591578 = validateParameter(valid_591578, JString, required = true,
                                 default = nil)
  if valid_591578 != nil:
    section.add "Stat", valid_591578
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
  var valid_591579 = header.getOrDefault("X-Amz-Signature")
  valid_591579 = validateParameter(valid_591579, JString, required = false,
                                 default = nil)
  if valid_591579 != nil:
    section.add "X-Amz-Signature", valid_591579
  var valid_591580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591580 = validateParameter(valid_591580, JString, required = false,
                                 default = nil)
  if valid_591580 != nil:
    section.add "X-Amz-Content-Sha256", valid_591580
  var valid_591581 = header.getOrDefault("X-Amz-Date")
  valid_591581 = validateParameter(valid_591581, JString, required = false,
                                 default = nil)
  if valid_591581 != nil:
    section.add "X-Amz-Date", valid_591581
  var valid_591582 = header.getOrDefault("X-Amz-Credential")
  valid_591582 = validateParameter(valid_591582, JString, required = false,
                                 default = nil)
  if valid_591582 != nil:
    section.add "X-Amz-Credential", valid_591582
  var valid_591583 = header.getOrDefault("X-Amz-Security-Token")
  valid_591583 = validateParameter(valid_591583, JString, required = false,
                                 default = nil)
  if valid_591583 != nil:
    section.add "X-Amz-Security-Token", valid_591583
  var valid_591584 = header.getOrDefault("X-Amz-Algorithm")
  valid_591584 = validateParameter(valid_591584, JString, required = false,
                                 default = nil)
  if valid_591584 != nil:
    section.add "X-Amz-Algorithm", valid_591584
  var valid_591585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591585 = validateParameter(valid_591585, JString, required = false,
                                 default = nil)
  if valid_591585 != nil:
    section.add "X-Amz-SignedHeaders", valid_591585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591586: Call_GetPutAnomalyDetector_591568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_591586.validator(path, query, header, formData, body)
  let scheme = call_591586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591586.url(scheme.get, call_591586.host, call_591586.base,
                         call_591586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591586, url, valid)

proc call*(call_591587: Call_GetPutAnomalyDetector_591568; Namespace: string;
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
  var query_591588 = newJObject()
  add(query_591588, "Namespace", newJString(Namespace))
  add(query_591588, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  if ConfigurationExcludedTimeRanges != nil:
    query_591588.add "Configuration.ExcludedTimeRanges",
                    ConfigurationExcludedTimeRanges
  if Dimensions != nil:
    query_591588.add "Dimensions", Dimensions
  add(query_591588, "Action", newJString(Action))
  add(query_591588, "Version", newJString(Version))
  add(query_591588, "MetricName", newJString(MetricName))
  add(query_591588, "Stat", newJString(Stat))
  result = call_591587.call(nil, query_591588, nil, nil, nil)

var getPutAnomalyDetector* = Call_GetPutAnomalyDetector_591568(
    name: "getPutAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_GetPutAnomalyDetector_591569, base: "/",
    url: url_GetPutAnomalyDetector_591570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutDashboard_591628 = ref object of OpenApiRestCall_590364
proc url_PostPutDashboard_591630(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutDashboard_591629(path: JsonNode; query: JsonNode;
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
  var valid_591631 = query.getOrDefault("Action")
  valid_591631 = validateParameter(valid_591631, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_591631 != nil:
    section.add "Action", valid_591631
  var valid_591632 = query.getOrDefault("Version")
  valid_591632 = validateParameter(valid_591632, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591632 != nil:
    section.add "Version", valid_591632
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
  var valid_591633 = header.getOrDefault("X-Amz-Signature")
  valid_591633 = validateParameter(valid_591633, JString, required = false,
                                 default = nil)
  if valid_591633 != nil:
    section.add "X-Amz-Signature", valid_591633
  var valid_591634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591634 = validateParameter(valid_591634, JString, required = false,
                                 default = nil)
  if valid_591634 != nil:
    section.add "X-Amz-Content-Sha256", valid_591634
  var valid_591635 = header.getOrDefault("X-Amz-Date")
  valid_591635 = validateParameter(valid_591635, JString, required = false,
                                 default = nil)
  if valid_591635 != nil:
    section.add "X-Amz-Date", valid_591635
  var valid_591636 = header.getOrDefault("X-Amz-Credential")
  valid_591636 = validateParameter(valid_591636, JString, required = false,
                                 default = nil)
  if valid_591636 != nil:
    section.add "X-Amz-Credential", valid_591636
  var valid_591637 = header.getOrDefault("X-Amz-Security-Token")
  valid_591637 = validateParameter(valid_591637, JString, required = false,
                                 default = nil)
  if valid_591637 != nil:
    section.add "X-Amz-Security-Token", valid_591637
  var valid_591638 = header.getOrDefault("X-Amz-Algorithm")
  valid_591638 = validateParameter(valid_591638, JString, required = false,
                                 default = nil)
  if valid_591638 != nil:
    section.add "X-Amz-Algorithm", valid_591638
  var valid_591639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591639 = validateParameter(valid_591639, JString, required = false,
                                 default = nil)
  if valid_591639 != nil:
    section.add "X-Amz-SignedHeaders", valid_591639
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_591640 = formData.getOrDefault("DashboardName")
  valid_591640 = validateParameter(valid_591640, JString, required = true,
                                 default = nil)
  if valid_591640 != nil:
    section.add "DashboardName", valid_591640
  var valid_591641 = formData.getOrDefault("DashboardBody")
  valid_591641 = validateParameter(valid_591641, JString, required = true,
                                 default = nil)
  if valid_591641 != nil:
    section.add "DashboardBody", valid_591641
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591642: Call_PostPutDashboard_591628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_591642.validator(path, query, header, formData, body)
  let scheme = call_591642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591642.url(scheme.get, call_591642.host, call_591642.base,
                         call_591642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591642, url, valid)

proc call*(call_591643: Call_PostPutDashboard_591628; DashboardName: string;
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
  var query_591644 = newJObject()
  var formData_591645 = newJObject()
  add(formData_591645, "DashboardName", newJString(DashboardName))
  add(query_591644, "Action", newJString(Action))
  add(formData_591645, "DashboardBody", newJString(DashboardBody))
  add(query_591644, "Version", newJString(Version))
  result = call_591643.call(nil, query_591644, nil, formData_591645, nil)

var postPutDashboard* = Call_PostPutDashboard_591628(name: "postPutDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_PostPutDashboard_591629,
    base: "/", url: url_PostPutDashboard_591630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutDashboard_591611 = ref object of OpenApiRestCall_590364
proc url_GetPutDashboard_591613(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutDashboard_591612(path: JsonNode; query: JsonNode;
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
  var valid_591614 = query.getOrDefault("DashboardBody")
  valid_591614 = validateParameter(valid_591614, JString, required = true,
                                 default = nil)
  if valid_591614 != nil:
    section.add "DashboardBody", valid_591614
  var valid_591615 = query.getOrDefault("Action")
  valid_591615 = validateParameter(valid_591615, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_591615 != nil:
    section.add "Action", valid_591615
  var valid_591616 = query.getOrDefault("DashboardName")
  valid_591616 = validateParameter(valid_591616, JString, required = true,
                                 default = nil)
  if valid_591616 != nil:
    section.add "DashboardName", valid_591616
  var valid_591617 = query.getOrDefault("Version")
  valid_591617 = validateParameter(valid_591617, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591617 != nil:
    section.add "Version", valid_591617
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
  var valid_591618 = header.getOrDefault("X-Amz-Signature")
  valid_591618 = validateParameter(valid_591618, JString, required = false,
                                 default = nil)
  if valid_591618 != nil:
    section.add "X-Amz-Signature", valid_591618
  var valid_591619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591619 = validateParameter(valid_591619, JString, required = false,
                                 default = nil)
  if valid_591619 != nil:
    section.add "X-Amz-Content-Sha256", valid_591619
  var valid_591620 = header.getOrDefault("X-Amz-Date")
  valid_591620 = validateParameter(valid_591620, JString, required = false,
                                 default = nil)
  if valid_591620 != nil:
    section.add "X-Amz-Date", valid_591620
  var valid_591621 = header.getOrDefault("X-Amz-Credential")
  valid_591621 = validateParameter(valid_591621, JString, required = false,
                                 default = nil)
  if valid_591621 != nil:
    section.add "X-Amz-Credential", valid_591621
  var valid_591622 = header.getOrDefault("X-Amz-Security-Token")
  valid_591622 = validateParameter(valid_591622, JString, required = false,
                                 default = nil)
  if valid_591622 != nil:
    section.add "X-Amz-Security-Token", valid_591622
  var valid_591623 = header.getOrDefault("X-Amz-Algorithm")
  valid_591623 = validateParameter(valid_591623, JString, required = false,
                                 default = nil)
  if valid_591623 != nil:
    section.add "X-Amz-Algorithm", valid_591623
  var valid_591624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591624 = validateParameter(valid_591624, JString, required = false,
                                 default = nil)
  if valid_591624 != nil:
    section.add "X-Amz-SignedHeaders", valid_591624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591625: Call_GetPutDashboard_591611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_591625.validator(path, query, header, formData, body)
  let scheme = call_591625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591625.url(scheme.get, call_591625.host, call_591625.base,
                         call_591625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591625, url, valid)

proc call*(call_591626: Call_GetPutDashboard_591611; DashboardBody: string;
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
  var query_591627 = newJObject()
  add(query_591627, "DashboardBody", newJString(DashboardBody))
  add(query_591627, "Action", newJString(Action))
  add(query_591627, "DashboardName", newJString(DashboardName))
  add(query_591627, "Version", newJString(Version))
  result = call_591626.call(nil, query_591627, nil, nil, nil)

var getPutDashboard* = Call_GetPutDashboard_591611(name: "getPutDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_GetPutDashboard_591612,
    base: "/", url: url_GetPutDashboard_591613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricAlarm_591683 = ref object of OpenApiRestCall_590364
proc url_PostPutMetricAlarm_591685(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutMetricAlarm_591684(path: JsonNode; query: JsonNode;
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
  var valid_591686 = query.getOrDefault("Action")
  valid_591686 = validateParameter(valid_591686, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_591686 != nil:
    section.add "Action", valid_591686
  var valid_591687 = query.getOrDefault("Version")
  valid_591687 = validateParameter(valid_591687, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591687 != nil:
    section.add "Version", valid_591687
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
  var valid_591688 = header.getOrDefault("X-Amz-Signature")
  valid_591688 = validateParameter(valid_591688, JString, required = false,
                                 default = nil)
  if valid_591688 != nil:
    section.add "X-Amz-Signature", valid_591688
  var valid_591689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591689 = validateParameter(valid_591689, JString, required = false,
                                 default = nil)
  if valid_591689 != nil:
    section.add "X-Amz-Content-Sha256", valid_591689
  var valid_591690 = header.getOrDefault("X-Amz-Date")
  valid_591690 = validateParameter(valid_591690, JString, required = false,
                                 default = nil)
  if valid_591690 != nil:
    section.add "X-Amz-Date", valid_591690
  var valid_591691 = header.getOrDefault("X-Amz-Credential")
  valid_591691 = validateParameter(valid_591691, JString, required = false,
                                 default = nil)
  if valid_591691 != nil:
    section.add "X-Amz-Credential", valid_591691
  var valid_591692 = header.getOrDefault("X-Amz-Security-Token")
  valid_591692 = validateParameter(valid_591692, JString, required = false,
                                 default = nil)
  if valid_591692 != nil:
    section.add "X-Amz-Security-Token", valid_591692
  var valid_591693 = header.getOrDefault("X-Amz-Algorithm")
  valid_591693 = validateParameter(valid_591693, JString, required = false,
                                 default = nil)
  if valid_591693 != nil:
    section.add "X-Amz-Algorithm", valid_591693
  var valid_591694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591694 = validateParameter(valid_591694, JString, required = false,
                                 default = nil)
  if valid_591694 != nil:
    section.add "X-Amz-SignedHeaders", valid_591694
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
  var valid_591695 = formData.getOrDefault("ActionsEnabled")
  valid_591695 = validateParameter(valid_591695, JBool, required = false, default = nil)
  if valid_591695 != nil:
    section.add "ActionsEnabled", valid_591695
  var valid_591696 = formData.getOrDefault("AlarmDescription")
  valid_591696 = validateParameter(valid_591696, JString, required = false,
                                 default = nil)
  if valid_591696 != nil:
    section.add "AlarmDescription", valid_591696
  assert formData != nil,
        "formData argument is necessary due to required `AlarmName` field"
  var valid_591697 = formData.getOrDefault("AlarmName")
  valid_591697 = validateParameter(valid_591697, JString, required = true,
                                 default = nil)
  if valid_591697 != nil:
    section.add "AlarmName", valid_591697
  var valid_591698 = formData.getOrDefault("ThresholdMetricId")
  valid_591698 = validateParameter(valid_591698, JString, required = false,
                                 default = nil)
  if valid_591698 != nil:
    section.add "ThresholdMetricId", valid_591698
  var valid_591699 = formData.getOrDefault("Unit")
  valid_591699 = validateParameter(valid_591699, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_591699 != nil:
    section.add "Unit", valid_591699
  var valid_591700 = formData.getOrDefault("Period")
  valid_591700 = validateParameter(valid_591700, JInt, required = false, default = nil)
  if valid_591700 != nil:
    section.add "Period", valid_591700
  var valid_591701 = formData.getOrDefault("AlarmActions")
  valid_591701 = validateParameter(valid_591701, JArray, required = false,
                                 default = nil)
  if valid_591701 != nil:
    section.add "AlarmActions", valid_591701
  var valid_591702 = formData.getOrDefault("ComparisonOperator")
  valid_591702 = validateParameter(valid_591702, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_591702 != nil:
    section.add "ComparisonOperator", valid_591702
  var valid_591703 = formData.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_591703 = validateParameter(valid_591703, JString, required = false,
                                 default = nil)
  if valid_591703 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_591703
  var valid_591704 = formData.getOrDefault("OKActions")
  valid_591704 = validateParameter(valid_591704, JArray, required = false,
                                 default = nil)
  if valid_591704 != nil:
    section.add "OKActions", valid_591704
  var valid_591705 = formData.getOrDefault("Statistic")
  valid_591705 = validateParameter(valid_591705, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_591705 != nil:
    section.add "Statistic", valid_591705
  var valid_591706 = formData.getOrDefault("TreatMissingData")
  valid_591706 = validateParameter(valid_591706, JString, required = false,
                                 default = nil)
  if valid_591706 != nil:
    section.add "TreatMissingData", valid_591706
  var valid_591707 = formData.getOrDefault("InsufficientDataActions")
  valid_591707 = validateParameter(valid_591707, JArray, required = false,
                                 default = nil)
  if valid_591707 != nil:
    section.add "InsufficientDataActions", valid_591707
  var valid_591708 = formData.getOrDefault("DatapointsToAlarm")
  valid_591708 = validateParameter(valid_591708, JInt, required = false, default = nil)
  if valid_591708 != nil:
    section.add "DatapointsToAlarm", valid_591708
  var valid_591709 = formData.getOrDefault("MetricName")
  valid_591709 = validateParameter(valid_591709, JString, required = false,
                                 default = nil)
  if valid_591709 != nil:
    section.add "MetricName", valid_591709
  var valid_591710 = formData.getOrDefault("Dimensions")
  valid_591710 = validateParameter(valid_591710, JArray, required = false,
                                 default = nil)
  if valid_591710 != nil:
    section.add "Dimensions", valid_591710
  var valid_591711 = formData.getOrDefault("Tags")
  valid_591711 = validateParameter(valid_591711, JArray, required = false,
                                 default = nil)
  if valid_591711 != nil:
    section.add "Tags", valid_591711
  var valid_591712 = formData.getOrDefault("Namespace")
  valid_591712 = validateParameter(valid_591712, JString, required = false,
                                 default = nil)
  if valid_591712 != nil:
    section.add "Namespace", valid_591712
  var valid_591713 = formData.getOrDefault("ExtendedStatistic")
  valid_591713 = validateParameter(valid_591713, JString, required = false,
                                 default = nil)
  if valid_591713 != nil:
    section.add "ExtendedStatistic", valid_591713
  var valid_591714 = formData.getOrDefault("EvaluationPeriods")
  valid_591714 = validateParameter(valid_591714, JInt, required = true, default = nil)
  if valid_591714 != nil:
    section.add "EvaluationPeriods", valid_591714
  var valid_591715 = formData.getOrDefault("Threshold")
  valid_591715 = validateParameter(valid_591715, JFloat, required = false,
                                 default = nil)
  if valid_591715 != nil:
    section.add "Threshold", valid_591715
  var valid_591716 = formData.getOrDefault("Metrics")
  valid_591716 = validateParameter(valid_591716, JArray, required = false,
                                 default = nil)
  if valid_591716 != nil:
    section.add "Metrics", valid_591716
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591717: Call_PostPutMetricAlarm_591683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_591717.validator(path, query, header, formData, body)
  let scheme = call_591717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591717.url(scheme.get, call_591717.host, call_591717.base,
                         call_591717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591717, url, valid)

proc call*(call_591718: Call_PostPutMetricAlarm_591683; AlarmName: string;
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
  var query_591719 = newJObject()
  var formData_591720 = newJObject()
  add(formData_591720, "ActionsEnabled", newJBool(ActionsEnabled))
  add(formData_591720, "AlarmDescription", newJString(AlarmDescription))
  add(formData_591720, "AlarmName", newJString(AlarmName))
  add(formData_591720, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(formData_591720, "Unit", newJString(Unit))
  add(formData_591720, "Period", newJInt(Period))
  if AlarmActions != nil:
    formData_591720.add "AlarmActions", AlarmActions
  add(formData_591720, "ComparisonOperator", newJString(ComparisonOperator))
  add(formData_591720, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  if OKActions != nil:
    formData_591720.add "OKActions", OKActions
  add(formData_591720, "Statistic", newJString(Statistic))
  add(formData_591720, "TreatMissingData", newJString(TreatMissingData))
  if InsufficientDataActions != nil:
    formData_591720.add "InsufficientDataActions", InsufficientDataActions
  add(formData_591720, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(formData_591720, "MetricName", newJString(MetricName))
  add(query_591719, "Action", newJString(Action))
  if Dimensions != nil:
    formData_591720.add "Dimensions", Dimensions
  if Tags != nil:
    formData_591720.add "Tags", Tags
  add(formData_591720, "Namespace", newJString(Namespace))
  add(formData_591720, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_591719, "Version", newJString(Version))
  add(formData_591720, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(formData_591720, "Threshold", newJFloat(Threshold))
  if Metrics != nil:
    formData_591720.add "Metrics", Metrics
  result = call_591718.call(nil, query_591719, nil, formData_591720, nil)

var postPutMetricAlarm* = Call_PostPutMetricAlarm_591683(
    name: "postPutMetricAlarm", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutMetricAlarm",
    validator: validate_PostPutMetricAlarm_591684, base: "/",
    url: url_PostPutMetricAlarm_591685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricAlarm_591646 = ref object of OpenApiRestCall_590364
proc url_GetPutMetricAlarm_591648(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutMetricAlarm_591647(path: JsonNode; query: JsonNode;
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
  var valid_591649 = query.getOrDefault("InsufficientDataActions")
  valid_591649 = validateParameter(valid_591649, JArray, required = false,
                                 default = nil)
  if valid_591649 != nil:
    section.add "InsufficientDataActions", valid_591649
  var valid_591650 = query.getOrDefault("Statistic")
  valid_591650 = validateParameter(valid_591650, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_591650 != nil:
    section.add "Statistic", valid_591650
  var valid_591651 = query.getOrDefault("AlarmDescription")
  valid_591651 = validateParameter(valid_591651, JString, required = false,
                                 default = nil)
  if valid_591651 != nil:
    section.add "AlarmDescription", valid_591651
  var valid_591652 = query.getOrDefault("Unit")
  valid_591652 = validateParameter(valid_591652, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_591652 != nil:
    section.add "Unit", valid_591652
  var valid_591653 = query.getOrDefault("DatapointsToAlarm")
  valid_591653 = validateParameter(valid_591653, JInt, required = false, default = nil)
  if valid_591653 != nil:
    section.add "DatapointsToAlarm", valid_591653
  var valid_591654 = query.getOrDefault("Threshold")
  valid_591654 = validateParameter(valid_591654, JFloat, required = false,
                                 default = nil)
  if valid_591654 != nil:
    section.add "Threshold", valid_591654
  var valid_591655 = query.getOrDefault("Tags")
  valid_591655 = validateParameter(valid_591655, JArray, required = false,
                                 default = nil)
  if valid_591655 != nil:
    section.add "Tags", valid_591655
  var valid_591656 = query.getOrDefault("ThresholdMetricId")
  valid_591656 = validateParameter(valid_591656, JString, required = false,
                                 default = nil)
  if valid_591656 != nil:
    section.add "ThresholdMetricId", valid_591656
  var valid_591657 = query.getOrDefault("Namespace")
  valid_591657 = validateParameter(valid_591657, JString, required = false,
                                 default = nil)
  if valid_591657 != nil:
    section.add "Namespace", valid_591657
  var valid_591658 = query.getOrDefault("TreatMissingData")
  valid_591658 = validateParameter(valid_591658, JString, required = false,
                                 default = nil)
  if valid_591658 != nil:
    section.add "TreatMissingData", valid_591658
  var valid_591659 = query.getOrDefault("ExtendedStatistic")
  valid_591659 = validateParameter(valid_591659, JString, required = false,
                                 default = nil)
  if valid_591659 != nil:
    section.add "ExtendedStatistic", valid_591659
  var valid_591660 = query.getOrDefault("OKActions")
  valid_591660 = validateParameter(valid_591660, JArray, required = false,
                                 default = nil)
  if valid_591660 != nil:
    section.add "OKActions", valid_591660
  var valid_591661 = query.getOrDefault("Dimensions")
  valid_591661 = validateParameter(valid_591661, JArray, required = false,
                                 default = nil)
  if valid_591661 != nil:
    section.add "Dimensions", valid_591661
  var valid_591662 = query.getOrDefault("Period")
  valid_591662 = validateParameter(valid_591662, JInt, required = false, default = nil)
  if valid_591662 != nil:
    section.add "Period", valid_591662
  assert query != nil,
        "query argument is necessary due to required `AlarmName` field"
  var valid_591663 = query.getOrDefault("AlarmName")
  valid_591663 = validateParameter(valid_591663, JString, required = true,
                                 default = nil)
  if valid_591663 != nil:
    section.add "AlarmName", valid_591663
  var valid_591664 = query.getOrDefault("Action")
  valid_591664 = validateParameter(valid_591664, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_591664 != nil:
    section.add "Action", valid_591664
  var valid_591665 = query.getOrDefault("EvaluationPeriods")
  valid_591665 = validateParameter(valid_591665, JInt, required = true, default = nil)
  if valid_591665 != nil:
    section.add "EvaluationPeriods", valid_591665
  var valid_591666 = query.getOrDefault("ActionsEnabled")
  valid_591666 = validateParameter(valid_591666, JBool, required = false, default = nil)
  if valid_591666 != nil:
    section.add "ActionsEnabled", valid_591666
  var valid_591667 = query.getOrDefault("ComparisonOperator")
  valid_591667 = validateParameter(valid_591667, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_591667 != nil:
    section.add "ComparisonOperator", valid_591667
  var valid_591668 = query.getOrDefault("AlarmActions")
  valid_591668 = validateParameter(valid_591668, JArray, required = false,
                                 default = nil)
  if valid_591668 != nil:
    section.add "AlarmActions", valid_591668
  var valid_591669 = query.getOrDefault("Metrics")
  valid_591669 = validateParameter(valid_591669, JArray, required = false,
                                 default = nil)
  if valid_591669 != nil:
    section.add "Metrics", valid_591669
  var valid_591670 = query.getOrDefault("Version")
  valid_591670 = validateParameter(valid_591670, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591670 != nil:
    section.add "Version", valid_591670
  var valid_591671 = query.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_591671 = validateParameter(valid_591671, JString, required = false,
                                 default = nil)
  if valid_591671 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_591671
  var valid_591672 = query.getOrDefault("MetricName")
  valid_591672 = validateParameter(valid_591672, JString, required = false,
                                 default = nil)
  if valid_591672 != nil:
    section.add "MetricName", valid_591672
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
  var valid_591673 = header.getOrDefault("X-Amz-Signature")
  valid_591673 = validateParameter(valid_591673, JString, required = false,
                                 default = nil)
  if valid_591673 != nil:
    section.add "X-Amz-Signature", valid_591673
  var valid_591674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591674 = validateParameter(valid_591674, JString, required = false,
                                 default = nil)
  if valid_591674 != nil:
    section.add "X-Amz-Content-Sha256", valid_591674
  var valid_591675 = header.getOrDefault("X-Amz-Date")
  valid_591675 = validateParameter(valid_591675, JString, required = false,
                                 default = nil)
  if valid_591675 != nil:
    section.add "X-Amz-Date", valid_591675
  var valid_591676 = header.getOrDefault("X-Amz-Credential")
  valid_591676 = validateParameter(valid_591676, JString, required = false,
                                 default = nil)
  if valid_591676 != nil:
    section.add "X-Amz-Credential", valid_591676
  var valid_591677 = header.getOrDefault("X-Amz-Security-Token")
  valid_591677 = validateParameter(valid_591677, JString, required = false,
                                 default = nil)
  if valid_591677 != nil:
    section.add "X-Amz-Security-Token", valid_591677
  var valid_591678 = header.getOrDefault("X-Amz-Algorithm")
  valid_591678 = validateParameter(valid_591678, JString, required = false,
                                 default = nil)
  if valid_591678 != nil:
    section.add "X-Amz-Algorithm", valid_591678
  var valid_591679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591679 = validateParameter(valid_591679, JString, required = false,
                                 default = nil)
  if valid_591679 != nil:
    section.add "X-Amz-SignedHeaders", valid_591679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591680: Call_GetPutMetricAlarm_591646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_591680.validator(path, query, header, formData, body)
  let scheme = call_591680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591680.url(scheme.get, call_591680.host, call_591680.base,
                         call_591680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591680, url, valid)

proc call*(call_591681: Call_GetPutMetricAlarm_591646; AlarmName: string;
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
  var query_591682 = newJObject()
  if InsufficientDataActions != nil:
    query_591682.add "InsufficientDataActions", InsufficientDataActions
  add(query_591682, "Statistic", newJString(Statistic))
  add(query_591682, "AlarmDescription", newJString(AlarmDescription))
  add(query_591682, "Unit", newJString(Unit))
  add(query_591682, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(query_591682, "Threshold", newJFloat(Threshold))
  if Tags != nil:
    query_591682.add "Tags", Tags
  add(query_591682, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_591682, "Namespace", newJString(Namespace))
  add(query_591682, "TreatMissingData", newJString(TreatMissingData))
  add(query_591682, "ExtendedStatistic", newJString(ExtendedStatistic))
  if OKActions != nil:
    query_591682.add "OKActions", OKActions
  if Dimensions != nil:
    query_591682.add "Dimensions", Dimensions
  add(query_591682, "Period", newJInt(Period))
  add(query_591682, "AlarmName", newJString(AlarmName))
  add(query_591682, "Action", newJString(Action))
  add(query_591682, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(query_591682, "ActionsEnabled", newJBool(ActionsEnabled))
  add(query_591682, "ComparisonOperator", newJString(ComparisonOperator))
  if AlarmActions != nil:
    query_591682.add "AlarmActions", AlarmActions
  if Metrics != nil:
    query_591682.add "Metrics", Metrics
  add(query_591682, "Version", newJString(Version))
  add(query_591682, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  add(query_591682, "MetricName", newJString(MetricName))
  result = call_591681.call(nil, query_591682, nil, nil, nil)

var getPutMetricAlarm* = Call_GetPutMetricAlarm_591646(name: "getPutMetricAlarm",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricAlarm", validator: validate_GetPutMetricAlarm_591647,
    base: "/", url: url_GetPutMetricAlarm_591648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricData_591738 = ref object of OpenApiRestCall_590364
proc url_PostPutMetricData_591740(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutMetricData_591739(path: JsonNode; query: JsonNode;
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
  var valid_591741 = query.getOrDefault("Action")
  valid_591741 = validateParameter(valid_591741, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_591741 != nil:
    section.add "Action", valid_591741
  var valid_591742 = query.getOrDefault("Version")
  valid_591742 = validateParameter(valid_591742, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591742 != nil:
    section.add "Version", valid_591742
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
  var valid_591743 = header.getOrDefault("X-Amz-Signature")
  valid_591743 = validateParameter(valid_591743, JString, required = false,
                                 default = nil)
  if valid_591743 != nil:
    section.add "X-Amz-Signature", valid_591743
  var valid_591744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591744 = validateParameter(valid_591744, JString, required = false,
                                 default = nil)
  if valid_591744 != nil:
    section.add "X-Amz-Content-Sha256", valid_591744
  var valid_591745 = header.getOrDefault("X-Amz-Date")
  valid_591745 = validateParameter(valid_591745, JString, required = false,
                                 default = nil)
  if valid_591745 != nil:
    section.add "X-Amz-Date", valid_591745
  var valid_591746 = header.getOrDefault("X-Amz-Credential")
  valid_591746 = validateParameter(valid_591746, JString, required = false,
                                 default = nil)
  if valid_591746 != nil:
    section.add "X-Amz-Credential", valid_591746
  var valid_591747 = header.getOrDefault("X-Amz-Security-Token")
  valid_591747 = validateParameter(valid_591747, JString, required = false,
                                 default = nil)
  if valid_591747 != nil:
    section.add "X-Amz-Security-Token", valid_591747
  var valid_591748 = header.getOrDefault("X-Amz-Algorithm")
  valid_591748 = validateParameter(valid_591748, JString, required = false,
                                 default = nil)
  if valid_591748 != nil:
    section.add "X-Amz-Algorithm", valid_591748
  var valid_591749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591749 = validateParameter(valid_591749, JString, required = false,
                                 default = nil)
  if valid_591749 != nil:
    section.add "X-Amz-SignedHeaders", valid_591749
  result.add "header", section
  ## parameters in `formData` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Namespace` field"
  var valid_591750 = formData.getOrDefault("Namespace")
  valid_591750 = validateParameter(valid_591750, JString, required = true,
                                 default = nil)
  if valid_591750 != nil:
    section.add "Namespace", valid_591750
  var valid_591751 = formData.getOrDefault("MetricData")
  valid_591751 = validateParameter(valid_591751, JArray, required = true, default = nil)
  if valid_591751 != nil:
    section.add "MetricData", valid_591751
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591752: Call_PostPutMetricData_591738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_591752.validator(path, query, header, formData, body)
  let scheme = call_591752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591752.url(scheme.get, call_591752.host, call_591752.base,
                         call_591752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591752, url, valid)

proc call*(call_591753: Call_PostPutMetricData_591738; Namespace: string;
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
  var query_591754 = newJObject()
  var formData_591755 = newJObject()
  add(query_591754, "Action", newJString(Action))
  add(formData_591755, "Namespace", newJString(Namespace))
  if MetricData != nil:
    formData_591755.add "MetricData", MetricData
  add(query_591754, "Version", newJString(Version))
  result = call_591753.call(nil, query_591754, nil, formData_591755, nil)

var postPutMetricData* = Call_PostPutMetricData_591738(name: "postPutMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_PostPutMetricData_591739,
    base: "/", url: url_PostPutMetricData_591740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricData_591721 = ref object of OpenApiRestCall_590364
proc url_GetPutMetricData_591723(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutMetricData_591722(path: JsonNode; query: JsonNode;
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
  var valid_591724 = query.getOrDefault("Namespace")
  valid_591724 = validateParameter(valid_591724, JString, required = true,
                                 default = nil)
  if valid_591724 != nil:
    section.add "Namespace", valid_591724
  var valid_591725 = query.getOrDefault("Action")
  valid_591725 = validateParameter(valid_591725, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_591725 != nil:
    section.add "Action", valid_591725
  var valid_591726 = query.getOrDefault("Version")
  valid_591726 = validateParameter(valid_591726, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591726 != nil:
    section.add "Version", valid_591726
  var valid_591727 = query.getOrDefault("MetricData")
  valid_591727 = validateParameter(valid_591727, JArray, required = true, default = nil)
  if valid_591727 != nil:
    section.add "MetricData", valid_591727
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
  var valid_591728 = header.getOrDefault("X-Amz-Signature")
  valid_591728 = validateParameter(valid_591728, JString, required = false,
                                 default = nil)
  if valid_591728 != nil:
    section.add "X-Amz-Signature", valid_591728
  var valid_591729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591729 = validateParameter(valid_591729, JString, required = false,
                                 default = nil)
  if valid_591729 != nil:
    section.add "X-Amz-Content-Sha256", valid_591729
  var valid_591730 = header.getOrDefault("X-Amz-Date")
  valid_591730 = validateParameter(valid_591730, JString, required = false,
                                 default = nil)
  if valid_591730 != nil:
    section.add "X-Amz-Date", valid_591730
  var valid_591731 = header.getOrDefault("X-Amz-Credential")
  valid_591731 = validateParameter(valid_591731, JString, required = false,
                                 default = nil)
  if valid_591731 != nil:
    section.add "X-Amz-Credential", valid_591731
  var valid_591732 = header.getOrDefault("X-Amz-Security-Token")
  valid_591732 = validateParameter(valid_591732, JString, required = false,
                                 default = nil)
  if valid_591732 != nil:
    section.add "X-Amz-Security-Token", valid_591732
  var valid_591733 = header.getOrDefault("X-Amz-Algorithm")
  valid_591733 = validateParameter(valid_591733, JString, required = false,
                                 default = nil)
  if valid_591733 != nil:
    section.add "X-Amz-Algorithm", valid_591733
  var valid_591734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591734 = validateParameter(valid_591734, JString, required = false,
                                 default = nil)
  if valid_591734 != nil:
    section.add "X-Amz-SignedHeaders", valid_591734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591735: Call_GetPutMetricData_591721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of 8.515920e-109 to 1.174271e+108 (Base 10) or 2e-360 to 2e360 (Base 2). In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_591735.validator(path, query, header, formData, body)
  let scheme = call_591735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591735.url(scheme.get, call_591735.host, call_591735.base,
                         call_591735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591735, url, valid)

proc call*(call_591736: Call_GetPutMetricData_591721; Namespace: string;
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
  var query_591737 = newJObject()
  add(query_591737, "Namespace", newJString(Namespace))
  add(query_591737, "Action", newJString(Action))
  add(query_591737, "Version", newJString(Version))
  if MetricData != nil:
    query_591737.add "MetricData", MetricData
  result = call_591736.call(nil, query_591737, nil, nil, nil)

var getPutMetricData* = Call_GetPutMetricData_591721(name: "getPutMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_GetPutMetricData_591722,
    base: "/", url: url_GetPutMetricData_591723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetAlarmState_591775 = ref object of OpenApiRestCall_590364
proc url_PostSetAlarmState_591777(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetAlarmState_591776(path: JsonNode; query: JsonNode;
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
  var valid_591778 = query.getOrDefault("Action")
  valid_591778 = validateParameter(valid_591778, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_591778 != nil:
    section.add "Action", valid_591778
  var valid_591779 = query.getOrDefault("Version")
  valid_591779 = validateParameter(valid_591779, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591779 != nil:
    section.add "Version", valid_591779
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
  var valid_591780 = header.getOrDefault("X-Amz-Signature")
  valid_591780 = validateParameter(valid_591780, JString, required = false,
                                 default = nil)
  if valid_591780 != nil:
    section.add "X-Amz-Signature", valid_591780
  var valid_591781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591781 = validateParameter(valid_591781, JString, required = false,
                                 default = nil)
  if valid_591781 != nil:
    section.add "X-Amz-Content-Sha256", valid_591781
  var valid_591782 = header.getOrDefault("X-Amz-Date")
  valid_591782 = validateParameter(valid_591782, JString, required = false,
                                 default = nil)
  if valid_591782 != nil:
    section.add "X-Amz-Date", valid_591782
  var valid_591783 = header.getOrDefault("X-Amz-Credential")
  valid_591783 = validateParameter(valid_591783, JString, required = false,
                                 default = nil)
  if valid_591783 != nil:
    section.add "X-Amz-Credential", valid_591783
  var valid_591784 = header.getOrDefault("X-Amz-Security-Token")
  valid_591784 = validateParameter(valid_591784, JString, required = false,
                                 default = nil)
  if valid_591784 != nil:
    section.add "X-Amz-Security-Token", valid_591784
  var valid_591785 = header.getOrDefault("X-Amz-Algorithm")
  valid_591785 = validateParameter(valid_591785, JString, required = false,
                                 default = nil)
  if valid_591785 != nil:
    section.add "X-Amz-Algorithm", valid_591785
  var valid_591786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591786 = validateParameter(valid_591786, JString, required = false,
                                 default = nil)
  if valid_591786 != nil:
    section.add "X-Amz-SignedHeaders", valid_591786
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
  var valid_591787 = formData.getOrDefault("AlarmName")
  valid_591787 = validateParameter(valid_591787, JString, required = true,
                                 default = nil)
  if valid_591787 != nil:
    section.add "AlarmName", valid_591787
  var valid_591788 = formData.getOrDefault("StateValue")
  valid_591788 = validateParameter(valid_591788, JString, required = true,
                                 default = newJString("OK"))
  if valid_591788 != nil:
    section.add "StateValue", valid_591788
  var valid_591789 = formData.getOrDefault("StateReason")
  valid_591789 = validateParameter(valid_591789, JString, required = true,
                                 default = nil)
  if valid_591789 != nil:
    section.add "StateReason", valid_591789
  var valid_591790 = formData.getOrDefault("StateReasonData")
  valid_591790 = validateParameter(valid_591790, JString, required = false,
                                 default = nil)
  if valid_591790 != nil:
    section.add "StateReasonData", valid_591790
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591791: Call_PostSetAlarmState_591775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_591791.validator(path, query, header, formData, body)
  let scheme = call_591791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591791.url(scheme.get, call_591791.host, call_591791.base,
                         call_591791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591791, url, valid)

proc call*(call_591792: Call_PostSetAlarmState_591775; AlarmName: string;
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
  var query_591793 = newJObject()
  var formData_591794 = newJObject()
  add(formData_591794, "AlarmName", newJString(AlarmName))
  add(formData_591794, "StateValue", newJString(StateValue))
  add(formData_591794, "StateReason", newJString(StateReason))
  add(formData_591794, "StateReasonData", newJString(StateReasonData))
  add(query_591793, "Action", newJString(Action))
  add(query_591793, "Version", newJString(Version))
  result = call_591792.call(nil, query_591793, nil, formData_591794, nil)

var postSetAlarmState* = Call_PostSetAlarmState_591775(name: "postSetAlarmState",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_PostSetAlarmState_591776,
    base: "/", url: url_PostSetAlarmState_591777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetAlarmState_591756 = ref object of OpenApiRestCall_590364
proc url_GetSetAlarmState_591758(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetAlarmState_591757(path: JsonNode; query: JsonNode;
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
  var valid_591759 = query.getOrDefault("StateReason")
  valid_591759 = validateParameter(valid_591759, JString, required = true,
                                 default = nil)
  if valid_591759 != nil:
    section.add "StateReason", valid_591759
  var valid_591760 = query.getOrDefault("StateValue")
  valid_591760 = validateParameter(valid_591760, JString, required = true,
                                 default = newJString("OK"))
  if valid_591760 != nil:
    section.add "StateValue", valid_591760
  var valid_591761 = query.getOrDefault("Action")
  valid_591761 = validateParameter(valid_591761, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_591761 != nil:
    section.add "Action", valid_591761
  var valid_591762 = query.getOrDefault("AlarmName")
  valid_591762 = validateParameter(valid_591762, JString, required = true,
                                 default = nil)
  if valid_591762 != nil:
    section.add "AlarmName", valid_591762
  var valid_591763 = query.getOrDefault("StateReasonData")
  valid_591763 = validateParameter(valid_591763, JString, required = false,
                                 default = nil)
  if valid_591763 != nil:
    section.add "StateReasonData", valid_591763
  var valid_591764 = query.getOrDefault("Version")
  valid_591764 = validateParameter(valid_591764, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591764 != nil:
    section.add "Version", valid_591764
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
  var valid_591765 = header.getOrDefault("X-Amz-Signature")
  valid_591765 = validateParameter(valid_591765, JString, required = false,
                                 default = nil)
  if valid_591765 != nil:
    section.add "X-Amz-Signature", valid_591765
  var valid_591766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591766 = validateParameter(valid_591766, JString, required = false,
                                 default = nil)
  if valid_591766 != nil:
    section.add "X-Amz-Content-Sha256", valid_591766
  var valid_591767 = header.getOrDefault("X-Amz-Date")
  valid_591767 = validateParameter(valid_591767, JString, required = false,
                                 default = nil)
  if valid_591767 != nil:
    section.add "X-Amz-Date", valid_591767
  var valid_591768 = header.getOrDefault("X-Amz-Credential")
  valid_591768 = validateParameter(valid_591768, JString, required = false,
                                 default = nil)
  if valid_591768 != nil:
    section.add "X-Amz-Credential", valid_591768
  var valid_591769 = header.getOrDefault("X-Amz-Security-Token")
  valid_591769 = validateParameter(valid_591769, JString, required = false,
                                 default = nil)
  if valid_591769 != nil:
    section.add "X-Amz-Security-Token", valid_591769
  var valid_591770 = header.getOrDefault("X-Amz-Algorithm")
  valid_591770 = validateParameter(valid_591770, JString, required = false,
                                 default = nil)
  if valid_591770 != nil:
    section.add "X-Amz-Algorithm", valid_591770
  var valid_591771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591771 = validateParameter(valid_591771, JString, required = false,
                                 default = nil)
  if valid_591771 != nil:
    section.add "X-Amz-SignedHeaders", valid_591771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591772: Call_GetSetAlarmState_591756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_591772.validator(path, query, header, formData, body)
  let scheme = call_591772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591772.url(scheme.get, call_591772.host, call_591772.base,
                         call_591772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591772, url, valid)

proc call*(call_591773: Call_GetSetAlarmState_591756; StateReason: string;
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
  var query_591774 = newJObject()
  add(query_591774, "StateReason", newJString(StateReason))
  add(query_591774, "StateValue", newJString(StateValue))
  add(query_591774, "Action", newJString(Action))
  add(query_591774, "AlarmName", newJString(AlarmName))
  add(query_591774, "StateReasonData", newJString(StateReasonData))
  add(query_591774, "Version", newJString(Version))
  result = call_591773.call(nil, query_591774, nil, nil, nil)

var getSetAlarmState* = Call_GetSetAlarmState_591756(name: "getSetAlarmState",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_GetSetAlarmState_591757,
    base: "/", url: url_GetSetAlarmState_591758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_591812 = ref object of OpenApiRestCall_590364
proc url_PostTagResource_591814(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostTagResource_591813(path: JsonNode; query: JsonNode;
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
  var valid_591815 = query.getOrDefault("Action")
  valid_591815 = validateParameter(valid_591815, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_591815 != nil:
    section.add "Action", valid_591815
  var valid_591816 = query.getOrDefault("Version")
  valid_591816 = validateParameter(valid_591816, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591816 != nil:
    section.add "Version", valid_591816
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
  var valid_591817 = header.getOrDefault("X-Amz-Signature")
  valid_591817 = validateParameter(valid_591817, JString, required = false,
                                 default = nil)
  if valid_591817 != nil:
    section.add "X-Amz-Signature", valid_591817
  var valid_591818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591818 = validateParameter(valid_591818, JString, required = false,
                                 default = nil)
  if valid_591818 != nil:
    section.add "X-Amz-Content-Sha256", valid_591818
  var valid_591819 = header.getOrDefault("X-Amz-Date")
  valid_591819 = validateParameter(valid_591819, JString, required = false,
                                 default = nil)
  if valid_591819 != nil:
    section.add "X-Amz-Date", valid_591819
  var valid_591820 = header.getOrDefault("X-Amz-Credential")
  valid_591820 = validateParameter(valid_591820, JString, required = false,
                                 default = nil)
  if valid_591820 != nil:
    section.add "X-Amz-Credential", valid_591820
  var valid_591821 = header.getOrDefault("X-Amz-Security-Token")
  valid_591821 = validateParameter(valid_591821, JString, required = false,
                                 default = nil)
  if valid_591821 != nil:
    section.add "X-Amz-Security-Token", valid_591821
  var valid_591822 = header.getOrDefault("X-Amz-Algorithm")
  valid_591822 = validateParameter(valid_591822, JString, required = false,
                                 default = nil)
  if valid_591822 != nil:
    section.add "X-Amz-Algorithm", valid_591822
  var valid_591823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591823 = validateParameter(valid_591823, JString, required = false,
                                 default = nil)
  if valid_591823 != nil:
    section.add "X-Amz-SignedHeaders", valid_591823
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
  var valid_591824 = formData.getOrDefault("Tags")
  valid_591824 = validateParameter(valid_591824, JArray, required = true, default = nil)
  if valid_591824 != nil:
    section.add "Tags", valid_591824
  var valid_591825 = formData.getOrDefault("ResourceARN")
  valid_591825 = validateParameter(valid_591825, JString, required = true,
                                 default = nil)
  if valid_591825 != nil:
    section.add "ResourceARN", valid_591825
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591826: Call_PostTagResource_591812; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_591826.validator(path, query, header, formData, body)
  let scheme = call_591826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591826.url(scheme.get, call_591826.host, call_591826.base,
                         call_591826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591826, url, valid)

proc call*(call_591827: Call_PostTagResource_591812; Tags: JsonNode;
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
  var query_591828 = newJObject()
  var formData_591829 = newJObject()
  add(query_591828, "Action", newJString(Action))
  if Tags != nil:
    formData_591829.add "Tags", Tags
  add(query_591828, "Version", newJString(Version))
  add(formData_591829, "ResourceARN", newJString(ResourceARN))
  result = call_591827.call(nil, query_591828, nil, formData_591829, nil)

var postTagResource* = Call_PostTagResource_591812(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_591813,
    base: "/", url: url_PostTagResource_591814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_591795 = ref object of OpenApiRestCall_590364
proc url_GetTagResource_591797(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTagResource_591796(path: JsonNode; query: JsonNode;
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
  var valid_591798 = query.getOrDefault("Tags")
  valid_591798 = validateParameter(valid_591798, JArray, required = true, default = nil)
  if valid_591798 != nil:
    section.add "Tags", valid_591798
  var valid_591799 = query.getOrDefault("Action")
  valid_591799 = validateParameter(valid_591799, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_591799 != nil:
    section.add "Action", valid_591799
  var valid_591800 = query.getOrDefault("ResourceARN")
  valid_591800 = validateParameter(valid_591800, JString, required = true,
                                 default = nil)
  if valid_591800 != nil:
    section.add "ResourceARN", valid_591800
  var valid_591801 = query.getOrDefault("Version")
  valid_591801 = validateParameter(valid_591801, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591801 != nil:
    section.add "Version", valid_591801
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
  var valid_591802 = header.getOrDefault("X-Amz-Signature")
  valid_591802 = validateParameter(valid_591802, JString, required = false,
                                 default = nil)
  if valid_591802 != nil:
    section.add "X-Amz-Signature", valid_591802
  var valid_591803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591803 = validateParameter(valid_591803, JString, required = false,
                                 default = nil)
  if valid_591803 != nil:
    section.add "X-Amz-Content-Sha256", valid_591803
  var valid_591804 = header.getOrDefault("X-Amz-Date")
  valid_591804 = validateParameter(valid_591804, JString, required = false,
                                 default = nil)
  if valid_591804 != nil:
    section.add "X-Amz-Date", valid_591804
  var valid_591805 = header.getOrDefault("X-Amz-Credential")
  valid_591805 = validateParameter(valid_591805, JString, required = false,
                                 default = nil)
  if valid_591805 != nil:
    section.add "X-Amz-Credential", valid_591805
  var valid_591806 = header.getOrDefault("X-Amz-Security-Token")
  valid_591806 = validateParameter(valid_591806, JString, required = false,
                                 default = nil)
  if valid_591806 != nil:
    section.add "X-Amz-Security-Token", valid_591806
  var valid_591807 = header.getOrDefault("X-Amz-Algorithm")
  valid_591807 = validateParameter(valid_591807, JString, required = false,
                                 default = nil)
  if valid_591807 != nil:
    section.add "X-Amz-Algorithm", valid_591807
  var valid_591808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591808 = validateParameter(valid_591808, JString, required = false,
                                 default = nil)
  if valid_591808 != nil:
    section.add "X-Amz-SignedHeaders", valid_591808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591809: Call_GetTagResource_591795; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_591809.validator(path, query, header, formData, body)
  let scheme = call_591809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591809.url(scheme.get, call_591809.host, call_591809.base,
                         call_591809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591809, url, valid)

proc call*(call_591810: Call_GetTagResource_591795; Tags: JsonNode;
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
  var query_591811 = newJObject()
  if Tags != nil:
    query_591811.add "Tags", Tags
  add(query_591811, "Action", newJString(Action))
  add(query_591811, "ResourceARN", newJString(ResourceARN))
  add(query_591811, "Version", newJString(Version))
  result = call_591810.call(nil, query_591811, nil, nil, nil)

var getTagResource* = Call_GetTagResource_591795(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_591796,
    base: "/", url: url_GetTagResource_591797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_591847 = ref object of OpenApiRestCall_590364
proc url_PostUntagResource_591849(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUntagResource_591848(path: JsonNode; query: JsonNode;
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
  var valid_591850 = query.getOrDefault("Action")
  valid_591850 = validateParameter(valid_591850, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_591850 != nil:
    section.add "Action", valid_591850
  var valid_591851 = query.getOrDefault("Version")
  valid_591851 = validateParameter(valid_591851, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591851 != nil:
    section.add "Version", valid_591851
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
  var valid_591852 = header.getOrDefault("X-Amz-Signature")
  valid_591852 = validateParameter(valid_591852, JString, required = false,
                                 default = nil)
  if valid_591852 != nil:
    section.add "X-Amz-Signature", valid_591852
  var valid_591853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591853 = validateParameter(valid_591853, JString, required = false,
                                 default = nil)
  if valid_591853 != nil:
    section.add "X-Amz-Content-Sha256", valid_591853
  var valid_591854 = header.getOrDefault("X-Amz-Date")
  valid_591854 = validateParameter(valid_591854, JString, required = false,
                                 default = nil)
  if valid_591854 != nil:
    section.add "X-Amz-Date", valid_591854
  var valid_591855 = header.getOrDefault("X-Amz-Credential")
  valid_591855 = validateParameter(valid_591855, JString, required = false,
                                 default = nil)
  if valid_591855 != nil:
    section.add "X-Amz-Credential", valid_591855
  var valid_591856 = header.getOrDefault("X-Amz-Security-Token")
  valid_591856 = validateParameter(valid_591856, JString, required = false,
                                 default = nil)
  if valid_591856 != nil:
    section.add "X-Amz-Security-Token", valid_591856
  var valid_591857 = header.getOrDefault("X-Amz-Algorithm")
  valid_591857 = validateParameter(valid_591857, JString, required = false,
                                 default = nil)
  if valid_591857 != nil:
    section.add "X-Amz-Algorithm", valid_591857
  var valid_591858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591858 = validateParameter(valid_591858, JString, required = false,
                                 default = nil)
  if valid_591858 != nil:
    section.add "X-Amz-SignedHeaders", valid_591858
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
  var valid_591859 = formData.getOrDefault("TagKeys")
  valid_591859 = validateParameter(valid_591859, JArray, required = true, default = nil)
  if valid_591859 != nil:
    section.add "TagKeys", valid_591859
  var valid_591860 = formData.getOrDefault("ResourceARN")
  valid_591860 = validateParameter(valid_591860, JString, required = true,
                                 default = nil)
  if valid_591860 != nil:
    section.add "ResourceARN", valid_591860
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591861: Call_PostUntagResource_591847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_591861.validator(path, query, header, formData, body)
  let scheme = call_591861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591861.url(scheme.get, call_591861.host, call_591861.base,
                         call_591861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591861, url, valid)

proc call*(call_591862: Call_PostUntagResource_591847; TagKeys: JsonNode;
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
  var query_591863 = newJObject()
  var formData_591864 = newJObject()
  if TagKeys != nil:
    formData_591864.add "TagKeys", TagKeys
  add(query_591863, "Action", newJString(Action))
  add(query_591863, "Version", newJString(Version))
  add(formData_591864, "ResourceARN", newJString(ResourceARN))
  result = call_591862.call(nil, query_591863, nil, formData_591864, nil)

var postUntagResource* = Call_PostUntagResource_591847(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_591848,
    base: "/", url: url_PostUntagResource_591849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_591830 = ref object of OpenApiRestCall_590364
proc url_GetUntagResource_591832(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUntagResource_591831(path: JsonNode; query: JsonNode;
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
  var valid_591833 = query.getOrDefault("TagKeys")
  valid_591833 = validateParameter(valid_591833, JArray, required = true, default = nil)
  if valid_591833 != nil:
    section.add "TagKeys", valid_591833
  var valid_591834 = query.getOrDefault("Action")
  valid_591834 = validateParameter(valid_591834, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_591834 != nil:
    section.add "Action", valid_591834
  var valid_591835 = query.getOrDefault("ResourceARN")
  valid_591835 = validateParameter(valid_591835, JString, required = true,
                                 default = nil)
  if valid_591835 != nil:
    section.add "ResourceARN", valid_591835
  var valid_591836 = query.getOrDefault("Version")
  valid_591836 = validateParameter(valid_591836, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_591836 != nil:
    section.add "Version", valid_591836
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
  var valid_591837 = header.getOrDefault("X-Amz-Signature")
  valid_591837 = validateParameter(valid_591837, JString, required = false,
                                 default = nil)
  if valid_591837 != nil:
    section.add "X-Amz-Signature", valid_591837
  var valid_591838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591838 = validateParameter(valid_591838, JString, required = false,
                                 default = nil)
  if valid_591838 != nil:
    section.add "X-Amz-Content-Sha256", valid_591838
  var valid_591839 = header.getOrDefault("X-Amz-Date")
  valid_591839 = validateParameter(valid_591839, JString, required = false,
                                 default = nil)
  if valid_591839 != nil:
    section.add "X-Amz-Date", valid_591839
  var valid_591840 = header.getOrDefault("X-Amz-Credential")
  valid_591840 = validateParameter(valid_591840, JString, required = false,
                                 default = nil)
  if valid_591840 != nil:
    section.add "X-Amz-Credential", valid_591840
  var valid_591841 = header.getOrDefault("X-Amz-Security-Token")
  valid_591841 = validateParameter(valid_591841, JString, required = false,
                                 default = nil)
  if valid_591841 != nil:
    section.add "X-Amz-Security-Token", valid_591841
  var valid_591842 = header.getOrDefault("X-Amz-Algorithm")
  valid_591842 = validateParameter(valid_591842, JString, required = false,
                                 default = nil)
  if valid_591842 != nil:
    section.add "X-Amz-Algorithm", valid_591842
  var valid_591843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591843 = validateParameter(valid_591843, JString, required = false,
                                 default = nil)
  if valid_591843 != nil:
    section.add "X-Amz-SignedHeaders", valid_591843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591844: Call_GetUntagResource_591830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_591844.validator(path, query, header, formData, body)
  let scheme = call_591844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591844.url(scheme.get, call_591844.host, call_591844.base,
                         call_591844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591844, url, valid)

proc call*(call_591845: Call_GetUntagResource_591830; TagKeys: JsonNode;
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
  var query_591846 = newJObject()
  if TagKeys != nil:
    query_591846.add "TagKeys", TagKeys
  add(query_591846, "Action", newJString(Action))
  add(query_591846, "ResourceARN", newJString(ResourceARN))
  add(query_591846, "Version", newJString(Version))
  result = call_591845.call(nil, query_591846, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_591830(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_591831,
    base: "/", url: url_GetUntagResource_591832,
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
