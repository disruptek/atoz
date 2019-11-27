
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_PostDeleteAlarms_599976 = ref object of OpenApiRestCall_599368
proc url_PostDeleteAlarms_599978(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAlarms_599977(path: JsonNode; query: JsonNode;
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
  var valid_599979 = query.getOrDefault("Action")
  valid_599979 = validateParameter(valid_599979, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_599979 != nil:
    section.add "Action", valid_599979
  var valid_599980 = query.getOrDefault("Version")
  valid_599980 = validateParameter(valid_599980, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_599980 != nil:
    section.add "Version", valid_599980
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
  var valid_599981 = header.getOrDefault("X-Amz-Date")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Date", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Security-Token")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Security-Token", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Content-Sha256", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Algorithm")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Algorithm", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Signature")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Signature", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-SignedHeaders", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Credential")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Credential", valid_599987
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_599988 = formData.getOrDefault("AlarmNames")
  valid_599988 = validateParameter(valid_599988, JArray, required = true, default = nil)
  if valid_599988 != nil:
    section.add "AlarmNames", valid_599988
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599989: Call_PostDeleteAlarms_599976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_599989.validator(path, query, header, formData, body)
  let scheme = call_599989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599989.url(scheme.get, call_599989.host, call_599989.base,
                         call_599989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599989, url, valid)

proc call*(call_599990: Call_PostDeleteAlarms_599976; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   Action: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Version: string (required)
  var query_599991 = newJObject()
  var formData_599992 = newJObject()
  add(query_599991, "Action", newJString(Action))
  if AlarmNames != nil:
    formData_599992.add "AlarmNames", AlarmNames
  add(query_599991, "Version", newJString(Version))
  result = call_599990.call(nil, query_599991, nil, formData_599992, nil)

var postDeleteAlarms* = Call_PostDeleteAlarms_599976(name: "postDeleteAlarms",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_PostDeleteAlarms_599977,
    base: "/", url: url_PostDeleteAlarms_599978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAlarms_599705 = ref object of OpenApiRestCall_599368
proc url_GetDeleteAlarms_599707(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAlarms_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = query.getOrDefault("AlarmNames")
  valid_599819 = validateParameter(valid_599819, JArray, required = true, default = nil)
  if valid_599819 != nil:
    section.add "AlarmNames", valid_599819
  var valid_599833 = query.getOrDefault("Action")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_599833 != nil:
    section.add "Action", valid_599833
  var valid_599834 = query.getOrDefault("Version")
  valid_599834 = validateParameter(valid_599834, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_599834 != nil:
    section.add "Version", valid_599834
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
  var valid_599835 = header.getOrDefault("X-Amz-Date")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Date", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Security-Token")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Security-Token", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Content-Sha256", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Algorithm")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Algorithm", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Signature")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Signature", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-SignedHeaders", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Credential")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Credential", valid_599841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599864: Call_GetDeleteAlarms_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_599864.validator(path, query, header, formData, body)
  let scheme = call_599864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599864.url(scheme.get, call_599864.host, call_599864.base,
                         call_599864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599864, url, valid)

proc call*(call_599935: Call_GetDeleteAlarms_599705; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_599936 = newJObject()
  if AlarmNames != nil:
    query_599936.add "AlarmNames", AlarmNames
  add(query_599936, "Action", newJString(Action))
  add(query_599936, "Version", newJString(Version))
  result = call_599935.call(nil, query_599936, nil, nil, nil)

var getDeleteAlarms* = Call_GetDeleteAlarms_599705(name: "getDeleteAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_GetDeleteAlarms_599706,
    base: "/", url: url_GetDeleteAlarms_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnomalyDetector_600012 = ref object of OpenApiRestCall_599368
proc url_PostDeleteAnomalyDetector_600014(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAnomalyDetector_600013(path: JsonNode; query: JsonNode;
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
  var valid_600015 = query.getOrDefault("Action")
  valid_600015 = validateParameter(valid_600015, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_600015 != nil:
    section.add "Action", valid_600015
  var valid_600016 = query.getOrDefault("Version")
  valid_600016 = validateParameter(valid_600016, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600016 != nil:
    section.add "Version", valid_600016
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
  var valid_600017 = header.getOrDefault("X-Amz-Date")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Date", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Security-Token")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Security-Token", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Content-Sha256", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Algorithm")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Algorithm", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Signature")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Signature", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-SignedHeaders", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Credential")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Credential", valid_600023
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
  var valid_600024 = formData.getOrDefault("MetricName")
  valid_600024 = validateParameter(valid_600024, JString, required = true,
                                 default = nil)
  if valid_600024 != nil:
    section.add "MetricName", valid_600024
  var valid_600025 = formData.getOrDefault("Dimensions")
  valid_600025 = validateParameter(valid_600025, JArray, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "Dimensions", valid_600025
  var valid_600026 = formData.getOrDefault("Stat")
  valid_600026 = validateParameter(valid_600026, JString, required = true,
                                 default = nil)
  if valid_600026 != nil:
    section.add "Stat", valid_600026
  var valid_600027 = formData.getOrDefault("Namespace")
  valid_600027 = validateParameter(valid_600027, JString, required = true,
                                 default = nil)
  if valid_600027 != nil:
    section.add "Namespace", valid_600027
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600028: Call_PostDeleteAnomalyDetector_600012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_600028.validator(path, query, header, formData, body)
  let scheme = call_600028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600028.url(scheme.get, call_600028.host, call_600028.base,
                         call_600028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600028, url, valid)

proc call*(call_600029: Call_PostDeleteAnomalyDetector_600012; MetricName: string;
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
  var query_600030 = newJObject()
  var formData_600031 = newJObject()
  add(formData_600031, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_600031.add "Dimensions", Dimensions
  add(query_600030, "Action", newJString(Action))
  add(formData_600031, "Stat", newJString(Stat))
  add(formData_600031, "Namespace", newJString(Namespace))
  add(query_600030, "Version", newJString(Version))
  result = call_600029.call(nil, query_600030, nil, formData_600031, nil)

var postDeleteAnomalyDetector* = Call_PostDeleteAnomalyDetector_600012(
    name: "postDeleteAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_PostDeleteAnomalyDetector_600013, base: "/",
    url: url_PostDeleteAnomalyDetector_600014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnomalyDetector_599993 = ref object of OpenApiRestCall_599368
proc url_GetDeleteAnomalyDetector_599995(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAnomalyDetector_599994(path: JsonNode; query: JsonNode;
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
  var valid_599996 = query.getOrDefault("Namespace")
  valid_599996 = validateParameter(valid_599996, JString, required = true,
                                 default = nil)
  if valid_599996 != nil:
    section.add "Namespace", valid_599996
  var valid_599997 = query.getOrDefault("Stat")
  valid_599997 = validateParameter(valid_599997, JString, required = true,
                                 default = nil)
  if valid_599997 != nil:
    section.add "Stat", valid_599997
  var valid_599998 = query.getOrDefault("Dimensions")
  valid_599998 = validateParameter(valid_599998, JArray, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "Dimensions", valid_599998
  var valid_599999 = query.getOrDefault("Action")
  valid_599999 = validateParameter(valid_599999, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_599999 != nil:
    section.add "Action", valid_599999
  var valid_600000 = query.getOrDefault("Version")
  valid_600000 = validateParameter(valid_600000, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600000 != nil:
    section.add "Version", valid_600000
  var valid_600001 = query.getOrDefault("MetricName")
  valid_600001 = validateParameter(valid_600001, JString, required = true,
                                 default = nil)
  if valid_600001 != nil:
    section.add "MetricName", valid_600001
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
  var valid_600002 = header.getOrDefault("X-Amz-Date")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Date", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Security-Token")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Security-Token", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Content-Sha256", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Algorithm")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Algorithm", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Signature")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Signature", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-SignedHeaders", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Credential")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Credential", valid_600008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600009: Call_GetDeleteAnomalyDetector_599993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_600009.validator(path, query, header, formData, body)
  let scheme = call_600009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600009.url(scheme.get, call_600009.host, call_600009.base,
                         call_600009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600009, url, valid)

proc call*(call_600010: Call_GetDeleteAnomalyDetector_599993; Namespace: string;
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
  var query_600011 = newJObject()
  add(query_600011, "Namespace", newJString(Namespace))
  add(query_600011, "Stat", newJString(Stat))
  if Dimensions != nil:
    query_600011.add "Dimensions", Dimensions
  add(query_600011, "Action", newJString(Action))
  add(query_600011, "Version", newJString(Version))
  add(query_600011, "MetricName", newJString(MetricName))
  result = call_600010.call(nil, query_600011, nil, nil, nil)

var getDeleteAnomalyDetector* = Call_GetDeleteAnomalyDetector_599993(
    name: "getDeleteAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_GetDeleteAnomalyDetector_599994, base: "/",
    url: url_GetDeleteAnomalyDetector_599995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDashboards_600048 = ref object of OpenApiRestCall_599368
proc url_PostDeleteDashboards_600050(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDashboards_600049(path: JsonNode; query: JsonNode;
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
  var valid_600051 = query.getOrDefault("Action")
  valid_600051 = validateParameter(valid_600051, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_600051 != nil:
    section.add "Action", valid_600051
  var valid_600052 = query.getOrDefault("Version")
  valid_600052 = validateParameter(valid_600052, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600052 != nil:
    section.add "Version", valid_600052
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
  var valid_600053 = header.getOrDefault("X-Amz-Date")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Date", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Security-Token")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Security-Token", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardNames` field"
  var valid_600060 = formData.getOrDefault("DashboardNames")
  valid_600060 = validateParameter(valid_600060, JArray, required = true, default = nil)
  if valid_600060 != nil:
    section.add "DashboardNames", valid_600060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_PostDeleteDashboards_600048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_PostDeleteDashboards_600048; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  var query_600063 = newJObject()
  var formData_600064 = newJObject()
  add(query_600063, "Action", newJString(Action))
  add(query_600063, "Version", newJString(Version))
  if DashboardNames != nil:
    formData_600064.add "DashboardNames", DashboardNames
  result = call_600062.call(nil, query_600063, nil, formData_600064, nil)

var postDeleteDashboards* = Call_PostDeleteDashboards_600048(
    name: "postDeleteDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_PostDeleteDashboards_600049, base: "/",
    url: url_PostDeleteDashboards_600050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDashboards_600032 = ref object of OpenApiRestCall_599368
proc url_GetDeleteDashboards_600034(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDashboards_600033(path: JsonNode; query: JsonNode;
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
  var valid_600035 = query.getOrDefault("Action")
  valid_600035 = validateParameter(valid_600035, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_600035 != nil:
    section.add "Action", valid_600035
  var valid_600036 = query.getOrDefault("DashboardNames")
  valid_600036 = validateParameter(valid_600036, JArray, required = true, default = nil)
  if valid_600036 != nil:
    section.add "DashboardNames", valid_600036
  var valid_600037 = query.getOrDefault("Version")
  valid_600037 = validateParameter(valid_600037, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600037 != nil:
    section.add "Version", valid_600037
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
  var valid_600038 = header.getOrDefault("X-Amz-Date")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Date", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Security-Token")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Security-Token", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600045: Call_GetDeleteDashboards_600032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_600045.validator(path, query, header, formData, body)
  let scheme = call_600045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600045.url(scheme.get, call_600045.host, call_600045.base,
                         call_600045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600045, url, valid)

proc call*(call_600046: Call_GetDeleteDashboards_600032; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   Action: string (required)
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Version: string (required)
  var query_600047 = newJObject()
  add(query_600047, "Action", newJString(Action))
  if DashboardNames != nil:
    query_600047.add "DashboardNames", DashboardNames
  add(query_600047, "Version", newJString(Version))
  result = call_600046.call(nil, query_600047, nil, nil, nil)

var getDeleteDashboards* = Call_GetDeleteDashboards_600032(
    name: "getDeleteDashboards", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_GetDeleteDashboards_600033, base: "/",
    url: url_GetDeleteDashboards_600034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteInsightRules_600081 = ref object of OpenApiRestCall_599368
proc url_PostDeleteInsightRules_600083(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteInsightRules_600082(path: JsonNode; query: JsonNode;
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
  var valid_600084 = query.getOrDefault("Action")
  valid_600084 = validateParameter(valid_600084, JString, required = true,
                                 default = newJString("DeleteInsightRules"))
  if valid_600084 != nil:
    section.add "Action", valid_600084
  var valid_600085 = query.getOrDefault("Version")
  valid_600085 = validateParameter(valid_600085, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600085 != nil:
    section.add "Version", valid_600085
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
  var valid_600086 = header.getOrDefault("X-Amz-Date")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Date", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Security-Token")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Security-Token", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Content-Sha256", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Algorithm")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Algorithm", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Signature")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Signature", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-SignedHeaders", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Credential")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Credential", valid_600092
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_600093 = formData.getOrDefault("RuleNames")
  valid_600093 = validateParameter(valid_600093, JArray, required = true, default = nil)
  if valid_600093 != nil:
    section.add "RuleNames", valid_600093
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600094: Call_PostDeleteInsightRules_600081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_600094.validator(path, query, header, formData, body)
  let scheme = call_600094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600094.url(scheme.get, call_600094.host, call_600094.base,
                         call_600094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600094, url, valid)

proc call*(call_600095: Call_PostDeleteInsightRules_600081; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600096 = newJObject()
  var formData_600097 = newJObject()
  if RuleNames != nil:
    formData_600097.add "RuleNames", RuleNames
  add(query_600096, "Action", newJString(Action))
  add(query_600096, "Version", newJString(Version))
  result = call_600095.call(nil, query_600096, nil, formData_600097, nil)

var postDeleteInsightRules* = Call_PostDeleteInsightRules_600081(
    name: "postDeleteInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_PostDeleteInsightRules_600082, base: "/",
    url: url_PostDeleteInsightRules_600083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteInsightRules_600065 = ref object of OpenApiRestCall_599368
proc url_GetDeleteInsightRules_600067(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteInsightRules_600066(path: JsonNode; query: JsonNode;
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
  var valid_600068 = query.getOrDefault("Action")
  valid_600068 = validateParameter(valid_600068, JString, required = true,
                                 default = newJString("DeleteInsightRules"))
  if valid_600068 != nil:
    section.add "Action", valid_600068
  var valid_600069 = query.getOrDefault("RuleNames")
  valid_600069 = validateParameter(valid_600069, JArray, required = true, default = nil)
  if valid_600069 != nil:
    section.add "RuleNames", valid_600069
  var valid_600070 = query.getOrDefault("Version")
  valid_600070 = validateParameter(valid_600070, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600070 != nil:
    section.add "Version", valid_600070
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
  var valid_600071 = header.getOrDefault("X-Amz-Date")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Date", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Security-Token")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Security-Token", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Content-Sha256", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Algorithm")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Algorithm", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Signature")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Signature", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-SignedHeaders", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Credential")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Credential", valid_600077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600078: Call_GetDeleteInsightRules_600065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_600078.validator(path, query, header, formData, body)
  let scheme = call_600078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600078.url(scheme.get, call_600078.host, call_600078.base,
                         call_600078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600078, url, valid)

proc call*(call_600079: Call_GetDeleteInsightRules_600065; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_600080 = newJObject()
  add(query_600080, "Action", newJString(Action))
  if RuleNames != nil:
    query_600080.add "RuleNames", RuleNames
  add(query_600080, "Version", newJString(Version))
  result = call_600079.call(nil, query_600080, nil, nil, nil)

var getDeleteInsightRules* = Call_GetDeleteInsightRules_600065(
    name: "getDeleteInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_GetDeleteInsightRules_600066, base: "/",
    url: url_GetDeleteInsightRules_600067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmHistory_600119 = ref object of OpenApiRestCall_599368
proc url_PostDescribeAlarmHistory_600121(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAlarmHistory_600120(path: JsonNode; query: JsonNode;
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
  var valid_600122 = query.getOrDefault("Action")
  valid_600122 = validateParameter(valid_600122, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_600122 != nil:
    section.add "Action", valid_600122
  var valid_600123 = query.getOrDefault("Version")
  valid_600123 = validateParameter(valid_600123, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600123 != nil:
    section.add "Version", valid_600123
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
  var valid_600124 = header.getOrDefault("X-Amz-Date")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Date", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Security-Token")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Security-Token", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Content-Sha256", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Algorithm")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Algorithm", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Signature")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Signature", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-SignedHeaders", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Credential")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Credential", valid_600130
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
  var valid_600131 = formData.getOrDefault("NextToken")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "NextToken", valid_600131
  var valid_600132 = formData.getOrDefault("AlarmName")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "AlarmName", valid_600132
  var valid_600133 = formData.getOrDefault("MaxRecords")
  valid_600133 = validateParameter(valid_600133, JInt, required = false, default = nil)
  if valid_600133 != nil:
    section.add "MaxRecords", valid_600133
  var valid_600134 = formData.getOrDefault("HistoryItemType")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_600134 != nil:
    section.add "HistoryItemType", valid_600134
  var valid_600135 = formData.getOrDefault("EndDate")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "EndDate", valid_600135
  var valid_600136 = formData.getOrDefault("StartDate")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "StartDate", valid_600136
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600137: Call_PostDescribeAlarmHistory_600119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_600137.validator(path, query, header, formData, body)
  let scheme = call_600137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600137.url(scheme.get, call_600137.host, call_600137.base,
                         call_600137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600137, url, valid)

proc call*(call_600138: Call_PostDescribeAlarmHistory_600119;
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
  var query_600139 = newJObject()
  var formData_600140 = newJObject()
  add(formData_600140, "NextToken", newJString(NextToken))
  add(query_600139, "Action", newJString(Action))
  add(formData_600140, "AlarmName", newJString(AlarmName))
  add(formData_600140, "MaxRecords", newJInt(MaxRecords))
  add(formData_600140, "HistoryItemType", newJString(HistoryItemType))
  add(formData_600140, "EndDate", newJString(EndDate))
  add(query_600139, "Version", newJString(Version))
  add(formData_600140, "StartDate", newJString(StartDate))
  result = call_600138.call(nil, query_600139, nil, formData_600140, nil)

var postDescribeAlarmHistory* = Call_PostDescribeAlarmHistory_600119(
    name: "postDescribeAlarmHistory", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_PostDescribeAlarmHistory_600120, base: "/",
    url: url_PostDescribeAlarmHistory_600121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmHistory_600098 = ref object of OpenApiRestCall_599368
proc url_GetDescribeAlarmHistory_600100(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAlarmHistory_600099(path: JsonNode; query: JsonNode;
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
  var valid_600101 = query.getOrDefault("MaxRecords")
  valid_600101 = validateParameter(valid_600101, JInt, required = false, default = nil)
  if valid_600101 != nil:
    section.add "MaxRecords", valid_600101
  var valid_600102 = query.getOrDefault("EndDate")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "EndDate", valid_600102
  var valid_600103 = query.getOrDefault("AlarmName")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "AlarmName", valid_600103
  var valid_600104 = query.getOrDefault("NextToken")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "NextToken", valid_600104
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600105 = query.getOrDefault("Action")
  valid_600105 = validateParameter(valid_600105, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_600105 != nil:
    section.add "Action", valid_600105
  var valid_600106 = query.getOrDefault("StartDate")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "StartDate", valid_600106
  var valid_600107 = query.getOrDefault("Version")
  valid_600107 = validateParameter(valid_600107, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600107 != nil:
    section.add "Version", valid_600107
  var valid_600108 = query.getOrDefault("HistoryItemType")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_600108 != nil:
    section.add "HistoryItemType", valid_600108
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
  var valid_600109 = header.getOrDefault("X-Amz-Date")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Date", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-Security-Token")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Security-Token", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Content-Sha256", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Algorithm")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Algorithm", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Signature")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Signature", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-SignedHeaders", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Credential")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Credential", valid_600115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600116: Call_GetDescribeAlarmHistory_600098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_600116.validator(path, query, header, formData, body)
  let scheme = call_600116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600116.url(scheme.get, call_600116.host, call_600116.base,
                         call_600116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600116, url, valid)

proc call*(call_600117: Call_GetDescribeAlarmHistory_600098; MaxRecords: int = 0;
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
  var query_600118 = newJObject()
  add(query_600118, "MaxRecords", newJInt(MaxRecords))
  add(query_600118, "EndDate", newJString(EndDate))
  add(query_600118, "AlarmName", newJString(AlarmName))
  add(query_600118, "NextToken", newJString(NextToken))
  add(query_600118, "Action", newJString(Action))
  add(query_600118, "StartDate", newJString(StartDate))
  add(query_600118, "Version", newJString(Version))
  add(query_600118, "HistoryItemType", newJString(HistoryItemType))
  result = call_600117.call(nil, query_600118, nil, nil, nil)

var getDescribeAlarmHistory* = Call_GetDescribeAlarmHistory_600098(
    name: "getDescribeAlarmHistory", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_GetDescribeAlarmHistory_600099, base: "/",
    url: url_GetDescribeAlarmHistory_600100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarms_600162 = ref object of OpenApiRestCall_599368
proc url_PostDescribeAlarms_600164(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAlarms_600163(path: JsonNode; query: JsonNode;
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
  var valid_600165 = query.getOrDefault("Action")
  valid_600165 = validateParameter(valid_600165, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_600165 != nil:
    section.add "Action", valid_600165
  var valid_600166 = query.getOrDefault("Version")
  valid_600166 = validateParameter(valid_600166, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600166 != nil:
    section.add "Version", valid_600166
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
  var valid_600167 = header.getOrDefault("X-Amz-Date")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Date", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Security-Token")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Security-Token", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Content-Sha256", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Algorithm")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Algorithm", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Signature")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Signature", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-SignedHeaders", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Credential")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Credential", valid_600173
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
  var valid_600174 = formData.getOrDefault("ActionPrefix")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "ActionPrefix", valid_600174
  var valid_600175 = formData.getOrDefault("NextToken")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "NextToken", valid_600175
  var valid_600176 = formData.getOrDefault("StateValue")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = newJString("OK"))
  if valid_600176 != nil:
    section.add "StateValue", valid_600176
  var valid_600177 = formData.getOrDefault("AlarmNamePrefix")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "AlarmNamePrefix", valid_600177
  var valid_600178 = formData.getOrDefault("MaxRecords")
  valid_600178 = validateParameter(valid_600178, JInt, required = false, default = nil)
  if valid_600178 != nil:
    section.add "MaxRecords", valid_600178
  var valid_600179 = formData.getOrDefault("AlarmNames")
  valid_600179 = validateParameter(valid_600179, JArray, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "AlarmNames", valid_600179
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600180: Call_PostDescribeAlarms_600162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_600180.validator(path, query, header, formData, body)
  let scheme = call_600180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600180.url(scheme.get, call_600180.host, call_600180.base,
                         call_600180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600180, url, valid)

proc call*(call_600181: Call_PostDescribeAlarms_600162; ActionPrefix: string = "";
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
  var query_600182 = newJObject()
  var formData_600183 = newJObject()
  add(formData_600183, "ActionPrefix", newJString(ActionPrefix))
  add(formData_600183, "NextToken", newJString(NextToken))
  add(formData_600183, "StateValue", newJString(StateValue))
  add(query_600182, "Action", newJString(Action))
  add(formData_600183, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(formData_600183, "MaxRecords", newJInt(MaxRecords))
  if AlarmNames != nil:
    formData_600183.add "AlarmNames", AlarmNames
  add(query_600182, "Version", newJString(Version))
  result = call_600181.call(nil, query_600182, nil, formData_600183, nil)

var postDescribeAlarms* = Call_PostDescribeAlarms_600162(
    name: "postDescribeAlarms", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarms",
    validator: validate_PostDescribeAlarms_600163, base: "/",
    url: url_PostDescribeAlarms_600164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarms_600141 = ref object of OpenApiRestCall_599368
proc url_GetDescribeAlarms_600143(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAlarms_600142(path: JsonNode; query: JsonNode;
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
  var valid_600144 = query.getOrDefault("AlarmNamePrefix")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "AlarmNamePrefix", valid_600144
  var valid_600145 = query.getOrDefault("MaxRecords")
  valid_600145 = validateParameter(valid_600145, JInt, required = false, default = nil)
  if valid_600145 != nil:
    section.add "MaxRecords", valid_600145
  var valid_600146 = query.getOrDefault("ActionPrefix")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "ActionPrefix", valid_600146
  var valid_600147 = query.getOrDefault("AlarmNames")
  valid_600147 = validateParameter(valid_600147, JArray, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "AlarmNames", valid_600147
  var valid_600148 = query.getOrDefault("NextToken")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "NextToken", valid_600148
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600149 = query.getOrDefault("Action")
  valid_600149 = validateParameter(valid_600149, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_600149 != nil:
    section.add "Action", valid_600149
  var valid_600150 = query.getOrDefault("StateValue")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = newJString("OK"))
  if valid_600150 != nil:
    section.add "StateValue", valid_600150
  var valid_600151 = query.getOrDefault("Version")
  valid_600151 = validateParameter(valid_600151, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600151 != nil:
    section.add "Version", valid_600151
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
  var valid_600152 = header.getOrDefault("X-Amz-Date")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Date", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Security-Token")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Security-Token", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Content-Sha256", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Algorithm")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Algorithm", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Signature")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Signature", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-SignedHeaders", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Credential")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Credential", valid_600158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600159: Call_GetDescribeAlarms_600141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_600159.validator(path, query, header, formData, body)
  let scheme = call_600159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600159.url(scheme.get, call_600159.host, call_600159.base,
                         call_600159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600159, url, valid)

proc call*(call_600160: Call_GetDescribeAlarms_600141;
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
  var query_600161 = newJObject()
  add(query_600161, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(query_600161, "MaxRecords", newJInt(MaxRecords))
  add(query_600161, "ActionPrefix", newJString(ActionPrefix))
  if AlarmNames != nil:
    query_600161.add "AlarmNames", AlarmNames
  add(query_600161, "NextToken", newJString(NextToken))
  add(query_600161, "Action", newJString(Action))
  add(query_600161, "StateValue", newJString(StateValue))
  add(query_600161, "Version", newJString(Version))
  result = call_600160.call(nil, query_600161, nil, nil, nil)

var getDescribeAlarms* = Call_GetDescribeAlarms_600141(name: "getDescribeAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DescribeAlarms", validator: validate_GetDescribeAlarms_600142,
    base: "/", url: url_GetDescribeAlarms_600143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmsForMetric_600206 = ref object of OpenApiRestCall_599368
proc url_PostDescribeAlarmsForMetric_600208(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAlarmsForMetric_600207(path: JsonNode; query: JsonNode;
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
  var valid_600209 = query.getOrDefault("Action")
  valid_600209 = validateParameter(valid_600209, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_600209 != nil:
    section.add "Action", valid_600209
  var valid_600210 = query.getOrDefault("Version")
  valid_600210 = validateParameter(valid_600210, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600210 != nil:
    section.add "Version", valid_600210
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
  var valid_600211 = header.getOrDefault("X-Amz-Date")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Date", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Security-Token")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Security-Token", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Content-Sha256", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Algorithm")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Algorithm", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Signature")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Signature", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-SignedHeaders", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Credential")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Credential", valid_600217
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
  var valid_600218 = formData.getOrDefault("ExtendedStatistic")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "ExtendedStatistic", valid_600218
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_600219 = formData.getOrDefault("MetricName")
  valid_600219 = validateParameter(valid_600219, JString, required = true,
                                 default = nil)
  if valid_600219 != nil:
    section.add "MetricName", valid_600219
  var valid_600220 = formData.getOrDefault("Dimensions")
  valid_600220 = validateParameter(valid_600220, JArray, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "Dimensions", valid_600220
  var valid_600221 = formData.getOrDefault("Statistic")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_600221 != nil:
    section.add "Statistic", valid_600221
  var valid_600222 = formData.getOrDefault("Namespace")
  valid_600222 = validateParameter(valid_600222, JString, required = true,
                                 default = nil)
  if valid_600222 != nil:
    section.add "Namespace", valid_600222
  var valid_600223 = formData.getOrDefault("Unit")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_600223 != nil:
    section.add "Unit", valid_600223
  var valid_600224 = formData.getOrDefault("Period")
  valid_600224 = validateParameter(valid_600224, JInt, required = false, default = nil)
  if valid_600224 != nil:
    section.add "Period", valid_600224
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600225: Call_PostDescribeAlarmsForMetric_600206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_600225.validator(path, query, header, formData, body)
  let scheme = call_600225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600225.url(scheme.get, call_600225.host, call_600225.base,
                         call_600225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600225, url, valid)

proc call*(call_600226: Call_PostDescribeAlarmsForMetric_600206;
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
  var query_600227 = newJObject()
  var formData_600228 = newJObject()
  add(formData_600228, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(formData_600228, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_600228.add "Dimensions", Dimensions
  add(query_600227, "Action", newJString(Action))
  add(formData_600228, "Statistic", newJString(Statistic))
  add(formData_600228, "Namespace", newJString(Namespace))
  add(formData_600228, "Unit", newJString(Unit))
  add(query_600227, "Version", newJString(Version))
  add(formData_600228, "Period", newJInt(Period))
  result = call_600226.call(nil, query_600227, nil, formData_600228, nil)

var postDescribeAlarmsForMetric* = Call_PostDescribeAlarmsForMetric_600206(
    name: "postDescribeAlarmsForMetric", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_PostDescribeAlarmsForMetric_600207, base: "/",
    url: url_PostDescribeAlarmsForMetric_600208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmsForMetric_600184 = ref object of OpenApiRestCall_599368
proc url_GetDescribeAlarmsForMetric_600186(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAlarmsForMetric_600185(path: JsonNode; query: JsonNode;
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
  var valid_600187 = query.getOrDefault("Namespace")
  valid_600187 = validateParameter(valid_600187, JString, required = true,
                                 default = nil)
  if valid_600187 != nil:
    section.add "Namespace", valid_600187
  var valid_600188 = query.getOrDefault("Unit")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_600188 != nil:
    section.add "Unit", valid_600188
  var valid_600189 = query.getOrDefault("ExtendedStatistic")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "ExtendedStatistic", valid_600189
  var valid_600190 = query.getOrDefault("Dimensions")
  valid_600190 = validateParameter(valid_600190, JArray, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "Dimensions", valid_600190
  var valid_600191 = query.getOrDefault("Action")
  valid_600191 = validateParameter(valid_600191, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_600191 != nil:
    section.add "Action", valid_600191
  var valid_600192 = query.getOrDefault("Period")
  valid_600192 = validateParameter(valid_600192, JInt, required = false, default = nil)
  if valid_600192 != nil:
    section.add "Period", valid_600192
  var valid_600193 = query.getOrDefault("MetricName")
  valid_600193 = validateParameter(valid_600193, JString, required = true,
                                 default = nil)
  if valid_600193 != nil:
    section.add "MetricName", valid_600193
  var valid_600194 = query.getOrDefault("Statistic")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_600194 != nil:
    section.add "Statistic", valid_600194
  var valid_600195 = query.getOrDefault("Version")
  valid_600195 = validateParameter(valid_600195, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600195 != nil:
    section.add "Version", valid_600195
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
  var valid_600196 = header.getOrDefault("X-Amz-Date")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Date", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Security-Token")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Security-Token", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Content-Sha256", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Algorithm")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Algorithm", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Signature")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Signature", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-SignedHeaders", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Credential")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Credential", valid_600202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600203: Call_GetDescribeAlarmsForMetric_600184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_600203.validator(path, query, header, formData, body)
  let scheme = call_600203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600203.url(scheme.get, call_600203.host, call_600203.base,
                         call_600203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600203, url, valid)

proc call*(call_600204: Call_GetDescribeAlarmsForMetric_600184; Namespace: string;
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
  var query_600205 = newJObject()
  add(query_600205, "Namespace", newJString(Namespace))
  add(query_600205, "Unit", newJString(Unit))
  add(query_600205, "ExtendedStatistic", newJString(ExtendedStatistic))
  if Dimensions != nil:
    query_600205.add "Dimensions", Dimensions
  add(query_600205, "Action", newJString(Action))
  add(query_600205, "Period", newJInt(Period))
  add(query_600205, "MetricName", newJString(MetricName))
  add(query_600205, "Statistic", newJString(Statistic))
  add(query_600205, "Version", newJString(Version))
  result = call_600204.call(nil, query_600205, nil, nil, nil)

var getDescribeAlarmsForMetric* = Call_GetDescribeAlarmsForMetric_600184(
    name: "getDescribeAlarmsForMetric", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_GetDescribeAlarmsForMetric_600185, base: "/",
    url: url_GetDescribeAlarmsForMetric_600186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnomalyDetectors_600249 = ref object of OpenApiRestCall_599368
proc url_PostDescribeAnomalyDetectors_600251(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAnomalyDetectors_600250(path: JsonNode; query: JsonNode;
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
  var valid_600252 = query.getOrDefault("Action")
  valid_600252 = validateParameter(valid_600252, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_600252 != nil:
    section.add "Action", valid_600252
  var valid_600253 = query.getOrDefault("Version")
  valid_600253 = validateParameter(valid_600253, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600253 != nil:
    section.add "Version", valid_600253
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
  var valid_600254 = header.getOrDefault("X-Amz-Date")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Date", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Security-Token")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Security-Token", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-Content-Sha256", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-Algorithm")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Algorithm", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Signature")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Signature", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-SignedHeaders", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Credential")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Credential", valid_600260
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
  var valid_600261 = formData.getOrDefault("NextToken")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "NextToken", valid_600261
  var valid_600262 = formData.getOrDefault("MaxResults")
  valid_600262 = validateParameter(valid_600262, JInt, required = false, default = nil)
  if valid_600262 != nil:
    section.add "MaxResults", valid_600262
  var valid_600263 = formData.getOrDefault("MetricName")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "MetricName", valid_600263
  var valid_600264 = formData.getOrDefault("Dimensions")
  valid_600264 = validateParameter(valid_600264, JArray, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "Dimensions", valid_600264
  var valid_600265 = formData.getOrDefault("Namespace")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "Namespace", valid_600265
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600266: Call_PostDescribeAnomalyDetectors_600249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_600266.validator(path, query, header, formData, body)
  let scheme = call_600266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600266.url(scheme.get, call_600266.host, call_600266.base,
                         call_600266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600266, url, valid)

proc call*(call_600267: Call_PostDescribeAnomalyDetectors_600249;
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
  var query_600268 = newJObject()
  var formData_600269 = newJObject()
  add(formData_600269, "NextToken", newJString(NextToken))
  add(formData_600269, "MaxResults", newJInt(MaxResults))
  add(formData_600269, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_600269.add "Dimensions", Dimensions
  add(query_600268, "Action", newJString(Action))
  add(formData_600269, "Namespace", newJString(Namespace))
  add(query_600268, "Version", newJString(Version))
  result = call_600267.call(nil, query_600268, nil, formData_600269, nil)

var postDescribeAnomalyDetectors* = Call_PostDescribeAnomalyDetectors_600249(
    name: "postDescribeAnomalyDetectors", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_PostDescribeAnomalyDetectors_600250, base: "/",
    url: url_PostDescribeAnomalyDetectors_600251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnomalyDetectors_600229 = ref object of OpenApiRestCall_599368
proc url_GetDescribeAnomalyDetectors_600231(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAnomalyDetectors_600230(path: JsonNode; query: JsonNode;
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
  var valid_600232 = query.getOrDefault("Namespace")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "Namespace", valid_600232
  var valid_600233 = query.getOrDefault("Dimensions")
  valid_600233 = validateParameter(valid_600233, JArray, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "Dimensions", valid_600233
  var valid_600234 = query.getOrDefault("NextToken")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "NextToken", valid_600234
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600235 = query.getOrDefault("Action")
  valid_600235 = validateParameter(valid_600235, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_600235 != nil:
    section.add "Action", valid_600235
  var valid_600236 = query.getOrDefault("Version")
  valid_600236 = validateParameter(valid_600236, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600236 != nil:
    section.add "Version", valid_600236
  var valid_600237 = query.getOrDefault("MetricName")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "MetricName", valid_600237
  var valid_600238 = query.getOrDefault("MaxResults")
  valid_600238 = validateParameter(valid_600238, JInt, required = false, default = nil)
  if valid_600238 != nil:
    section.add "MaxResults", valid_600238
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
  var valid_600239 = header.getOrDefault("X-Amz-Date")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Date", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Security-Token")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Security-Token", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Content-Sha256", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Algorithm")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Algorithm", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Signature")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Signature", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-SignedHeaders", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Credential")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Credential", valid_600245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600246: Call_GetDescribeAnomalyDetectors_600229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_600246.validator(path, query, header, formData, body)
  let scheme = call_600246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600246.url(scheme.get, call_600246.host, call_600246.base,
                         call_600246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600246, url, valid)

proc call*(call_600247: Call_GetDescribeAnomalyDetectors_600229;
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
  var query_600248 = newJObject()
  add(query_600248, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_600248.add "Dimensions", Dimensions
  add(query_600248, "NextToken", newJString(NextToken))
  add(query_600248, "Action", newJString(Action))
  add(query_600248, "Version", newJString(Version))
  add(query_600248, "MetricName", newJString(MetricName))
  add(query_600248, "MaxResults", newJInt(MaxResults))
  result = call_600247.call(nil, query_600248, nil, nil, nil)

var getDescribeAnomalyDetectors* = Call_GetDescribeAnomalyDetectors_600229(
    name: "getDescribeAnomalyDetectors", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_GetDescribeAnomalyDetectors_600230, base: "/",
    url: url_GetDescribeAnomalyDetectors_600231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInsightRules_600287 = ref object of OpenApiRestCall_599368
proc url_PostDescribeInsightRules_600289(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeInsightRules_600288(path: JsonNode; query: JsonNode;
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
  var valid_600290 = query.getOrDefault("Action")
  valid_600290 = validateParameter(valid_600290, JString, required = true,
                                 default = newJString("DescribeInsightRules"))
  if valid_600290 != nil:
    section.add "Action", valid_600290
  var valid_600291 = query.getOrDefault("Version")
  valid_600291 = validateParameter(valid_600291, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600291 != nil:
    section.add "Version", valid_600291
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
  var valid_600292 = header.getOrDefault("X-Amz-Date")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Date", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Security-Token")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Security-Token", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Content-Sha256", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Algorithm")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Algorithm", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Signature")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Signature", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-SignedHeaders", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Credential")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Credential", valid_600298
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Reserved for future use.
  ##   MaxResults: JInt
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  section = newJObject()
  var valid_600299 = formData.getOrDefault("NextToken")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "NextToken", valid_600299
  var valid_600300 = formData.getOrDefault("MaxResults")
  valid_600300 = validateParameter(valid_600300, JInt, required = false, default = nil)
  if valid_600300 != nil:
    section.add "MaxResults", valid_600300
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600301: Call_PostDescribeInsightRules_600287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_600301.validator(path, query, header, formData, body)
  let scheme = call_600301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600301.url(scheme.get, call_600301.host, call_600301.base,
                         call_600301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600301, url, valid)

proc call*(call_600302: Call_PostDescribeInsightRules_600287;
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
  var query_600303 = newJObject()
  var formData_600304 = newJObject()
  add(formData_600304, "NextToken", newJString(NextToken))
  add(formData_600304, "MaxResults", newJInt(MaxResults))
  add(query_600303, "Action", newJString(Action))
  add(query_600303, "Version", newJString(Version))
  result = call_600302.call(nil, query_600303, nil, formData_600304, nil)

var postDescribeInsightRules* = Call_PostDescribeInsightRules_600287(
    name: "postDescribeInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_PostDescribeInsightRules_600288, base: "/",
    url: url_PostDescribeInsightRules_600289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInsightRules_600270 = ref object of OpenApiRestCall_599368
proc url_GetDescribeInsightRules_600272(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeInsightRules_600271(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600273 = query.getOrDefault("NextToken")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "NextToken", valid_600273
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600274 = query.getOrDefault("Action")
  valid_600274 = validateParameter(valid_600274, JString, required = true,
                                 default = newJString("DescribeInsightRules"))
  if valid_600274 != nil:
    section.add "Action", valid_600274
  var valid_600275 = query.getOrDefault("Version")
  valid_600275 = validateParameter(valid_600275, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600275 != nil:
    section.add "Version", valid_600275
  var valid_600276 = query.getOrDefault("MaxResults")
  valid_600276 = validateParameter(valid_600276, JInt, required = false, default = nil)
  if valid_600276 != nil:
    section.add "MaxResults", valid_600276
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
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Content-Sha256", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Algorithm")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Algorithm", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Signature")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Signature", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-SignedHeaders", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Credential")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Credential", valid_600283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600284: Call_GetDescribeInsightRules_600270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_600284.validator(path, query, header, formData, body)
  let scheme = call_600284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600284.url(scheme.get, call_600284.host, call_600284.base,
                         call_600284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600284, url, valid)

proc call*(call_600285: Call_GetDescribeInsightRules_600270;
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
  var query_600286 = newJObject()
  add(query_600286, "NextToken", newJString(NextToken))
  add(query_600286, "Action", newJString(Action))
  add(query_600286, "Version", newJString(Version))
  add(query_600286, "MaxResults", newJInt(MaxResults))
  result = call_600285.call(nil, query_600286, nil, nil, nil)

var getDescribeInsightRules* = Call_GetDescribeInsightRules_600270(
    name: "getDescribeInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_GetDescribeInsightRules_600271, base: "/",
    url: url_GetDescribeInsightRules_600272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAlarmActions_600321 = ref object of OpenApiRestCall_599368
proc url_PostDisableAlarmActions_600323(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDisableAlarmActions_600322(path: JsonNode; query: JsonNode;
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
  var valid_600324 = query.getOrDefault("Action")
  valid_600324 = validateParameter(valid_600324, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_600324 != nil:
    section.add "Action", valid_600324
  var valid_600325 = query.getOrDefault("Version")
  valid_600325 = validateParameter(valid_600325, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600325 != nil:
    section.add "Version", valid_600325
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
  var valid_600326 = header.getOrDefault("X-Amz-Date")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Date", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Security-Token")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Security-Token", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Content-Sha256", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Algorithm")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Algorithm", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Signature")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Signature", valid_600330
  var valid_600331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-SignedHeaders", valid_600331
  var valid_600332 = header.getOrDefault("X-Amz-Credential")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Credential", valid_600332
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_600333 = formData.getOrDefault("AlarmNames")
  valid_600333 = validateParameter(valid_600333, JArray, required = true, default = nil)
  if valid_600333 != nil:
    section.add "AlarmNames", valid_600333
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600334: Call_PostDisableAlarmActions_600321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_600334.validator(path, query, header, formData, body)
  let scheme = call_600334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600334.url(scheme.get, call_600334.host, call_600334.base,
                         call_600334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600334, url, valid)

proc call*(call_600335: Call_PostDisableAlarmActions_600321; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   Action: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Version: string (required)
  var query_600336 = newJObject()
  var formData_600337 = newJObject()
  add(query_600336, "Action", newJString(Action))
  if AlarmNames != nil:
    formData_600337.add "AlarmNames", AlarmNames
  add(query_600336, "Version", newJString(Version))
  result = call_600335.call(nil, query_600336, nil, formData_600337, nil)

var postDisableAlarmActions* = Call_PostDisableAlarmActions_600321(
    name: "postDisableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_PostDisableAlarmActions_600322, base: "/",
    url: url_PostDisableAlarmActions_600323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAlarmActions_600305 = ref object of OpenApiRestCall_599368
proc url_GetDisableAlarmActions_600307(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisableAlarmActions_600306(path: JsonNode; query: JsonNode;
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
  var valid_600308 = query.getOrDefault("AlarmNames")
  valid_600308 = validateParameter(valid_600308, JArray, required = true, default = nil)
  if valid_600308 != nil:
    section.add "AlarmNames", valid_600308
  var valid_600309 = query.getOrDefault("Action")
  valid_600309 = validateParameter(valid_600309, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_600309 != nil:
    section.add "Action", valid_600309
  var valid_600310 = query.getOrDefault("Version")
  valid_600310 = validateParameter(valid_600310, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600310 != nil:
    section.add "Version", valid_600310
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
  var valid_600311 = header.getOrDefault("X-Amz-Date")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Date", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Security-Token")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Security-Token", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Content-Sha256", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Algorithm")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Algorithm", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Signature")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Signature", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-SignedHeaders", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-Credential")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Credential", valid_600317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600318: Call_GetDisableAlarmActions_600305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_600318.validator(path, query, header, formData, body)
  let scheme = call_600318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600318.url(scheme.get, call_600318.host, call_600318.base,
                         call_600318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600318, url, valid)

proc call*(call_600319: Call_GetDisableAlarmActions_600305; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600320 = newJObject()
  if AlarmNames != nil:
    query_600320.add "AlarmNames", AlarmNames
  add(query_600320, "Action", newJString(Action))
  add(query_600320, "Version", newJString(Version))
  result = call_600319.call(nil, query_600320, nil, nil, nil)

var getDisableAlarmActions* = Call_GetDisableAlarmActions_600305(
    name: "getDisableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_GetDisableAlarmActions_600306, base: "/",
    url: url_GetDisableAlarmActions_600307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableInsightRules_600354 = ref object of OpenApiRestCall_599368
proc url_PostDisableInsightRules_600356(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDisableInsightRules_600355(path: JsonNode; query: JsonNode;
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
  var valid_600357 = query.getOrDefault("Action")
  valid_600357 = validateParameter(valid_600357, JString, required = true,
                                 default = newJString("DisableInsightRules"))
  if valid_600357 != nil:
    section.add "Action", valid_600357
  var valid_600358 = query.getOrDefault("Version")
  valid_600358 = validateParameter(valid_600358, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600358 != nil:
    section.add "Version", valid_600358
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
  var valid_600359 = header.getOrDefault("X-Amz-Date")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Date", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Security-Token")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Security-Token", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Content-Sha256", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Algorithm")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Algorithm", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Signature")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Signature", valid_600363
  var valid_600364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-SignedHeaders", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-Credential")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Credential", valid_600365
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_600366 = formData.getOrDefault("RuleNames")
  valid_600366 = validateParameter(valid_600366, JArray, required = true, default = nil)
  if valid_600366 != nil:
    section.add "RuleNames", valid_600366
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600367: Call_PostDisableInsightRules_600354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_600367.validator(path, query, header, formData, body)
  let scheme = call_600367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600367.url(scheme.get, call_600367.host, call_600367.base,
                         call_600367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600367, url, valid)

proc call*(call_600368: Call_PostDisableInsightRules_600354; RuleNames: JsonNode;
          Action: string = "DisableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600369 = newJObject()
  var formData_600370 = newJObject()
  if RuleNames != nil:
    formData_600370.add "RuleNames", RuleNames
  add(query_600369, "Action", newJString(Action))
  add(query_600369, "Version", newJString(Version))
  result = call_600368.call(nil, query_600369, nil, formData_600370, nil)

var postDisableInsightRules* = Call_PostDisableInsightRules_600354(
    name: "postDisableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_PostDisableInsightRules_600355, base: "/",
    url: url_PostDisableInsightRules_600356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableInsightRules_600338 = ref object of OpenApiRestCall_599368
proc url_GetDisableInsightRules_600340(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisableInsightRules_600339(path: JsonNode; query: JsonNode;
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
  var valid_600341 = query.getOrDefault("Action")
  valid_600341 = validateParameter(valid_600341, JString, required = true,
                                 default = newJString("DisableInsightRules"))
  if valid_600341 != nil:
    section.add "Action", valid_600341
  var valid_600342 = query.getOrDefault("RuleNames")
  valid_600342 = validateParameter(valid_600342, JArray, required = true, default = nil)
  if valid_600342 != nil:
    section.add "RuleNames", valid_600342
  var valid_600343 = query.getOrDefault("Version")
  valid_600343 = validateParameter(valid_600343, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600343 != nil:
    section.add "Version", valid_600343
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
  var valid_600344 = header.getOrDefault("X-Amz-Date")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Date", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Security-Token")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Security-Token", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Content-Sha256", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Algorithm")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Algorithm", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Signature")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Signature", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-SignedHeaders", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Credential")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Credential", valid_600350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600351: Call_GetDisableInsightRules_600338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_600351.validator(path, query, header, formData, body)
  let scheme = call_600351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600351.url(scheme.get, call_600351.host, call_600351.base,
                         call_600351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600351, url, valid)

proc call*(call_600352: Call_GetDisableInsightRules_600338; RuleNames: JsonNode;
          Action: string = "DisableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_600353 = newJObject()
  add(query_600353, "Action", newJString(Action))
  if RuleNames != nil:
    query_600353.add "RuleNames", RuleNames
  add(query_600353, "Version", newJString(Version))
  result = call_600352.call(nil, query_600353, nil, nil, nil)

var getDisableInsightRules* = Call_GetDisableInsightRules_600338(
    name: "getDisableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_GetDisableInsightRules_600339, base: "/",
    url: url_GetDisableInsightRules_600340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAlarmActions_600387 = ref object of OpenApiRestCall_599368
proc url_PostEnableAlarmActions_600389(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostEnableAlarmActions_600388(path: JsonNode; query: JsonNode;
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
  var valid_600390 = query.getOrDefault("Action")
  valid_600390 = validateParameter(valid_600390, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_600390 != nil:
    section.add "Action", valid_600390
  var valid_600391 = query.getOrDefault("Version")
  valid_600391 = validateParameter(valid_600391, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600391 != nil:
    section.add "Version", valid_600391
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
  var valid_600392 = header.getOrDefault("X-Amz-Date")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Date", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Security-Token")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Security-Token", valid_600393
  var valid_600394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Content-Sha256", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-Algorithm")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Algorithm", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-Signature")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Signature", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-SignedHeaders", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Credential")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Credential", valid_600398
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_600399 = formData.getOrDefault("AlarmNames")
  valid_600399 = validateParameter(valid_600399, JArray, required = true, default = nil)
  if valid_600399 != nil:
    section.add "AlarmNames", valid_600399
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600400: Call_PostEnableAlarmActions_600387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_600400.validator(path, query, header, formData, body)
  let scheme = call_600400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600400.url(scheme.get, call_600400.host, call_600400.base,
                         call_600400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600400, url, valid)

proc call*(call_600401: Call_PostEnableAlarmActions_600387; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   Action: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Version: string (required)
  var query_600402 = newJObject()
  var formData_600403 = newJObject()
  add(query_600402, "Action", newJString(Action))
  if AlarmNames != nil:
    formData_600403.add "AlarmNames", AlarmNames
  add(query_600402, "Version", newJString(Version))
  result = call_600401.call(nil, query_600402, nil, formData_600403, nil)

var postEnableAlarmActions* = Call_PostEnableAlarmActions_600387(
    name: "postEnableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_PostEnableAlarmActions_600388, base: "/",
    url: url_PostEnableAlarmActions_600389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAlarmActions_600371 = ref object of OpenApiRestCall_599368
proc url_GetEnableAlarmActions_600373(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnableAlarmActions_600372(path: JsonNode; query: JsonNode;
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
  var valid_600374 = query.getOrDefault("AlarmNames")
  valid_600374 = validateParameter(valid_600374, JArray, required = true, default = nil)
  if valid_600374 != nil:
    section.add "AlarmNames", valid_600374
  var valid_600375 = query.getOrDefault("Action")
  valid_600375 = validateParameter(valid_600375, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_600375 != nil:
    section.add "Action", valid_600375
  var valid_600376 = query.getOrDefault("Version")
  valid_600376 = validateParameter(valid_600376, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600376 != nil:
    section.add "Version", valid_600376
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
  var valid_600377 = header.getOrDefault("X-Amz-Date")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Date", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Security-Token")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Security-Token", valid_600378
  var valid_600379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-Content-Sha256", valid_600379
  var valid_600380 = header.getOrDefault("X-Amz-Algorithm")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-Algorithm", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-Signature")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-Signature", valid_600381
  var valid_600382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-SignedHeaders", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Credential")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Credential", valid_600383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600384: Call_GetEnableAlarmActions_600371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_600384.validator(path, query, header, formData, body)
  let scheme = call_600384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600384.url(scheme.get, call_600384.host, call_600384.base,
                         call_600384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600384, url, valid)

proc call*(call_600385: Call_GetEnableAlarmActions_600371; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600386 = newJObject()
  if AlarmNames != nil:
    query_600386.add "AlarmNames", AlarmNames
  add(query_600386, "Action", newJString(Action))
  add(query_600386, "Version", newJString(Version))
  result = call_600385.call(nil, query_600386, nil, nil, nil)

var getEnableAlarmActions* = Call_GetEnableAlarmActions_600371(
    name: "getEnableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_GetEnableAlarmActions_600372, base: "/",
    url: url_GetEnableAlarmActions_600373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableInsightRules_600420 = ref object of OpenApiRestCall_599368
proc url_PostEnableInsightRules_600422(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostEnableInsightRules_600421(path: JsonNode; query: JsonNode;
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
  var valid_600423 = query.getOrDefault("Action")
  valid_600423 = validateParameter(valid_600423, JString, required = true,
                                 default = newJString("EnableInsightRules"))
  if valid_600423 != nil:
    section.add "Action", valid_600423
  var valid_600424 = query.getOrDefault("Version")
  valid_600424 = validateParameter(valid_600424, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600424 != nil:
    section.add "Version", valid_600424
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
  var valid_600425 = header.getOrDefault("X-Amz-Date")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-Date", valid_600425
  var valid_600426 = header.getOrDefault("X-Amz-Security-Token")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "X-Amz-Security-Token", valid_600426
  var valid_600427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Content-Sha256", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-Algorithm")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Algorithm", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Signature")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Signature", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-SignedHeaders", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Credential")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Credential", valid_600431
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_600432 = formData.getOrDefault("RuleNames")
  valid_600432 = validateParameter(valid_600432, JArray, required = true, default = nil)
  if valid_600432 != nil:
    section.add "RuleNames", valid_600432
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600433: Call_PostEnableInsightRules_600420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_600433.validator(path, query, header, formData, body)
  let scheme = call_600433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600433.url(scheme.get, call_600433.host, call_600433.base,
                         call_600433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600433, url, valid)

proc call*(call_600434: Call_PostEnableInsightRules_600420; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600435 = newJObject()
  var formData_600436 = newJObject()
  if RuleNames != nil:
    formData_600436.add "RuleNames", RuleNames
  add(query_600435, "Action", newJString(Action))
  add(query_600435, "Version", newJString(Version))
  result = call_600434.call(nil, query_600435, nil, formData_600436, nil)

var postEnableInsightRules* = Call_PostEnableInsightRules_600420(
    name: "postEnableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_PostEnableInsightRules_600421, base: "/",
    url: url_PostEnableInsightRules_600422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableInsightRules_600404 = ref object of OpenApiRestCall_599368
proc url_GetEnableInsightRules_600406(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnableInsightRules_600405(path: JsonNode; query: JsonNode;
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
  var valid_600407 = query.getOrDefault("Action")
  valid_600407 = validateParameter(valid_600407, JString, required = true,
                                 default = newJString("EnableInsightRules"))
  if valid_600407 != nil:
    section.add "Action", valid_600407
  var valid_600408 = query.getOrDefault("RuleNames")
  valid_600408 = validateParameter(valid_600408, JArray, required = true, default = nil)
  if valid_600408 != nil:
    section.add "RuleNames", valid_600408
  var valid_600409 = query.getOrDefault("Version")
  valid_600409 = validateParameter(valid_600409, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600409 != nil:
    section.add "Version", valid_600409
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
  var valid_600410 = header.getOrDefault("X-Amz-Date")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-Date", valid_600410
  var valid_600411 = header.getOrDefault("X-Amz-Security-Token")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Security-Token", valid_600411
  var valid_600412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Content-Sha256", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Algorithm")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Algorithm", valid_600413
  var valid_600414 = header.getOrDefault("X-Amz-Signature")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-Signature", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-SignedHeaders", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Credential")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Credential", valid_600416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600417: Call_GetEnableInsightRules_600404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_600417.validator(path, query, header, formData, body)
  let scheme = call_600417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600417.url(scheme.get, call_600417.host, call_600417.base,
                         call_600417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600417, url, valid)

proc call*(call_600418: Call_GetEnableInsightRules_600404; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_600419 = newJObject()
  add(query_600419, "Action", newJString(Action))
  if RuleNames != nil:
    query_600419.add "RuleNames", RuleNames
  add(query_600419, "Version", newJString(Version))
  result = call_600418.call(nil, query_600419, nil, nil, nil)

var getEnableInsightRules* = Call_GetEnableInsightRules_600404(
    name: "getEnableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_GetEnableInsightRules_600405, base: "/",
    url: url_GetEnableInsightRules_600406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetDashboard_600453 = ref object of OpenApiRestCall_599368
proc url_PostGetDashboard_600455(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetDashboard_600454(path: JsonNode; query: JsonNode;
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
  var valid_600456 = query.getOrDefault("Action")
  valid_600456 = validateParameter(valid_600456, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_600456 != nil:
    section.add "Action", valid_600456
  var valid_600457 = query.getOrDefault("Version")
  valid_600457 = validateParameter(valid_600457, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600457 != nil:
    section.add "Version", valid_600457
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
  var valid_600458 = header.getOrDefault("X-Amz-Date")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Date", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Security-Token")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Security-Token", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Content-Sha256", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Algorithm")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Algorithm", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Signature")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Signature", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-SignedHeaders", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Credential")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Credential", valid_600464
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_600465 = formData.getOrDefault("DashboardName")
  valid_600465 = validateParameter(valid_600465, JString, required = true,
                                 default = nil)
  if valid_600465 != nil:
    section.add "DashboardName", valid_600465
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600466: Call_PostGetDashboard_600453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_600466.validator(path, query, header, formData, body)
  let scheme = call_600466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600466.url(scheme.get, call_600466.host, call_600466.base,
                         call_600466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600466, url, valid)

proc call*(call_600467: Call_PostGetDashboard_600453; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## postGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Version: string (required)
  var query_600468 = newJObject()
  var formData_600469 = newJObject()
  add(query_600468, "Action", newJString(Action))
  add(formData_600469, "DashboardName", newJString(DashboardName))
  add(query_600468, "Version", newJString(Version))
  result = call_600467.call(nil, query_600468, nil, formData_600469, nil)

var postGetDashboard* = Call_PostGetDashboard_600453(name: "postGetDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_PostGetDashboard_600454,
    base: "/", url: url_PostGetDashboard_600455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetDashboard_600437 = ref object of OpenApiRestCall_599368
proc url_GetGetDashboard_600439(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetDashboard_600438(path: JsonNode; query: JsonNode;
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
  var valid_600440 = query.getOrDefault("DashboardName")
  valid_600440 = validateParameter(valid_600440, JString, required = true,
                                 default = nil)
  if valid_600440 != nil:
    section.add "DashboardName", valid_600440
  var valid_600441 = query.getOrDefault("Action")
  valid_600441 = validateParameter(valid_600441, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_600441 != nil:
    section.add "Action", valid_600441
  var valid_600442 = query.getOrDefault("Version")
  valid_600442 = validateParameter(valid_600442, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600442 != nil:
    section.add "Version", valid_600442
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
  var valid_600443 = header.getOrDefault("X-Amz-Date")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Date", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Security-Token")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Security-Token", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Content-Sha256", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-Algorithm")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Algorithm", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Signature")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Signature", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-SignedHeaders", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Credential")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Credential", valid_600449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600450: Call_GetGetDashboard_600437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_600450.validator(path, query, header, formData, body)
  let scheme = call_600450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600450.url(scheme.get, call_600450.host, call_600450.base,
                         call_600450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600450, url, valid)

proc call*(call_600451: Call_GetGetDashboard_600437; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## getGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600452 = newJObject()
  add(query_600452, "DashboardName", newJString(DashboardName))
  add(query_600452, "Action", newJString(Action))
  add(query_600452, "Version", newJString(Version))
  result = call_600451.call(nil, query_600452, nil, nil, nil)

var getGetDashboard* = Call_GetGetDashboard_600437(name: "getGetDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_GetGetDashboard_600438,
    base: "/", url: url_GetGetDashboard_600439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetInsightRuleReport_600492 = ref object of OpenApiRestCall_599368
proc url_PostGetInsightRuleReport_600494(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetInsightRuleReport_600493(path: JsonNode; query: JsonNode;
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
  var valid_600495 = query.getOrDefault("Action")
  valid_600495 = validateParameter(valid_600495, JString, required = true,
                                 default = newJString("GetInsightRuleReport"))
  if valid_600495 != nil:
    section.add "Action", valid_600495
  var valid_600496 = query.getOrDefault("Version")
  valid_600496 = validateParameter(valid_600496, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600496 != nil:
    section.add "Version", valid_600496
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
  var valid_600497 = header.getOrDefault("X-Amz-Date")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-Date", valid_600497
  var valid_600498 = header.getOrDefault("X-Amz-Security-Token")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Security-Token", valid_600498
  var valid_600499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Content-Sha256", valid_600499
  var valid_600500 = header.getOrDefault("X-Amz-Algorithm")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-Algorithm", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-Signature")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-Signature", valid_600501
  var valid_600502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-SignedHeaders", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Credential")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Credential", valid_600503
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
  var valid_600504 = formData.getOrDefault("Metrics")
  valid_600504 = validateParameter(valid_600504, JArray, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "Metrics", valid_600504
  var valid_600505 = formData.getOrDefault("MaxContributorCount")
  valid_600505 = validateParameter(valid_600505, JInt, required = false, default = nil)
  if valid_600505 != nil:
    section.add "MaxContributorCount", valid_600505
  assert formData != nil,
        "formData argument is necessary due to required `RuleName` field"
  var valid_600506 = formData.getOrDefault("RuleName")
  valid_600506 = validateParameter(valid_600506, JString, required = true,
                                 default = nil)
  if valid_600506 != nil:
    section.add "RuleName", valid_600506
  var valid_600507 = formData.getOrDefault("StartTime")
  valid_600507 = validateParameter(valid_600507, JString, required = true,
                                 default = nil)
  if valid_600507 != nil:
    section.add "StartTime", valid_600507
  var valid_600508 = formData.getOrDefault("OrderBy")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "OrderBy", valid_600508
  var valid_600509 = formData.getOrDefault("EndTime")
  valid_600509 = validateParameter(valid_600509, JString, required = true,
                                 default = nil)
  if valid_600509 != nil:
    section.add "EndTime", valid_600509
  var valid_600510 = formData.getOrDefault("Period")
  valid_600510 = validateParameter(valid_600510, JInt, required = true, default = nil)
  if valid_600510 != nil:
    section.add "Period", valid_600510
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600511: Call_PostGetInsightRuleReport_600492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_600511.validator(path, query, header, formData, body)
  let scheme = call_600511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600511.url(scheme.get, call_600511.host, call_600511.base,
                         call_600511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600511, url, valid)

proc call*(call_600512: Call_PostGetInsightRuleReport_600492; RuleName: string;
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
  var query_600513 = newJObject()
  var formData_600514 = newJObject()
  if Metrics != nil:
    formData_600514.add "Metrics", Metrics
  add(formData_600514, "MaxContributorCount", newJInt(MaxContributorCount))
  add(formData_600514, "RuleName", newJString(RuleName))
  add(formData_600514, "StartTime", newJString(StartTime))
  add(query_600513, "Action", newJString(Action))
  add(formData_600514, "OrderBy", newJString(OrderBy))
  add(formData_600514, "EndTime", newJString(EndTime))
  add(query_600513, "Version", newJString(Version))
  add(formData_600514, "Period", newJInt(Period))
  result = call_600512.call(nil, query_600513, nil, formData_600514, nil)

var postGetInsightRuleReport* = Call_PostGetInsightRuleReport_600492(
    name: "postGetInsightRuleReport", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_PostGetInsightRuleReport_600493, base: "/",
    url: url_PostGetInsightRuleReport_600494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetInsightRuleReport_600470 = ref object of OpenApiRestCall_599368
proc url_GetGetInsightRuleReport_600472(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetInsightRuleReport_600471(path: JsonNode; query: JsonNode;
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
  var valid_600473 = query.getOrDefault("RuleName")
  valid_600473 = validateParameter(valid_600473, JString, required = true,
                                 default = nil)
  if valid_600473 != nil:
    section.add "RuleName", valid_600473
  var valid_600474 = query.getOrDefault("StartTime")
  valid_600474 = validateParameter(valid_600474, JString, required = true,
                                 default = nil)
  if valid_600474 != nil:
    section.add "StartTime", valid_600474
  var valid_600475 = query.getOrDefault("Action")
  valid_600475 = validateParameter(valid_600475, JString, required = true,
                                 default = newJString("GetInsightRuleReport"))
  if valid_600475 != nil:
    section.add "Action", valid_600475
  var valid_600476 = query.getOrDefault("Metrics")
  valid_600476 = validateParameter(valid_600476, JArray, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "Metrics", valid_600476
  var valid_600477 = query.getOrDefault("OrderBy")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "OrderBy", valid_600477
  var valid_600478 = query.getOrDefault("EndTime")
  valid_600478 = validateParameter(valid_600478, JString, required = true,
                                 default = nil)
  if valid_600478 != nil:
    section.add "EndTime", valid_600478
  var valid_600479 = query.getOrDefault("Period")
  valid_600479 = validateParameter(valid_600479, JInt, required = true, default = nil)
  if valid_600479 != nil:
    section.add "Period", valid_600479
  var valid_600480 = query.getOrDefault("MaxContributorCount")
  valid_600480 = validateParameter(valid_600480, JInt, required = false, default = nil)
  if valid_600480 != nil:
    section.add "MaxContributorCount", valid_600480
  var valid_600481 = query.getOrDefault("Version")
  valid_600481 = validateParameter(valid_600481, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600481 != nil:
    section.add "Version", valid_600481
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
  var valid_600482 = header.getOrDefault("X-Amz-Date")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Date", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-Security-Token")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Security-Token", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-Content-Sha256", valid_600484
  var valid_600485 = header.getOrDefault("X-Amz-Algorithm")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-Algorithm", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-Signature")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Signature", valid_600486
  var valid_600487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-SignedHeaders", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Credential")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Credential", valid_600488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600489: Call_GetGetInsightRuleReport_600470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_600489.validator(path, query, header, formData, body)
  let scheme = call_600489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600489.url(scheme.get, call_600489.host, call_600489.base,
                         call_600489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600489, url, valid)

proc call*(call_600490: Call_GetGetInsightRuleReport_600470; RuleName: string;
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
  var query_600491 = newJObject()
  add(query_600491, "RuleName", newJString(RuleName))
  add(query_600491, "StartTime", newJString(StartTime))
  add(query_600491, "Action", newJString(Action))
  if Metrics != nil:
    query_600491.add "Metrics", Metrics
  add(query_600491, "OrderBy", newJString(OrderBy))
  add(query_600491, "EndTime", newJString(EndTime))
  add(query_600491, "Period", newJInt(Period))
  add(query_600491, "MaxContributorCount", newJInt(MaxContributorCount))
  add(query_600491, "Version", newJString(Version))
  result = call_600490.call(nil, query_600491, nil, nil, nil)

var getGetInsightRuleReport* = Call_GetGetInsightRuleReport_600470(
    name: "getGetInsightRuleReport", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_GetGetInsightRuleReport_600471, base: "/",
    url: url_GetGetInsightRuleReport_600472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricData_600536 = ref object of OpenApiRestCall_599368
proc url_PostGetMetricData_600538(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetMetricData_600537(path: JsonNode; query: JsonNode;
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
  var valid_600539 = query.getOrDefault("Action")
  valid_600539 = validateParameter(valid_600539, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_600539 != nil:
    section.add "Action", valid_600539
  var valid_600540 = query.getOrDefault("Version")
  valid_600540 = validateParameter(valid_600540, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600540 != nil:
    section.add "Version", valid_600540
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
  var valid_600541 = header.getOrDefault("X-Amz-Date")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Date", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-Security-Token")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Security-Token", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Content-Sha256", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Algorithm")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Algorithm", valid_600544
  var valid_600545 = header.getOrDefault("X-Amz-Signature")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-Signature", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-SignedHeaders", valid_600546
  var valid_600547 = header.getOrDefault("X-Amz-Credential")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-Credential", valid_600547
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
  var valid_600548 = formData.getOrDefault("NextToken")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "NextToken", valid_600548
  var valid_600549 = formData.getOrDefault("ScanBy")
  valid_600549 = validateParameter(valid_600549, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_600549 != nil:
    section.add "ScanBy", valid_600549
  assert formData != nil,
        "formData argument is necessary due to required `StartTime` field"
  var valid_600550 = formData.getOrDefault("StartTime")
  valid_600550 = validateParameter(valid_600550, JString, required = true,
                                 default = nil)
  if valid_600550 != nil:
    section.add "StartTime", valid_600550
  var valid_600551 = formData.getOrDefault("EndTime")
  valid_600551 = validateParameter(valid_600551, JString, required = true,
                                 default = nil)
  if valid_600551 != nil:
    section.add "EndTime", valid_600551
  var valid_600552 = formData.getOrDefault("MetricDataQueries")
  valid_600552 = validateParameter(valid_600552, JArray, required = true, default = nil)
  if valid_600552 != nil:
    section.add "MetricDataQueries", valid_600552
  var valid_600553 = formData.getOrDefault("MaxDatapoints")
  valid_600553 = validateParameter(valid_600553, JInt, required = false, default = nil)
  if valid_600553 != nil:
    section.add "MaxDatapoints", valid_600553
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600554: Call_PostGetMetricData_600536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_600554.validator(path, query, header, formData, body)
  let scheme = call_600554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600554.url(scheme.get, call_600554.host, call_600554.base,
                         call_600554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600554, url, valid)

proc call*(call_600555: Call_PostGetMetricData_600536; StartTime: string;
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
  var query_600556 = newJObject()
  var formData_600557 = newJObject()
  add(formData_600557, "NextToken", newJString(NextToken))
  add(formData_600557, "ScanBy", newJString(ScanBy))
  add(formData_600557, "StartTime", newJString(StartTime))
  add(query_600556, "Action", newJString(Action))
  add(formData_600557, "EndTime", newJString(EndTime))
  if MetricDataQueries != nil:
    formData_600557.add "MetricDataQueries", MetricDataQueries
  add(formData_600557, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_600556, "Version", newJString(Version))
  result = call_600555.call(nil, query_600556, nil, formData_600557, nil)

var postGetMetricData* = Call_PostGetMetricData_600536(name: "postGetMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_PostGetMetricData_600537,
    base: "/", url: url_PostGetMetricData_600538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricData_600515 = ref object of OpenApiRestCall_599368
proc url_GetGetMetricData_600517(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetMetricData_600516(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_600518 = query.getOrDefault("MaxDatapoints")
  valid_600518 = validateParameter(valid_600518, JInt, required = false, default = nil)
  if valid_600518 != nil:
    section.add "MaxDatapoints", valid_600518
  var valid_600519 = query.getOrDefault("ScanBy")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_600519 != nil:
    section.add "ScanBy", valid_600519
  assert query != nil,
        "query argument is necessary due to required `StartTime` field"
  var valid_600520 = query.getOrDefault("StartTime")
  valid_600520 = validateParameter(valid_600520, JString, required = true,
                                 default = nil)
  if valid_600520 != nil:
    section.add "StartTime", valid_600520
  var valid_600521 = query.getOrDefault("NextToken")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "NextToken", valid_600521
  var valid_600522 = query.getOrDefault("Action")
  valid_600522 = validateParameter(valid_600522, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_600522 != nil:
    section.add "Action", valid_600522
  var valid_600523 = query.getOrDefault("MetricDataQueries")
  valid_600523 = validateParameter(valid_600523, JArray, required = true, default = nil)
  if valid_600523 != nil:
    section.add "MetricDataQueries", valid_600523
  var valid_600524 = query.getOrDefault("EndTime")
  valid_600524 = validateParameter(valid_600524, JString, required = true,
                                 default = nil)
  if valid_600524 != nil:
    section.add "EndTime", valid_600524
  var valid_600525 = query.getOrDefault("Version")
  valid_600525 = validateParameter(valid_600525, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600525 != nil:
    section.add "Version", valid_600525
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
  var valid_600526 = header.getOrDefault("X-Amz-Date")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Date", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-Security-Token")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Security-Token", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Content-Sha256", valid_600528
  var valid_600529 = header.getOrDefault("X-Amz-Algorithm")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amz-Algorithm", valid_600529
  var valid_600530 = header.getOrDefault("X-Amz-Signature")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-Signature", valid_600530
  var valid_600531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "X-Amz-SignedHeaders", valid_600531
  var valid_600532 = header.getOrDefault("X-Amz-Credential")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Credential", valid_600532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600533: Call_GetGetMetricData_600515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_600533.validator(path, query, header, formData, body)
  let scheme = call_600533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600533.url(scheme.get, call_600533.host, call_600533.base,
                         call_600533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600533, url, valid)

proc call*(call_600534: Call_GetGetMetricData_600515; StartTime: string;
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
  var query_600535 = newJObject()
  add(query_600535, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_600535, "ScanBy", newJString(ScanBy))
  add(query_600535, "StartTime", newJString(StartTime))
  add(query_600535, "NextToken", newJString(NextToken))
  add(query_600535, "Action", newJString(Action))
  if MetricDataQueries != nil:
    query_600535.add "MetricDataQueries", MetricDataQueries
  add(query_600535, "EndTime", newJString(EndTime))
  add(query_600535, "Version", newJString(Version))
  result = call_600534.call(nil, query_600535, nil, nil, nil)

var getGetMetricData* = Call_GetGetMetricData_600515(name: "getGetMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_GetGetMetricData_600516,
    base: "/", url: url_GetGetMetricData_600517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricStatistics_600582 = ref object of OpenApiRestCall_599368
proc url_PostGetMetricStatistics_600584(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetMetricStatistics_600583(path: JsonNode; query: JsonNode;
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
  var valid_600585 = query.getOrDefault("Action")
  valid_600585 = validateParameter(valid_600585, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_600585 != nil:
    section.add "Action", valid_600585
  var valid_600586 = query.getOrDefault("Version")
  valid_600586 = validateParameter(valid_600586, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600586 != nil:
    section.add "Version", valid_600586
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
  var valid_600587 = header.getOrDefault("X-Amz-Date")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Date", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Security-Token")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Security-Token", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Content-Sha256", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Algorithm")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Algorithm", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Signature")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Signature", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-SignedHeaders", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Credential")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Credential", valid_600593
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
  var valid_600594 = formData.getOrDefault("Statistics")
  valid_600594 = validateParameter(valid_600594, JArray, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "Statistics", valid_600594
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_600595 = formData.getOrDefault("MetricName")
  valid_600595 = validateParameter(valid_600595, JString, required = true,
                                 default = nil)
  if valid_600595 != nil:
    section.add "MetricName", valid_600595
  var valid_600596 = formData.getOrDefault("Dimensions")
  valid_600596 = validateParameter(valid_600596, JArray, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "Dimensions", valid_600596
  var valid_600597 = formData.getOrDefault("StartTime")
  valid_600597 = validateParameter(valid_600597, JString, required = true,
                                 default = nil)
  if valid_600597 != nil:
    section.add "StartTime", valid_600597
  var valid_600598 = formData.getOrDefault("Namespace")
  valid_600598 = validateParameter(valid_600598, JString, required = true,
                                 default = nil)
  if valid_600598 != nil:
    section.add "Namespace", valid_600598
  var valid_600599 = formData.getOrDefault("ExtendedStatistics")
  valid_600599 = validateParameter(valid_600599, JArray, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "ExtendedStatistics", valid_600599
  var valid_600600 = formData.getOrDefault("EndTime")
  valid_600600 = validateParameter(valid_600600, JString, required = true,
                                 default = nil)
  if valid_600600 != nil:
    section.add "EndTime", valid_600600
  var valid_600601 = formData.getOrDefault("Unit")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_600601 != nil:
    section.add "Unit", valid_600601
  var valid_600602 = formData.getOrDefault("Period")
  valid_600602 = validateParameter(valid_600602, JInt, required = true, default = nil)
  if valid_600602 != nil:
    section.add "Period", valid_600602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600603: Call_PostGetMetricStatistics_600582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_600603.validator(path, query, header, formData, body)
  let scheme = call_600603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600603.url(scheme.get, call_600603.host, call_600603.base,
                         call_600603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600603, url, valid)

proc call*(call_600604: Call_PostGetMetricStatistics_600582; MetricName: string;
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
  var query_600605 = newJObject()
  var formData_600606 = newJObject()
  if Statistics != nil:
    formData_600606.add "Statistics", Statistics
  add(formData_600606, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_600606.add "Dimensions", Dimensions
  add(formData_600606, "StartTime", newJString(StartTime))
  add(query_600605, "Action", newJString(Action))
  add(formData_600606, "Namespace", newJString(Namespace))
  if ExtendedStatistics != nil:
    formData_600606.add "ExtendedStatistics", ExtendedStatistics
  add(formData_600606, "EndTime", newJString(EndTime))
  add(formData_600606, "Unit", newJString(Unit))
  add(query_600605, "Version", newJString(Version))
  add(formData_600606, "Period", newJInt(Period))
  result = call_600604.call(nil, query_600605, nil, formData_600606, nil)

var postGetMetricStatistics* = Call_PostGetMetricStatistics_600582(
    name: "postGetMetricStatistics", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_PostGetMetricStatistics_600583, base: "/",
    url: url_PostGetMetricStatistics_600584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricStatistics_600558 = ref object of OpenApiRestCall_599368
proc url_GetGetMetricStatistics_600560(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetMetricStatistics_600559(path: JsonNode; query: JsonNode;
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
  var valid_600561 = query.getOrDefault("Namespace")
  valid_600561 = validateParameter(valid_600561, JString, required = true,
                                 default = nil)
  if valid_600561 != nil:
    section.add "Namespace", valid_600561
  var valid_600562 = query.getOrDefault("Unit")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_600562 != nil:
    section.add "Unit", valid_600562
  var valid_600563 = query.getOrDefault("StartTime")
  valid_600563 = validateParameter(valid_600563, JString, required = true,
                                 default = nil)
  if valid_600563 != nil:
    section.add "StartTime", valid_600563
  var valid_600564 = query.getOrDefault("Dimensions")
  valid_600564 = validateParameter(valid_600564, JArray, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "Dimensions", valid_600564
  var valid_600565 = query.getOrDefault("Action")
  valid_600565 = validateParameter(valid_600565, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_600565 != nil:
    section.add "Action", valid_600565
  var valid_600566 = query.getOrDefault("ExtendedStatistics")
  valid_600566 = validateParameter(valid_600566, JArray, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "ExtendedStatistics", valid_600566
  var valid_600567 = query.getOrDefault("Statistics")
  valid_600567 = validateParameter(valid_600567, JArray, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "Statistics", valid_600567
  var valid_600568 = query.getOrDefault("EndTime")
  valid_600568 = validateParameter(valid_600568, JString, required = true,
                                 default = nil)
  if valid_600568 != nil:
    section.add "EndTime", valid_600568
  var valid_600569 = query.getOrDefault("Period")
  valid_600569 = validateParameter(valid_600569, JInt, required = true, default = nil)
  if valid_600569 != nil:
    section.add "Period", valid_600569
  var valid_600570 = query.getOrDefault("MetricName")
  valid_600570 = validateParameter(valid_600570, JString, required = true,
                                 default = nil)
  if valid_600570 != nil:
    section.add "MetricName", valid_600570
  var valid_600571 = query.getOrDefault("Version")
  valid_600571 = validateParameter(valid_600571, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600571 != nil:
    section.add "Version", valid_600571
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
  var valid_600572 = header.getOrDefault("X-Amz-Date")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Date", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-Security-Token")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Security-Token", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Content-Sha256", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-Algorithm")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Algorithm", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Signature")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Signature", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-SignedHeaders", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Credential")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Credential", valid_600578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600579: Call_GetGetMetricStatistics_600558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_600579.validator(path, query, header, formData, body)
  let scheme = call_600579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600579.url(scheme.get, call_600579.host, call_600579.base,
                         call_600579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600579, url, valid)

proc call*(call_600580: Call_GetGetMetricStatistics_600558; Namespace: string;
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
  var query_600581 = newJObject()
  add(query_600581, "Namespace", newJString(Namespace))
  add(query_600581, "Unit", newJString(Unit))
  add(query_600581, "StartTime", newJString(StartTime))
  if Dimensions != nil:
    query_600581.add "Dimensions", Dimensions
  add(query_600581, "Action", newJString(Action))
  if ExtendedStatistics != nil:
    query_600581.add "ExtendedStatistics", ExtendedStatistics
  if Statistics != nil:
    query_600581.add "Statistics", Statistics
  add(query_600581, "EndTime", newJString(EndTime))
  add(query_600581, "Period", newJInt(Period))
  add(query_600581, "MetricName", newJString(MetricName))
  add(query_600581, "Version", newJString(Version))
  result = call_600580.call(nil, query_600581, nil, nil, nil)

var getGetMetricStatistics* = Call_GetGetMetricStatistics_600558(
    name: "getGetMetricStatistics", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_GetGetMetricStatistics_600559, base: "/",
    url: url_GetGetMetricStatistics_600560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricWidgetImage_600624 = ref object of OpenApiRestCall_599368
proc url_PostGetMetricWidgetImage_600626(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetMetricWidgetImage_600625(path: JsonNode; query: JsonNode;
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
  var valid_600627 = query.getOrDefault("Action")
  valid_600627 = validateParameter(valid_600627, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_600627 != nil:
    section.add "Action", valid_600627
  var valid_600628 = query.getOrDefault("Version")
  valid_600628 = validateParameter(valid_600628, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600628 != nil:
    section.add "Version", valid_600628
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
  var valid_600629 = header.getOrDefault("X-Amz-Date")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Date", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-Security-Token")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-Security-Token", valid_600630
  var valid_600631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600631 = validateParameter(valid_600631, JString, required = false,
                                 default = nil)
  if valid_600631 != nil:
    section.add "X-Amz-Content-Sha256", valid_600631
  var valid_600632 = header.getOrDefault("X-Amz-Algorithm")
  valid_600632 = validateParameter(valid_600632, JString, required = false,
                                 default = nil)
  if valid_600632 != nil:
    section.add "X-Amz-Algorithm", valid_600632
  var valid_600633 = header.getOrDefault("X-Amz-Signature")
  valid_600633 = validateParameter(valid_600633, JString, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "X-Amz-Signature", valid_600633
  var valid_600634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-SignedHeaders", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-Credential")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Credential", valid_600635
  result.add "header", section
  ## parameters in `formData` object:
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  section = newJObject()
  var valid_600636 = formData.getOrDefault("OutputFormat")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "OutputFormat", valid_600636
  assert formData != nil,
        "formData argument is necessary due to required `MetricWidget` field"
  var valid_600637 = formData.getOrDefault("MetricWidget")
  valid_600637 = validateParameter(valid_600637, JString, required = true,
                                 default = nil)
  if valid_600637 != nil:
    section.add "MetricWidget", valid_600637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600638: Call_PostGetMetricWidgetImage_600624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_600638.validator(path, query, header, formData, body)
  let scheme = call_600638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600638.url(scheme.get, call_600638.host, call_600638.base,
                         call_600638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600638, url, valid)

proc call*(call_600639: Call_PostGetMetricWidgetImage_600624; MetricWidget: string;
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
  var query_600640 = newJObject()
  var formData_600641 = newJObject()
  add(formData_600641, "OutputFormat", newJString(OutputFormat))
  add(formData_600641, "MetricWidget", newJString(MetricWidget))
  add(query_600640, "Action", newJString(Action))
  add(query_600640, "Version", newJString(Version))
  result = call_600639.call(nil, query_600640, nil, formData_600641, nil)

var postGetMetricWidgetImage* = Call_PostGetMetricWidgetImage_600624(
    name: "postGetMetricWidgetImage", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_PostGetMetricWidgetImage_600625, base: "/",
    url: url_PostGetMetricWidgetImage_600626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricWidgetImage_600607 = ref object of OpenApiRestCall_599368
proc url_GetGetMetricWidgetImage_600609(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetMetricWidgetImage_600608(path: JsonNode; query: JsonNode;
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
  var valid_600610 = query.getOrDefault("MetricWidget")
  valid_600610 = validateParameter(valid_600610, JString, required = true,
                                 default = nil)
  if valid_600610 != nil:
    section.add "MetricWidget", valid_600610
  var valid_600611 = query.getOrDefault("OutputFormat")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "OutputFormat", valid_600611
  var valid_600612 = query.getOrDefault("Action")
  valid_600612 = validateParameter(valid_600612, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_600612 != nil:
    section.add "Action", valid_600612
  var valid_600613 = query.getOrDefault("Version")
  valid_600613 = validateParameter(valid_600613, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600613 != nil:
    section.add "Version", valid_600613
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
  var valid_600614 = header.getOrDefault("X-Amz-Date")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Date", valid_600614
  var valid_600615 = header.getOrDefault("X-Amz-Security-Token")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "X-Amz-Security-Token", valid_600615
  var valid_600616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600616 = validateParameter(valid_600616, JString, required = false,
                                 default = nil)
  if valid_600616 != nil:
    section.add "X-Amz-Content-Sha256", valid_600616
  var valid_600617 = header.getOrDefault("X-Amz-Algorithm")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "X-Amz-Algorithm", valid_600617
  var valid_600618 = header.getOrDefault("X-Amz-Signature")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "X-Amz-Signature", valid_600618
  var valid_600619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-SignedHeaders", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-Credential")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Credential", valid_600620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600621: Call_GetGetMetricWidgetImage_600607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_600621.validator(path, query, header, formData, body)
  let scheme = call_600621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600621.url(scheme.get, call_600621.host, call_600621.base,
                         call_600621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600621, url, valid)

proc call*(call_600622: Call_GetGetMetricWidgetImage_600607; MetricWidget: string;
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
  var query_600623 = newJObject()
  add(query_600623, "MetricWidget", newJString(MetricWidget))
  add(query_600623, "OutputFormat", newJString(OutputFormat))
  add(query_600623, "Action", newJString(Action))
  add(query_600623, "Version", newJString(Version))
  result = call_600622.call(nil, query_600623, nil, nil, nil)

var getGetMetricWidgetImage* = Call_GetGetMetricWidgetImage_600607(
    name: "getGetMetricWidgetImage", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_GetGetMetricWidgetImage_600608, base: "/",
    url: url_GetGetMetricWidgetImage_600609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDashboards_600659 = ref object of OpenApiRestCall_599368
proc url_PostListDashboards_600661(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListDashboards_600660(path: JsonNode; query: JsonNode;
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
  var valid_600662 = query.getOrDefault("Action")
  valid_600662 = validateParameter(valid_600662, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_600662 != nil:
    section.add "Action", valid_600662
  var valid_600663 = query.getOrDefault("Version")
  valid_600663 = validateParameter(valid_600663, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600663 != nil:
    section.add "Version", valid_600663
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
  var valid_600664 = header.getOrDefault("X-Amz-Date")
  valid_600664 = validateParameter(valid_600664, JString, required = false,
                                 default = nil)
  if valid_600664 != nil:
    section.add "X-Amz-Date", valid_600664
  var valid_600665 = header.getOrDefault("X-Amz-Security-Token")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-Security-Token", valid_600665
  var valid_600666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-Content-Sha256", valid_600666
  var valid_600667 = header.getOrDefault("X-Amz-Algorithm")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Algorithm", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Signature")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Signature", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-SignedHeaders", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Credential")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Credential", valid_600670
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   DashboardNamePrefix: JString
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  section = newJObject()
  var valid_600671 = formData.getOrDefault("NextToken")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "NextToken", valid_600671
  var valid_600672 = formData.getOrDefault("DashboardNamePrefix")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "DashboardNamePrefix", valid_600672
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600673: Call_PostListDashboards_600659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_600673.validator(path, query, header, formData, body)
  let scheme = call_600673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600673.url(scheme.get, call_600673.host, call_600673.base,
                         call_600673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600673, url, valid)

proc call*(call_600674: Call_PostListDashboards_600659; NextToken: string = "";
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
  var query_600675 = newJObject()
  var formData_600676 = newJObject()
  add(formData_600676, "NextToken", newJString(NextToken))
  add(query_600675, "Action", newJString(Action))
  add(formData_600676, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_600675, "Version", newJString(Version))
  result = call_600674.call(nil, query_600675, nil, formData_600676, nil)

var postListDashboards* = Call_PostListDashboards_600659(
    name: "postListDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListDashboards",
    validator: validate_PostListDashboards_600660, base: "/",
    url: url_PostListDashboards_600661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDashboards_600642 = ref object of OpenApiRestCall_599368
proc url_GetListDashboards_600644(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListDashboards_600643(path: JsonNode; query: JsonNode;
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
  var valid_600645 = query.getOrDefault("DashboardNamePrefix")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "DashboardNamePrefix", valid_600645
  var valid_600646 = query.getOrDefault("NextToken")
  valid_600646 = validateParameter(valid_600646, JString, required = false,
                                 default = nil)
  if valid_600646 != nil:
    section.add "NextToken", valid_600646
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600647 = query.getOrDefault("Action")
  valid_600647 = validateParameter(valid_600647, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_600647 != nil:
    section.add "Action", valid_600647
  var valid_600648 = query.getOrDefault("Version")
  valid_600648 = validateParameter(valid_600648, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600648 != nil:
    section.add "Version", valid_600648
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
  var valid_600649 = header.getOrDefault("X-Amz-Date")
  valid_600649 = validateParameter(valid_600649, JString, required = false,
                                 default = nil)
  if valid_600649 != nil:
    section.add "X-Amz-Date", valid_600649
  var valid_600650 = header.getOrDefault("X-Amz-Security-Token")
  valid_600650 = validateParameter(valid_600650, JString, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "X-Amz-Security-Token", valid_600650
  var valid_600651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Content-Sha256", valid_600651
  var valid_600652 = header.getOrDefault("X-Amz-Algorithm")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Algorithm", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Signature")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Signature", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-SignedHeaders", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Credential")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Credential", valid_600655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600656: Call_GetListDashboards_600642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_600656.validator(path, query, header, formData, body)
  let scheme = call_600656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600656.url(scheme.get, call_600656.host, call_600656.base,
                         call_600656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600656, url, valid)

proc call*(call_600657: Call_GetListDashboards_600642;
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
  var query_600658 = newJObject()
  add(query_600658, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_600658, "NextToken", newJString(NextToken))
  add(query_600658, "Action", newJString(Action))
  add(query_600658, "Version", newJString(Version))
  result = call_600657.call(nil, query_600658, nil, nil, nil)

var getListDashboards* = Call_GetListDashboards_600642(name: "getListDashboards",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListDashboards", validator: validate_GetListDashboards_600643,
    base: "/", url: url_GetListDashboards_600644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListMetrics_600696 = ref object of OpenApiRestCall_599368
proc url_PostListMetrics_600698(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListMetrics_600697(path: JsonNode; query: JsonNode;
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
  var valid_600699 = query.getOrDefault("Action")
  valid_600699 = validateParameter(valid_600699, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_600699 != nil:
    section.add "Action", valid_600699
  var valid_600700 = query.getOrDefault("Version")
  valid_600700 = validateParameter(valid_600700, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600700 != nil:
    section.add "Version", valid_600700
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
  var valid_600701 = header.getOrDefault("X-Amz-Date")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Date", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Security-Token")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Security-Token", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Content-Sha256", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-Algorithm")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-Algorithm", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Signature")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Signature", valid_600705
  var valid_600706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "X-Amz-SignedHeaders", valid_600706
  var valid_600707 = header.getOrDefault("X-Amz-Credential")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-Credential", valid_600707
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
  var valid_600708 = formData.getOrDefault("NextToken")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "NextToken", valid_600708
  var valid_600709 = formData.getOrDefault("MetricName")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "MetricName", valid_600709
  var valid_600710 = formData.getOrDefault("Dimensions")
  valid_600710 = validateParameter(valid_600710, JArray, required = false,
                                 default = nil)
  if valid_600710 != nil:
    section.add "Dimensions", valid_600710
  var valid_600711 = formData.getOrDefault("Namespace")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "Namespace", valid_600711
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600712: Call_PostListMetrics_600696; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_600712.validator(path, query, header, formData, body)
  let scheme = call_600712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600712.url(scheme.get, call_600712.host, call_600712.base,
                         call_600712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600712, url, valid)

proc call*(call_600713: Call_PostListMetrics_600696; NextToken: string = "";
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
  var query_600714 = newJObject()
  var formData_600715 = newJObject()
  add(formData_600715, "NextToken", newJString(NextToken))
  add(formData_600715, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_600715.add "Dimensions", Dimensions
  add(query_600714, "Action", newJString(Action))
  add(formData_600715, "Namespace", newJString(Namespace))
  add(query_600714, "Version", newJString(Version))
  result = call_600713.call(nil, query_600714, nil, formData_600715, nil)

var postListMetrics* = Call_PostListMetrics_600696(name: "postListMetrics",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_PostListMetrics_600697,
    base: "/", url: url_PostListMetrics_600698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListMetrics_600677 = ref object of OpenApiRestCall_599368
proc url_GetListMetrics_600679(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListMetrics_600678(path: JsonNode; query: JsonNode;
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
  var valid_600680 = query.getOrDefault("Namespace")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "Namespace", valid_600680
  var valid_600681 = query.getOrDefault("Dimensions")
  valid_600681 = validateParameter(valid_600681, JArray, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "Dimensions", valid_600681
  var valid_600682 = query.getOrDefault("NextToken")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "NextToken", valid_600682
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600683 = query.getOrDefault("Action")
  valid_600683 = validateParameter(valid_600683, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_600683 != nil:
    section.add "Action", valid_600683
  var valid_600684 = query.getOrDefault("Version")
  valid_600684 = validateParameter(valid_600684, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600684 != nil:
    section.add "Version", valid_600684
  var valid_600685 = query.getOrDefault("MetricName")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "MetricName", valid_600685
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
  var valid_600686 = header.getOrDefault("X-Amz-Date")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Date", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Security-Token")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Security-Token", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-Content-Sha256", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-Algorithm")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Algorithm", valid_600689
  var valid_600690 = header.getOrDefault("X-Amz-Signature")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "X-Amz-Signature", valid_600690
  var valid_600691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "X-Amz-SignedHeaders", valid_600691
  var valid_600692 = header.getOrDefault("X-Amz-Credential")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-Credential", valid_600692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600693: Call_GetListMetrics_600677; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_600693.validator(path, query, header, formData, body)
  let scheme = call_600693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600693.url(scheme.get, call_600693.host, call_600693.base,
                         call_600693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600693, url, valid)

proc call*(call_600694: Call_GetListMetrics_600677; Namespace: string = "";
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
  var query_600695 = newJObject()
  add(query_600695, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_600695.add "Dimensions", Dimensions
  add(query_600695, "NextToken", newJString(NextToken))
  add(query_600695, "Action", newJString(Action))
  add(query_600695, "Version", newJString(Version))
  add(query_600695, "MetricName", newJString(MetricName))
  result = call_600694.call(nil, query_600695, nil, nil, nil)

var getListMetrics* = Call_GetListMetrics_600677(name: "getListMetrics",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_GetListMetrics_600678,
    base: "/", url: url_GetListMetrics_600679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_600732 = ref object of OpenApiRestCall_599368
proc url_PostListTagsForResource_600734(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_600733(path: JsonNode; query: JsonNode;
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
  var valid_600735 = query.getOrDefault("Action")
  valid_600735 = validateParameter(valid_600735, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_600735 != nil:
    section.add "Action", valid_600735
  var valid_600736 = query.getOrDefault("Version")
  valid_600736 = validateParameter(valid_600736, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600736 != nil:
    section.add "Version", valid_600736
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
  var valid_600737 = header.getOrDefault("X-Amz-Date")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Date", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Security-Token")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Security-Token", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-Content-Sha256", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-Algorithm")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-Algorithm", valid_600740
  var valid_600741 = header.getOrDefault("X-Amz-Signature")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-Signature", valid_600741
  var valid_600742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "X-Amz-SignedHeaders", valid_600742
  var valid_600743 = header.getOrDefault("X-Amz-Credential")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "X-Amz-Credential", valid_600743
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceARN` field"
  var valid_600744 = formData.getOrDefault("ResourceARN")
  valid_600744 = validateParameter(valid_600744, JString, required = true,
                                 default = nil)
  if valid_600744 != nil:
    section.add "ResourceARN", valid_600744
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600745: Call_PostListTagsForResource_600732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_600745.validator(path, query, header, formData, body)
  let scheme = call_600745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600745.url(scheme.get, call_600745.host, call_600745.base,
                         call_600745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600745, url, valid)

proc call*(call_600746: Call_PostListTagsForResource_600732; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## postListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_600747 = newJObject()
  var formData_600748 = newJObject()
  add(query_600747, "Action", newJString(Action))
  add(formData_600748, "ResourceARN", newJString(ResourceARN))
  add(query_600747, "Version", newJString(Version))
  result = call_600746.call(nil, query_600747, nil, formData_600748, nil)

var postListTagsForResource* = Call_PostListTagsForResource_600732(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_600733, base: "/",
    url: url_PostListTagsForResource_600734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_600716 = ref object of OpenApiRestCall_599368
proc url_GetListTagsForResource_600718(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_600717(path: JsonNode; query: JsonNode;
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
  var valid_600719 = query.getOrDefault("ResourceARN")
  valid_600719 = validateParameter(valid_600719, JString, required = true,
                                 default = nil)
  if valid_600719 != nil:
    section.add "ResourceARN", valid_600719
  var valid_600720 = query.getOrDefault("Action")
  valid_600720 = validateParameter(valid_600720, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_600720 != nil:
    section.add "Action", valid_600720
  var valid_600721 = query.getOrDefault("Version")
  valid_600721 = validateParameter(valid_600721, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600721 != nil:
    section.add "Version", valid_600721
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
  var valid_600722 = header.getOrDefault("X-Amz-Date")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-Date", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Security-Token")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Security-Token", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Content-Sha256", valid_600724
  var valid_600725 = header.getOrDefault("X-Amz-Algorithm")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-Algorithm", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Signature")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Signature", valid_600726
  var valid_600727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-SignedHeaders", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-Credential")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Credential", valid_600728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600729: Call_GetListTagsForResource_600716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_600729.validator(path, query, header, formData, body)
  let scheme = call_600729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600729.url(scheme.get, call_600729.host, call_600729.base,
                         call_600729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600729, url, valid)

proc call*(call_600730: Call_GetListTagsForResource_600716; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## getListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600731 = newJObject()
  add(query_600731, "ResourceARN", newJString(ResourceARN))
  add(query_600731, "Action", newJString(Action))
  add(query_600731, "Version", newJString(Version))
  result = call_600730.call(nil, query_600731, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_600716(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_600717, base: "/",
    url: url_GetListTagsForResource_600718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAnomalyDetector_600770 = ref object of OpenApiRestCall_599368
proc url_PostPutAnomalyDetector_600772(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutAnomalyDetector_600771(path: JsonNode; query: JsonNode;
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
  var valid_600773 = query.getOrDefault("Action")
  valid_600773 = validateParameter(valid_600773, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_600773 != nil:
    section.add "Action", valid_600773
  var valid_600774 = query.getOrDefault("Version")
  valid_600774 = validateParameter(valid_600774, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600774 != nil:
    section.add "Version", valid_600774
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
  var valid_600775 = header.getOrDefault("X-Amz-Date")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Date", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Security-Token")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Security-Token", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-Content-Sha256", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-Algorithm")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-Algorithm", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-Signature")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Signature", valid_600779
  var valid_600780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600780 = validateParameter(valid_600780, JString, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "X-Amz-SignedHeaders", valid_600780
  var valid_600781 = header.getOrDefault("X-Amz-Credential")
  valid_600781 = validateParameter(valid_600781, JString, required = false,
                                 default = nil)
  if valid_600781 != nil:
    section.add "X-Amz-Credential", valid_600781
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
  var valid_600782 = formData.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_600782 = validateParameter(valid_600782, JArray, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_600782
  var valid_600783 = formData.getOrDefault("Configuration.MetricTimezone")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "Configuration.MetricTimezone", valid_600783
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_600784 = formData.getOrDefault("MetricName")
  valid_600784 = validateParameter(valid_600784, JString, required = true,
                                 default = nil)
  if valid_600784 != nil:
    section.add "MetricName", valid_600784
  var valid_600785 = formData.getOrDefault("Dimensions")
  valid_600785 = validateParameter(valid_600785, JArray, required = false,
                                 default = nil)
  if valid_600785 != nil:
    section.add "Dimensions", valid_600785
  var valid_600786 = formData.getOrDefault("Stat")
  valid_600786 = validateParameter(valid_600786, JString, required = true,
                                 default = nil)
  if valid_600786 != nil:
    section.add "Stat", valid_600786
  var valid_600787 = formData.getOrDefault("Namespace")
  valid_600787 = validateParameter(valid_600787, JString, required = true,
                                 default = nil)
  if valid_600787 != nil:
    section.add "Namespace", valid_600787
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600788: Call_PostPutAnomalyDetector_600770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_600788.validator(path, query, header, formData, body)
  let scheme = call_600788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600788.url(scheme.get, call_600788.host, call_600788.base,
                         call_600788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600788, url, valid)

proc call*(call_600789: Call_PostPutAnomalyDetector_600770; MetricName: string;
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
  var query_600790 = newJObject()
  var formData_600791 = newJObject()
  if ConfigurationExcludedTimeRanges != nil:
    formData_600791.add "Configuration.ExcludedTimeRanges",
                       ConfigurationExcludedTimeRanges
  add(formData_600791, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  add(formData_600791, "MetricName", newJString(MetricName))
  if Dimensions != nil:
    formData_600791.add "Dimensions", Dimensions
  add(query_600790, "Action", newJString(Action))
  add(formData_600791, "Stat", newJString(Stat))
  add(formData_600791, "Namespace", newJString(Namespace))
  add(query_600790, "Version", newJString(Version))
  result = call_600789.call(nil, query_600790, nil, formData_600791, nil)

var postPutAnomalyDetector* = Call_PostPutAnomalyDetector_600770(
    name: "postPutAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_PostPutAnomalyDetector_600771, base: "/",
    url: url_PostPutAnomalyDetector_600772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAnomalyDetector_600749 = ref object of OpenApiRestCall_599368
proc url_GetPutAnomalyDetector_600751(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutAnomalyDetector_600750(path: JsonNode; query: JsonNode;
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
  var valid_600752 = query.getOrDefault("Namespace")
  valid_600752 = validateParameter(valid_600752, JString, required = true,
                                 default = nil)
  if valid_600752 != nil:
    section.add "Namespace", valid_600752
  var valid_600753 = query.getOrDefault("Stat")
  valid_600753 = validateParameter(valid_600753, JString, required = true,
                                 default = nil)
  if valid_600753 != nil:
    section.add "Stat", valid_600753
  var valid_600754 = query.getOrDefault("Configuration.MetricTimezone")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "Configuration.MetricTimezone", valid_600754
  var valid_600755 = query.getOrDefault("Dimensions")
  valid_600755 = validateParameter(valid_600755, JArray, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "Dimensions", valid_600755
  var valid_600756 = query.getOrDefault("Action")
  valid_600756 = validateParameter(valid_600756, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_600756 != nil:
    section.add "Action", valid_600756
  var valid_600757 = query.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_600757 = validateParameter(valid_600757, JArray, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_600757
  var valid_600758 = query.getOrDefault("Version")
  valid_600758 = validateParameter(valid_600758, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600758 != nil:
    section.add "Version", valid_600758
  var valid_600759 = query.getOrDefault("MetricName")
  valid_600759 = validateParameter(valid_600759, JString, required = true,
                                 default = nil)
  if valid_600759 != nil:
    section.add "MetricName", valid_600759
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
  var valid_600760 = header.getOrDefault("X-Amz-Date")
  valid_600760 = validateParameter(valid_600760, JString, required = false,
                                 default = nil)
  if valid_600760 != nil:
    section.add "X-Amz-Date", valid_600760
  var valid_600761 = header.getOrDefault("X-Amz-Security-Token")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Security-Token", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Content-Sha256", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-Algorithm")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-Algorithm", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-Signature")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Signature", valid_600764
  var valid_600765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-SignedHeaders", valid_600765
  var valid_600766 = header.getOrDefault("X-Amz-Credential")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "X-Amz-Credential", valid_600766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600767: Call_GetPutAnomalyDetector_600749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_600767.validator(path, query, header, formData, body)
  let scheme = call_600767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600767.url(scheme.get, call_600767.host, call_600767.base,
                         call_600767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600767, url, valid)

proc call*(call_600768: Call_GetPutAnomalyDetector_600749; Namespace: string;
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
  var query_600769 = newJObject()
  add(query_600769, "Namespace", newJString(Namespace))
  add(query_600769, "Stat", newJString(Stat))
  add(query_600769, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  if Dimensions != nil:
    query_600769.add "Dimensions", Dimensions
  add(query_600769, "Action", newJString(Action))
  if ConfigurationExcludedTimeRanges != nil:
    query_600769.add "Configuration.ExcludedTimeRanges",
                    ConfigurationExcludedTimeRanges
  add(query_600769, "Version", newJString(Version))
  add(query_600769, "MetricName", newJString(MetricName))
  result = call_600768.call(nil, query_600769, nil, nil, nil)

var getPutAnomalyDetector* = Call_GetPutAnomalyDetector_600749(
    name: "getPutAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_GetPutAnomalyDetector_600750, base: "/",
    url: url_GetPutAnomalyDetector_600751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutDashboard_600809 = ref object of OpenApiRestCall_599368
proc url_PostPutDashboard_600811(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutDashboard_600810(path: JsonNode; query: JsonNode;
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
  var valid_600812 = query.getOrDefault("Action")
  valid_600812 = validateParameter(valid_600812, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_600812 != nil:
    section.add "Action", valid_600812
  var valid_600813 = query.getOrDefault("Version")
  valid_600813 = validateParameter(valid_600813, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600813 != nil:
    section.add "Version", valid_600813
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
  var valid_600814 = header.getOrDefault("X-Amz-Date")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Date", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Security-Token")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Security-Token", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-Content-Sha256", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-Algorithm")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Algorithm", valid_600817
  var valid_600818 = header.getOrDefault("X-Amz-Signature")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "X-Amz-Signature", valid_600818
  var valid_600819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "X-Amz-SignedHeaders", valid_600819
  var valid_600820 = header.getOrDefault("X-Amz-Credential")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "X-Amz-Credential", valid_600820
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_600821 = formData.getOrDefault("DashboardName")
  valid_600821 = validateParameter(valid_600821, JString, required = true,
                                 default = nil)
  if valid_600821 != nil:
    section.add "DashboardName", valid_600821
  var valid_600822 = formData.getOrDefault("DashboardBody")
  valid_600822 = validateParameter(valid_600822, JString, required = true,
                                 default = nil)
  if valid_600822 != nil:
    section.add "DashboardBody", valid_600822
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600823: Call_PostPutDashboard_600809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_600823.validator(path, query, header, formData, body)
  let scheme = call_600823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600823.url(scheme.get, call_600823.host, call_600823.base,
                         call_600823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600823, url, valid)

proc call*(call_600824: Call_PostPutDashboard_600809; DashboardName: string;
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
  var query_600825 = newJObject()
  var formData_600826 = newJObject()
  add(query_600825, "Action", newJString(Action))
  add(formData_600826, "DashboardName", newJString(DashboardName))
  add(formData_600826, "DashboardBody", newJString(DashboardBody))
  add(query_600825, "Version", newJString(Version))
  result = call_600824.call(nil, query_600825, nil, formData_600826, nil)

var postPutDashboard* = Call_PostPutDashboard_600809(name: "postPutDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_PostPutDashboard_600810,
    base: "/", url: url_PostPutDashboard_600811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutDashboard_600792 = ref object of OpenApiRestCall_599368
proc url_GetPutDashboard_600794(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutDashboard_600793(path: JsonNode; query: JsonNode;
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
  var valid_600795 = query.getOrDefault("DashboardName")
  valid_600795 = validateParameter(valid_600795, JString, required = true,
                                 default = nil)
  if valid_600795 != nil:
    section.add "DashboardName", valid_600795
  var valid_600796 = query.getOrDefault("Action")
  valid_600796 = validateParameter(valid_600796, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_600796 != nil:
    section.add "Action", valid_600796
  var valid_600797 = query.getOrDefault("DashboardBody")
  valid_600797 = validateParameter(valid_600797, JString, required = true,
                                 default = nil)
  if valid_600797 != nil:
    section.add "DashboardBody", valid_600797
  var valid_600798 = query.getOrDefault("Version")
  valid_600798 = validateParameter(valid_600798, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600798 != nil:
    section.add "Version", valid_600798
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
  var valid_600799 = header.getOrDefault("X-Amz-Date")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Date", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Security-Token")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Security-Token", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Content-Sha256", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-Algorithm")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Algorithm", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-Signature")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-Signature", valid_600803
  var valid_600804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600804 = validateParameter(valid_600804, JString, required = false,
                                 default = nil)
  if valid_600804 != nil:
    section.add "X-Amz-SignedHeaders", valid_600804
  var valid_600805 = header.getOrDefault("X-Amz-Credential")
  valid_600805 = validateParameter(valid_600805, JString, required = false,
                                 default = nil)
  if valid_600805 != nil:
    section.add "X-Amz-Credential", valid_600805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600806: Call_GetPutDashboard_600792; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_600806.validator(path, query, header, formData, body)
  let scheme = call_600806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600806.url(scheme.get, call_600806.host, call_600806.base,
                         call_600806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600806, url, valid)

proc call*(call_600807: Call_GetPutDashboard_600792; DashboardName: string;
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
  var query_600808 = newJObject()
  add(query_600808, "DashboardName", newJString(DashboardName))
  add(query_600808, "Action", newJString(Action))
  add(query_600808, "DashboardBody", newJString(DashboardBody))
  add(query_600808, "Version", newJString(Version))
  result = call_600807.call(nil, query_600808, nil, nil, nil)

var getPutDashboard* = Call_GetPutDashboard_600792(name: "getPutDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_GetPutDashboard_600793,
    base: "/", url: url_GetPutDashboard_600794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutInsightRule_600845 = ref object of OpenApiRestCall_599368
proc url_PostPutInsightRule_600847(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutInsightRule_600846(path: JsonNode; query: JsonNode;
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
  var valid_600848 = query.getOrDefault("Action")
  valid_600848 = validateParameter(valid_600848, JString, required = true,
                                 default = newJString("PutInsightRule"))
  if valid_600848 != nil:
    section.add "Action", valid_600848
  var valid_600849 = query.getOrDefault("Version")
  valid_600849 = validateParameter(valid_600849, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600849 != nil:
    section.add "Version", valid_600849
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
  var valid_600850 = header.getOrDefault("X-Amz-Date")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Date", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Security-Token")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Security-Token", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Content-Sha256", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-Algorithm")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-Algorithm", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Signature")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Signature", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-SignedHeaders", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-Credential")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Credential", valid_600856
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
  var valid_600857 = formData.getOrDefault("RuleName")
  valid_600857 = validateParameter(valid_600857, JString, required = true,
                                 default = nil)
  if valid_600857 != nil:
    section.add "RuleName", valid_600857
  var valid_600858 = formData.getOrDefault("RuleState")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "RuleState", valid_600858
  var valid_600859 = formData.getOrDefault("RuleDefinition")
  valid_600859 = validateParameter(valid_600859, JString, required = true,
                                 default = nil)
  if valid_600859 != nil:
    section.add "RuleDefinition", valid_600859
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600860: Call_PostPutInsightRule_600845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_600860.validator(path, query, header, formData, body)
  let scheme = call_600860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600860.url(scheme.get, call_600860.host, call_600860.base,
                         call_600860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600860, url, valid)

proc call*(call_600861: Call_PostPutInsightRule_600845; RuleName: string;
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
  var query_600862 = newJObject()
  var formData_600863 = newJObject()
  add(formData_600863, "RuleName", newJString(RuleName))
  add(query_600862, "Action", newJString(Action))
  add(formData_600863, "RuleState", newJString(RuleState))
  add(formData_600863, "RuleDefinition", newJString(RuleDefinition))
  add(query_600862, "Version", newJString(Version))
  result = call_600861.call(nil, query_600862, nil, formData_600863, nil)

var postPutInsightRule* = Call_PostPutInsightRule_600845(
    name: "postPutInsightRule", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutInsightRule",
    validator: validate_PostPutInsightRule_600846, base: "/",
    url: url_PostPutInsightRule_600847, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutInsightRule_600827 = ref object of OpenApiRestCall_599368
proc url_GetPutInsightRule_600829(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutInsightRule_600828(path: JsonNode; query: JsonNode;
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
  var valid_600830 = query.getOrDefault("RuleName")
  valid_600830 = validateParameter(valid_600830, JString, required = true,
                                 default = nil)
  if valid_600830 != nil:
    section.add "RuleName", valid_600830
  var valid_600831 = query.getOrDefault("Action")
  valid_600831 = validateParameter(valid_600831, JString, required = true,
                                 default = newJString("PutInsightRule"))
  if valid_600831 != nil:
    section.add "Action", valid_600831
  var valid_600832 = query.getOrDefault("RuleDefinition")
  valid_600832 = validateParameter(valid_600832, JString, required = true,
                                 default = nil)
  if valid_600832 != nil:
    section.add "RuleDefinition", valid_600832
  var valid_600833 = query.getOrDefault("RuleState")
  valid_600833 = validateParameter(valid_600833, JString, required = false,
                                 default = nil)
  if valid_600833 != nil:
    section.add "RuleState", valid_600833
  var valid_600834 = query.getOrDefault("Version")
  valid_600834 = validateParameter(valid_600834, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600834 != nil:
    section.add "Version", valid_600834
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
  var valid_600835 = header.getOrDefault("X-Amz-Date")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "X-Amz-Date", valid_600835
  var valid_600836 = header.getOrDefault("X-Amz-Security-Token")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Security-Token", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Content-Sha256", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-Algorithm")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Algorithm", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-Signature")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Signature", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-SignedHeaders", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-Credential")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Credential", valid_600841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600842: Call_GetPutInsightRule_600827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_600842.validator(path, query, header, formData, body)
  let scheme = call_600842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600842.url(scheme.get, call_600842.host, call_600842.base,
                         call_600842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600842, url, valid)

proc call*(call_600843: Call_GetPutInsightRule_600827; RuleName: string;
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
  var query_600844 = newJObject()
  add(query_600844, "RuleName", newJString(RuleName))
  add(query_600844, "Action", newJString(Action))
  add(query_600844, "RuleDefinition", newJString(RuleDefinition))
  add(query_600844, "RuleState", newJString(RuleState))
  add(query_600844, "Version", newJString(Version))
  result = call_600843.call(nil, query_600844, nil, nil, nil)

var getPutInsightRule* = Call_GetPutInsightRule_600827(name: "getPutInsightRule",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutInsightRule", validator: validate_GetPutInsightRule_600828,
    base: "/", url: url_GetPutInsightRule_600829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricAlarm_600901 = ref object of OpenApiRestCall_599368
proc url_PostPutMetricAlarm_600903(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutMetricAlarm_600902(path: JsonNode; query: JsonNode;
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
  var valid_600904 = query.getOrDefault("Action")
  valid_600904 = validateParameter(valid_600904, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_600904 != nil:
    section.add "Action", valid_600904
  var valid_600905 = query.getOrDefault("Version")
  valid_600905 = validateParameter(valid_600905, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600905 != nil:
    section.add "Version", valid_600905
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
  var valid_600906 = header.getOrDefault("X-Amz-Date")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Date", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Security-Token")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Security-Token", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Content-Sha256", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Algorithm")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Algorithm", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Signature")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Signature", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-SignedHeaders", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-Credential")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Credential", valid_600912
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
  var valid_600913 = formData.getOrDefault("ActionsEnabled")
  valid_600913 = validateParameter(valid_600913, JBool, required = false, default = nil)
  if valid_600913 != nil:
    section.add "ActionsEnabled", valid_600913
  var valid_600914 = formData.getOrDefault("Threshold")
  valid_600914 = validateParameter(valid_600914, JFloat, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "Threshold", valid_600914
  var valid_600915 = formData.getOrDefault("ExtendedStatistic")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "ExtendedStatistic", valid_600915
  var valid_600916 = formData.getOrDefault("Metrics")
  valid_600916 = validateParameter(valid_600916, JArray, required = false,
                                 default = nil)
  if valid_600916 != nil:
    section.add "Metrics", valid_600916
  var valid_600917 = formData.getOrDefault("MetricName")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "MetricName", valid_600917
  var valid_600918 = formData.getOrDefault("TreatMissingData")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "TreatMissingData", valid_600918
  var valid_600919 = formData.getOrDefault("AlarmDescription")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "AlarmDescription", valid_600919
  var valid_600920 = formData.getOrDefault("Dimensions")
  valid_600920 = validateParameter(valid_600920, JArray, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "Dimensions", valid_600920
  assert formData != nil, "formData argument is necessary due to required `ComparisonOperator` field"
  var valid_600921 = formData.getOrDefault("ComparisonOperator")
  valid_600921 = validateParameter(valid_600921, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_600921 != nil:
    section.add "ComparisonOperator", valid_600921
  var valid_600922 = formData.getOrDefault("Tags")
  valid_600922 = validateParameter(valid_600922, JArray, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "Tags", valid_600922
  var valid_600923 = formData.getOrDefault("ThresholdMetricId")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "ThresholdMetricId", valid_600923
  var valid_600924 = formData.getOrDefault("OKActions")
  valid_600924 = validateParameter(valid_600924, JArray, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "OKActions", valid_600924
  var valid_600925 = formData.getOrDefault("Statistic")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_600925 != nil:
    section.add "Statistic", valid_600925
  var valid_600926 = formData.getOrDefault("EvaluationPeriods")
  valid_600926 = validateParameter(valid_600926, JInt, required = true, default = nil)
  if valid_600926 != nil:
    section.add "EvaluationPeriods", valid_600926
  var valid_600927 = formData.getOrDefault("DatapointsToAlarm")
  valid_600927 = validateParameter(valid_600927, JInt, required = false, default = nil)
  if valid_600927 != nil:
    section.add "DatapointsToAlarm", valid_600927
  var valid_600928 = formData.getOrDefault("AlarmName")
  valid_600928 = validateParameter(valid_600928, JString, required = true,
                                 default = nil)
  if valid_600928 != nil:
    section.add "AlarmName", valid_600928
  var valid_600929 = formData.getOrDefault("Namespace")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "Namespace", valid_600929
  var valid_600930 = formData.getOrDefault("InsufficientDataActions")
  valid_600930 = validateParameter(valid_600930, JArray, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "InsufficientDataActions", valid_600930
  var valid_600931 = formData.getOrDefault("AlarmActions")
  valid_600931 = validateParameter(valid_600931, JArray, required = false,
                                 default = nil)
  if valid_600931 != nil:
    section.add "AlarmActions", valid_600931
  var valid_600932 = formData.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_600932 = validateParameter(valid_600932, JString, required = false,
                                 default = nil)
  if valid_600932 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_600932
  var valid_600933 = formData.getOrDefault("Unit")
  valid_600933 = validateParameter(valid_600933, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_600933 != nil:
    section.add "Unit", valid_600933
  var valid_600934 = formData.getOrDefault("Period")
  valid_600934 = validateParameter(valid_600934, JInt, required = false, default = nil)
  if valid_600934 != nil:
    section.add "Period", valid_600934
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600935: Call_PostPutMetricAlarm_600901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_600935.validator(path, query, header, formData, body)
  let scheme = call_600935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600935.url(scheme.get, call_600935.host, call_600935.base,
                         call_600935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600935, url, valid)

proc call*(call_600936: Call_PostPutMetricAlarm_600901; EvaluationPeriods: int;
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
  var query_600937 = newJObject()
  var formData_600938 = newJObject()
  add(formData_600938, "ActionsEnabled", newJBool(ActionsEnabled))
  add(formData_600938, "Threshold", newJFloat(Threshold))
  add(formData_600938, "ExtendedStatistic", newJString(ExtendedStatistic))
  if Metrics != nil:
    formData_600938.add "Metrics", Metrics
  add(formData_600938, "MetricName", newJString(MetricName))
  add(formData_600938, "TreatMissingData", newJString(TreatMissingData))
  add(formData_600938, "AlarmDescription", newJString(AlarmDescription))
  if Dimensions != nil:
    formData_600938.add "Dimensions", Dimensions
  add(formData_600938, "ComparisonOperator", newJString(ComparisonOperator))
  if Tags != nil:
    formData_600938.add "Tags", Tags
  add(formData_600938, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_600937, "Action", newJString(Action))
  if OKActions != nil:
    formData_600938.add "OKActions", OKActions
  add(formData_600938, "Statistic", newJString(Statistic))
  add(formData_600938, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(formData_600938, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(formData_600938, "AlarmName", newJString(AlarmName))
  add(formData_600938, "Namespace", newJString(Namespace))
  if InsufficientDataActions != nil:
    formData_600938.add "InsufficientDataActions", InsufficientDataActions
  if AlarmActions != nil:
    formData_600938.add "AlarmActions", AlarmActions
  add(formData_600938, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  add(formData_600938, "Unit", newJString(Unit))
  add(query_600937, "Version", newJString(Version))
  add(formData_600938, "Period", newJInt(Period))
  result = call_600936.call(nil, query_600937, nil, formData_600938, nil)

var postPutMetricAlarm* = Call_PostPutMetricAlarm_600901(
    name: "postPutMetricAlarm", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutMetricAlarm",
    validator: validate_PostPutMetricAlarm_600902, base: "/",
    url: url_PostPutMetricAlarm_600903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricAlarm_600864 = ref object of OpenApiRestCall_599368
proc url_GetPutMetricAlarm_600866(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutMetricAlarm_600865(path: JsonNode; query: JsonNode;
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
  var valid_600867 = query.getOrDefault("Namespace")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "Namespace", valid_600867
  var valid_600868 = query.getOrDefault("DatapointsToAlarm")
  valid_600868 = validateParameter(valid_600868, JInt, required = false, default = nil)
  if valid_600868 != nil:
    section.add "DatapointsToAlarm", valid_600868
  assert query != nil,
        "query argument is necessary due to required `AlarmName` field"
  var valid_600869 = query.getOrDefault("AlarmName")
  valid_600869 = validateParameter(valid_600869, JString, required = true,
                                 default = nil)
  if valid_600869 != nil:
    section.add "AlarmName", valid_600869
  var valid_600870 = query.getOrDefault("Unit")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_600870 != nil:
    section.add "Unit", valid_600870
  var valid_600871 = query.getOrDefault("Threshold")
  valid_600871 = validateParameter(valid_600871, JFloat, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "Threshold", valid_600871
  var valid_600872 = query.getOrDefault("ExtendedStatistic")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "ExtendedStatistic", valid_600872
  var valid_600873 = query.getOrDefault("TreatMissingData")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "TreatMissingData", valid_600873
  var valid_600874 = query.getOrDefault("Dimensions")
  valid_600874 = validateParameter(valid_600874, JArray, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "Dimensions", valid_600874
  var valid_600875 = query.getOrDefault("Tags")
  valid_600875 = validateParameter(valid_600875, JArray, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "Tags", valid_600875
  var valid_600876 = query.getOrDefault("Action")
  valid_600876 = validateParameter(valid_600876, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_600876 != nil:
    section.add "Action", valid_600876
  var valid_600877 = query.getOrDefault("EvaluationPeriods")
  valid_600877 = validateParameter(valid_600877, JInt, required = true, default = nil)
  if valid_600877 != nil:
    section.add "EvaluationPeriods", valid_600877
  var valid_600878 = query.getOrDefault("ActionsEnabled")
  valid_600878 = validateParameter(valid_600878, JBool, required = false, default = nil)
  if valid_600878 != nil:
    section.add "ActionsEnabled", valid_600878
  var valid_600879 = query.getOrDefault("ComparisonOperator")
  valid_600879 = validateParameter(valid_600879, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_600879 != nil:
    section.add "ComparisonOperator", valid_600879
  var valid_600880 = query.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_600880 = validateParameter(valid_600880, JString, required = false,
                                 default = nil)
  if valid_600880 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_600880
  var valid_600881 = query.getOrDefault("Metrics")
  valid_600881 = validateParameter(valid_600881, JArray, required = false,
                                 default = nil)
  if valid_600881 != nil:
    section.add "Metrics", valid_600881
  var valid_600882 = query.getOrDefault("InsufficientDataActions")
  valid_600882 = validateParameter(valid_600882, JArray, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "InsufficientDataActions", valid_600882
  var valid_600883 = query.getOrDefault("AlarmDescription")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "AlarmDescription", valid_600883
  var valid_600884 = query.getOrDefault("AlarmActions")
  valid_600884 = validateParameter(valid_600884, JArray, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "AlarmActions", valid_600884
  var valid_600885 = query.getOrDefault("Period")
  valid_600885 = validateParameter(valid_600885, JInt, required = false, default = nil)
  if valid_600885 != nil:
    section.add "Period", valid_600885
  var valid_600886 = query.getOrDefault("MetricName")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "MetricName", valid_600886
  var valid_600887 = query.getOrDefault("Statistic")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_600887 != nil:
    section.add "Statistic", valid_600887
  var valid_600888 = query.getOrDefault("ThresholdMetricId")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "ThresholdMetricId", valid_600888
  var valid_600889 = query.getOrDefault("Version")
  valid_600889 = validateParameter(valid_600889, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600889 != nil:
    section.add "Version", valid_600889
  var valid_600890 = query.getOrDefault("OKActions")
  valid_600890 = validateParameter(valid_600890, JArray, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "OKActions", valid_600890
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
  var valid_600891 = header.getOrDefault("X-Amz-Date")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Date", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Security-Token")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Security-Token", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Content-Sha256", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Algorithm")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Algorithm", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Signature")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Signature", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-SignedHeaders", valid_600896
  var valid_600897 = header.getOrDefault("X-Amz-Credential")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Credential", valid_600897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600898: Call_GetPutMetricAlarm_600864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_600898.validator(path, query, header, formData, body)
  let scheme = call_600898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600898.url(scheme.get, call_600898.host, call_600898.base,
                         call_600898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600898, url, valid)

proc call*(call_600899: Call_GetPutMetricAlarm_600864; AlarmName: string;
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
  var query_600900 = newJObject()
  add(query_600900, "Namespace", newJString(Namespace))
  add(query_600900, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(query_600900, "AlarmName", newJString(AlarmName))
  add(query_600900, "Unit", newJString(Unit))
  add(query_600900, "Threshold", newJFloat(Threshold))
  add(query_600900, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_600900, "TreatMissingData", newJString(TreatMissingData))
  if Dimensions != nil:
    query_600900.add "Dimensions", Dimensions
  if Tags != nil:
    query_600900.add "Tags", Tags
  add(query_600900, "Action", newJString(Action))
  add(query_600900, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(query_600900, "ActionsEnabled", newJBool(ActionsEnabled))
  add(query_600900, "ComparisonOperator", newJString(ComparisonOperator))
  add(query_600900, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  if Metrics != nil:
    query_600900.add "Metrics", Metrics
  if InsufficientDataActions != nil:
    query_600900.add "InsufficientDataActions", InsufficientDataActions
  add(query_600900, "AlarmDescription", newJString(AlarmDescription))
  if AlarmActions != nil:
    query_600900.add "AlarmActions", AlarmActions
  add(query_600900, "Period", newJInt(Period))
  add(query_600900, "MetricName", newJString(MetricName))
  add(query_600900, "Statistic", newJString(Statistic))
  add(query_600900, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_600900, "Version", newJString(Version))
  if OKActions != nil:
    query_600900.add "OKActions", OKActions
  result = call_600899.call(nil, query_600900, nil, nil, nil)

var getPutMetricAlarm* = Call_GetPutMetricAlarm_600864(name: "getPutMetricAlarm",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricAlarm", validator: validate_GetPutMetricAlarm_600865,
    base: "/", url: url_GetPutMetricAlarm_600866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricData_600956 = ref object of OpenApiRestCall_599368
proc url_PostPutMetricData_600958(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutMetricData_600957(path: JsonNode; query: JsonNode;
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
  var valid_600959 = query.getOrDefault("Action")
  valid_600959 = validateParameter(valid_600959, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_600959 != nil:
    section.add "Action", valid_600959
  var valid_600960 = query.getOrDefault("Version")
  valid_600960 = validateParameter(valid_600960, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600960 != nil:
    section.add "Version", valid_600960
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
  var valid_600961 = header.getOrDefault("X-Amz-Date")
  valid_600961 = validateParameter(valid_600961, JString, required = false,
                                 default = nil)
  if valid_600961 != nil:
    section.add "X-Amz-Date", valid_600961
  var valid_600962 = header.getOrDefault("X-Amz-Security-Token")
  valid_600962 = validateParameter(valid_600962, JString, required = false,
                                 default = nil)
  if valid_600962 != nil:
    section.add "X-Amz-Security-Token", valid_600962
  var valid_600963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600963 = validateParameter(valid_600963, JString, required = false,
                                 default = nil)
  if valid_600963 != nil:
    section.add "X-Amz-Content-Sha256", valid_600963
  var valid_600964 = header.getOrDefault("X-Amz-Algorithm")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "X-Amz-Algorithm", valid_600964
  var valid_600965 = header.getOrDefault("X-Amz-Signature")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "X-Amz-Signature", valid_600965
  var valid_600966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600966 = validateParameter(valid_600966, JString, required = false,
                                 default = nil)
  if valid_600966 != nil:
    section.add "X-Amz-SignedHeaders", valid_600966
  var valid_600967 = header.getOrDefault("X-Amz-Credential")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Credential", valid_600967
  result.add "header", section
  ## parameters in `formData` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Namespace` field"
  var valid_600968 = formData.getOrDefault("Namespace")
  valid_600968 = validateParameter(valid_600968, JString, required = true,
                                 default = nil)
  if valid_600968 != nil:
    section.add "Namespace", valid_600968
  var valid_600969 = formData.getOrDefault("MetricData")
  valid_600969 = validateParameter(valid_600969, JArray, required = true, default = nil)
  if valid_600969 != nil:
    section.add "MetricData", valid_600969
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600970: Call_PostPutMetricData_600956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_600970.validator(path, query, header, formData, body)
  let scheme = call_600970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600970.url(scheme.get, call_600970.host, call_600970.base,
                         call_600970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600970, url, valid)

proc call*(call_600971: Call_PostPutMetricData_600956; Namespace: string;
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
  var query_600972 = newJObject()
  var formData_600973 = newJObject()
  add(query_600972, "Action", newJString(Action))
  add(formData_600973, "Namespace", newJString(Namespace))
  if MetricData != nil:
    formData_600973.add "MetricData", MetricData
  add(query_600972, "Version", newJString(Version))
  result = call_600971.call(nil, query_600972, nil, formData_600973, nil)

var postPutMetricData* = Call_PostPutMetricData_600956(name: "postPutMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_PostPutMetricData_600957,
    base: "/", url: url_PostPutMetricData_600958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricData_600939 = ref object of OpenApiRestCall_599368
proc url_GetPutMetricData_600941(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutMetricData_600940(path: JsonNode; query: JsonNode;
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
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_600942 = query.getOrDefault("Namespace")
  valid_600942 = validateParameter(valid_600942, JString, required = true,
                                 default = nil)
  if valid_600942 != nil:
    section.add "Namespace", valid_600942
  var valid_600943 = query.getOrDefault("MetricData")
  valid_600943 = validateParameter(valid_600943, JArray, required = true, default = nil)
  if valid_600943 != nil:
    section.add "MetricData", valid_600943
  var valid_600944 = query.getOrDefault("Action")
  valid_600944 = validateParameter(valid_600944, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_600944 != nil:
    section.add "Action", valid_600944
  var valid_600945 = query.getOrDefault("Version")
  valid_600945 = validateParameter(valid_600945, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600945 != nil:
    section.add "Version", valid_600945
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
  var valid_600946 = header.getOrDefault("X-Amz-Date")
  valid_600946 = validateParameter(valid_600946, JString, required = false,
                                 default = nil)
  if valid_600946 != nil:
    section.add "X-Amz-Date", valid_600946
  var valid_600947 = header.getOrDefault("X-Amz-Security-Token")
  valid_600947 = validateParameter(valid_600947, JString, required = false,
                                 default = nil)
  if valid_600947 != nil:
    section.add "X-Amz-Security-Token", valid_600947
  var valid_600948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600948 = validateParameter(valid_600948, JString, required = false,
                                 default = nil)
  if valid_600948 != nil:
    section.add "X-Amz-Content-Sha256", valid_600948
  var valid_600949 = header.getOrDefault("X-Amz-Algorithm")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "X-Amz-Algorithm", valid_600949
  var valid_600950 = header.getOrDefault("X-Amz-Signature")
  valid_600950 = validateParameter(valid_600950, JString, required = false,
                                 default = nil)
  if valid_600950 != nil:
    section.add "X-Amz-Signature", valid_600950
  var valid_600951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600951 = validateParameter(valid_600951, JString, required = false,
                                 default = nil)
  if valid_600951 != nil:
    section.add "X-Amz-SignedHeaders", valid_600951
  var valid_600952 = header.getOrDefault("X-Amz-Credential")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Credential", valid_600952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600953: Call_GetPutMetricData_600939; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_600953.validator(path, query, header, formData, body)
  let scheme = call_600953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600953.url(scheme.get, call_600953.host, call_600953.base,
                         call_600953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600953, url, valid)

proc call*(call_600954: Call_GetPutMetricData_600939; Namespace: string;
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
  var query_600955 = newJObject()
  add(query_600955, "Namespace", newJString(Namespace))
  if MetricData != nil:
    query_600955.add "MetricData", MetricData
  add(query_600955, "Action", newJString(Action))
  add(query_600955, "Version", newJString(Version))
  result = call_600954.call(nil, query_600955, nil, nil, nil)

var getPutMetricData* = Call_GetPutMetricData_600939(name: "getPutMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_GetPutMetricData_600940,
    base: "/", url: url_GetPutMetricData_600941,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetAlarmState_600993 = ref object of OpenApiRestCall_599368
proc url_PostSetAlarmState_600995(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetAlarmState_600994(path: JsonNode; query: JsonNode;
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
  var valid_600996 = query.getOrDefault("Action")
  valid_600996 = validateParameter(valid_600996, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_600996 != nil:
    section.add "Action", valid_600996
  var valid_600997 = query.getOrDefault("Version")
  valid_600997 = validateParameter(valid_600997, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600997 != nil:
    section.add "Version", valid_600997
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
  var valid_600998 = header.getOrDefault("X-Amz-Date")
  valid_600998 = validateParameter(valid_600998, JString, required = false,
                                 default = nil)
  if valid_600998 != nil:
    section.add "X-Amz-Date", valid_600998
  var valid_600999 = header.getOrDefault("X-Amz-Security-Token")
  valid_600999 = validateParameter(valid_600999, JString, required = false,
                                 default = nil)
  if valid_600999 != nil:
    section.add "X-Amz-Security-Token", valid_600999
  var valid_601000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601000 = validateParameter(valid_601000, JString, required = false,
                                 default = nil)
  if valid_601000 != nil:
    section.add "X-Amz-Content-Sha256", valid_601000
  var valid_601001 = header.getOrDefault("X-Amz-Algorithm")
  valid_601001 = validateParameter(valid_601001, JString, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "X-Amz-Algorithm", valid_601001
  var valid_601002 = header.getOrDefault("X-Amz-Signature")
  valid_601002 = validateParameter(valid_601002, JString, required = false,
                                 default = nil)
  if valid_601002 != nil:
    section.add "X-Amz-Signature", valid_601002
  var valid_601003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601003 = validateParameter(valid_601003, JString, required = false,
                                 default = nil)
  if valid_601003 != nil:
    section.add "X-Amz-SignedHeaders", valid_601003
  var valid_601004 = header.getOrDefault("X-Amz-Credential")
  valid_601004 = validateParameter(valid_601004, JString, required = false,
                                 default = nil)
  if valid_601004 != nil:
    section.add "X-Amz-Credential", valid_601004
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
  var valid_601005 = formData.getOrDefault("StateReasonData")
  valid_601005 = validateParameter(valid_601005, JString, required = false,
                                 default = nil)
  if valid_601005 != nil:
    section.add "StateReasonData", valid_601005
  assert formData != nil,
        "formData argument is necessary due to required `StateReason` field"
  var valid_601006 = formData.getOrDefault("StateReason")
  valid_601006 = validateParameter(valid_601006, JString, required = true,
                                 default = nil)
  if valid_601006 != nil:
    section.add "StateReason", valid_601006
  var valid_601007 = formData.getOrDefault("StateValue")
  valid_601007 = validateParameter(valid_601007, JString, required = true,
                                 default = newJString("OK"))
  if valid_601007 != nil:
    section.add "StateValue", valid_601007
  var valid_601008 = formData.getOrDefault("AlarmName")
  valid_601008 = validateParameter(valid_601008, JString, required = true,
                                 default = nil)
  if valid_601008 != nil:
    section.add "AlarmName", valid_601008
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601009: Call_PostSetAlarmState_600993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_601009.validator(path, query, header, formData, body)
  let scheme = call_601009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601009.url(scheme.get, call_601009.host, call_601009.base,
                         call_601009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601009, url, valid)

proc call*(call_601010: Call_PostSetAlarmState_600993; StateReason: string;
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
  var query_601011 = newJObject()
  var formData_601012 = newJObject()
  add(formData_601012, "StateReasonData", newJString(StateReasonData))
  add(formData_601012, "StateReason", newJString(StateReason))
  add(formData_601012, "StateValue", newJString(StateValue))
  add(query_601011, "Action", newJString(Action))
  add(formData_601012, "AlarmName", newJString(AlarmName))
  add(query_601011, "Version", newJString(Version))
  result = call_601010.call(nil, query_601011, nil, formData_601012, nil)

var postSetAlarmState* = Call_PostSetAlarmState_600993(name: "postSetAlarmState",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_PostSetAlarmState_600994,
    base: "/", url: url_PostSetAlarmState_600995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetAlarmState_600974 = ref object of OpenApiRestCall_599368
proc url_GetSetAlarmState_600976(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetAlarmState_600975(path: JsonNode; query: JsonNode;
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
  var valid_600977 = query.getOrDefault("AlarmName")
  valid_600977 = validateParameter(valid_600977, JString, required = true,
                                 default = nil)
  if valid_600977 != nil:
    section.add "AlarmName", valid_600977
  var valid_600978 = query.getOrDefault("Action")
  valid_600978 = validateParameter(valid_600978, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_600978 != nil:
    section.add "Action", valid_600978
  var valid_600979 = query.getOrDefault("StateValue")
  valid_600979 = validateParameter(valid_600979, JString, required = true,
                                 default = newJString("OK"))
  if valid_600979 != nil:
    section.add "StateValue", valid_600979
  var valid_600980 = query.getOrDefault("StateReasonData")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "StateReasonData", valid_600980
  var valid_600981 = query.getOrDefault("StateReason")
  valid_600981 = validateParameter(valid_600981, JString, required = true,
                                 default = nil)
  if valid_600981 != nil:
    section.add "StateReason", valid_600981
  var valid_600982 = query.getOrDefault("Version")
  valid_600982 = validateParameter(valid_600982, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_600982 != nil:
    section.add "Version", valid_600982
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
  var valid_600983 = header.getOrDefault("X-Amz-Date")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "X-Amz-Date", valid_600983
  var valid_600984 = header.getOrDefault("X-Amz-Security-Token")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "X-Amz-Security-Token", valid_600984
  var valid_600985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "X-Amz-Content-Sha256", valid_600985
  var valid_600986 = header.getOrDefault("X-Amz-Algorithm")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "X-Amz-Algorithm", valid_600986
  var valid_600987 = header.getOrDefault("X-Amz-Signature")
  valid_600987 = validateParameter(valid_600987, JString, required = false,
                                 default = nil)
  if valid_600987 != nil:
    section.add "X-Amz-Signature", valid_600987
  var valid_600988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "X-Amz-SignedHeaders", valid_600988
  var valid_600989 = header.getOrDefault("X-Amz-Credential")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "X-Amz-Credential", valid_600989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600990: Call_GetSetAlarmState_600974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_600990.validator(path, query, header, formData, body)
  let scheme = call_600990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600990.url(scheme.get, call_600990.host, call_600990.base,
                         call_600990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600990, url, valid)

proc call*(call_600991: Call_GetSetAlarmState_600974; AlarmName: string;
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
  var query_600992 = newJObject()
  add(query_600992, "AlarmName", newJString(AlarmName))
  add(query_600992, "Action", newJString(Action))
  add(query_600992, "StateValue", newJString(StateValue))
  add(query_600992, "StateReasonData", newJString(StateReasonData))
  add(query_600992, "StateReason", newJString(StateReason))
  add(query_600992, "Version", newJString(Version))
  result = call_600991.call(nil, query_600992, nil, nil, nil)

var getSetAlarmState* = Call_GetSetAlarmState_600974(name: "getSetAlarmState",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_GetSetAlarmState_600975,
    base: "/", url: url_GetSetAlarmState_600976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_601030 = ref object of OpenApiRestCall_599368
proc url_PostTagResource_601032(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostTagResource_601031(path: JsonNode; query: JsonNode;
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
  var valid_601033 = query.getOrDefault("Action")
  valid_601033 = validateParameter(valid_601033, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_601033 != nil:
    section.add "Action", valid_601033
  var valid_601034 = query.getOrDefault("Version")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_601034 != nil:
    section.add "Version", valid_601034
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
  var valid_601035 = header.getOrDefault("X-Amz-Date")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Date", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Security-Token")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Security-Token", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Content-Sha256", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Algorithm")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Algorithm", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Signature")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Signature", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-SignedHeaders", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Credential")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Credential", valid_601041
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
  var valid_601042 = formData.getOrDefault("Tags")
  valid_601042 = validateParameter(valid_601042, JArray, required = true, default = nil)
  if valid_601042 != nil:
    section.add "Tags", valid_601042
  var valid_601043 = formData.getOrDefault("ResourceARN")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = nil)
  if valid_601043 != nil:
    section.add "ResourceARN", valid_601043
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601044: Call_PostTagResource_601030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_601044.validator(path, query, header, formData, body)
  let scheme = call_601044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601044.url(scheme.get, call_601044.host, call_601044.base,
                         call_601044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601044, url, valid)

proc call*(call_601045: Call_PostTagResource_601030; Tags: JsonNode;
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
  var query_601046 = newJObject()
  var formData_601047 = newJObject()
  if Tags != nil:
    formData_601047.add "Tags", Tags
  add(query_601046, "Action", newJString(Action))
  add(formData_601047, "ResourceARN", newJString(ResourceARN))
  add(query_601046, "Version", newJString(Version))
  result = call_601045.call(nil, query_601046, nil, formData_601047, nil)

var postTagResource* = Call_PostTagResource_601030(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_601031,
    base: "/", url: url_PostTagResource_601032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_601013 = ref object of OpenApiRestCall_599368
proc url_GetTagResource_601015(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTagResource_601014(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_601016 = query.getOrDefault("ResourceARN")
  valid_601016 = validateParameter(valid_601016, JString, required = true,
                                 default = nil)
  if valid_601016 != nil:
    section.add "ResourceARN", valid_601016
  var valid_601017 = query.getOrDefault("Tags")
  valid_601017 = validateParameter(valid_601017, JArray, required = true, default = nil)
  if valid_601017 != nil:
    section.add "Tags", valid_601017
  var valid_601018 = query.getOrDefault("Action")
  valid_601018 = validateParameter(valid_601018, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_601018 != nil:
    section.add "Action", valid_601018
  var valid_601019 = query.getOrDefault("Version")
  valid_601019 = validateParameter(valid_601019, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_601019 != nil:
    section.add "Version", valid_601019
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
  var valid_601020 = header.getOrDefault("X-Amz-Date")
  valid_601020 = validateParameter(valid_601020, JString, required = false,
                                 default = nil)
  if valid_601020 != nil:
    section.add "X-Amz-Date", valid_601020
  var valid_601021 = header.getOrDefault("X-Amz-Security-Token")
  valid_601021 = validateParameter(valid_601021, JString, required = false,
                                 default = nil)
  if valid_601021 != nil:
    section.add "X-Amz-Security-Token", valid_601021
  var valid_601022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601022 = validateParameter(valid_601022, JString, required = false,
                                 default = nil)
  if valid_601022 != nil:
    section.add "X-Amz-Content-Sha256", valid_601022
  var valid_601023 = header.getOrDefault("X-Amz-Algorithm")
  valid_601023 = validateParameter(valid_601023, JString, required = false,
                                 default = nil)
  if valid_601023 != nil:
    section.add "X-Amz-Algorithm", valid_601023
  var valid_601024 = header.getOrDefault("X-Amz-Signature")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "X-Amz-Signature", valid_601024
  var valid_601025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-SignedHeaders", valid_601025
  var valid_601026 = header.getOrDefault("X-Amz-Credential")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Credential", valid_601026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601027: Call_GetTagResource_601013; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_601027.validator(path, query, header, formData, body)
  let scheme = call_601027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601027.url(scheme.get, call_601027.host, call_601027.base,
                         call_601027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601027, url, valid)

proc call*(call_601028: Call_GetTagResource_601013; ResourceARN: string;
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
  var query_601029 = newJObject()
  add(query_601029, "ResourceARN", newJString(ResourceARN))
  if Tags != nil:
    query_601029.add "Tags", Tags
  add(query_601029, "Action", newJString(Action))
  add(query_601029, "Version", newJString(Version))
  result = call_601028.call(nil, query_601029, nil, nil, nil)

var getTagResource* = Call_GetTagResource_601013(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_601014,
    base: "/", url: url_GetTagResource_601015, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_601065 = ref object of OpenApiRestCall_599368
proc url_PostUntagResource_601067(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUntagResource_601066(path: JsonNode; query: JsonNode;
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
  var valid_601068 = query.getOrDefault("Action")
  valid_601068 = validateParameter(valid_601068, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_601068 != nil:
    section.add "Action", valid_601068
  var valid_601069 = query.getOrDefault("Version")
  valid_601069 = validateParameter(valid_601069, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_601069 != nil:
    section.add "Version", valid_601069
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
  var valid_601072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Content-Sha256", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Algorithm")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Algorithm", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Signature")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Signature", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-SignedHeaders", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Credential")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Credential", valid_601076
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
  var valid_601077 = formData.getOrDefault("ResourceARN")
  valid_601077 = validateParameter(valid_601077, JString, required = true,
                                 default = nil)
  if valid_601077 != nil:
    section.add "ResourceARN", valid_601077
  var valid_601078 = formData.getOrDefault("TagKeys")
  valid_601078 = validateParameter(valid_601078, JArray, required = true, default = nil)
  if valid_601078 != nil:
    section.add "TagKeys", valid_601078
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_PostUntagResource_601065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601079, url, valid)

proc call*(call_601080: Call_PostUntagResource_601065; ResourceARN: string;
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
  var query_601081 = newJObject()
  var formData_601082 = newJObject()
  add(query_601081, "Action", newJString(Action))
  add(formData_601082, "ResourceARN", newJString(ResourceARN))
  if TagKeys != nil:
    formData_601082.add "TagKeys", TagKeys
  add(query_601081, "Version", newJString(Version))
  result = call_601080.call(nil, query_601081, nil, formData_601082, nil)

var postUntagResource* = Call_PostUntagResource_601065(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_601066,
    base: "/", url: url_PostUntagResource_601067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_601048 = ref object of OpenApiRestCall_599368
proc url_GetUntagResource_601050(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUntagResource_601049(path: JsonNode; query: JsonNode;
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
  var valid_601051 = query.getOrDefault("ResourceARN")
  valid_601051 = validateParameter(valid_601051, JString, required = true,
                                 default = nil)
  if valid_601051 != nil:
    section.add "ResourceARN", valid_601051
  var valid_601052 = query.getOrDefault("Action")
  valid_601052 = validateParameter(valid_601052, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_601052 != nil:
    section.add "Action", valid_601052
  var valid_601053 = query.getOrDefault("TagKeys")
  valid_601053 = validateParameter(valid_601053, JArray, required = true, default = nil)
  if valid_601053 != nil:
    section.add "TagKeys", valid_601053
  var valid_601054 = query.getOrDefault("Version")
  valid_601054 = validateParameter(valid_601054, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_601054 != nil:
    section.add "Version", valid_601054
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
  var valid_601057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Content-Sha256", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Algorithm")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Algorithm", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Signature")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Signature", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-SignedHeaders", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Credential")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Credential", valid_601061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601062: Call_GetUntagResource_601048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_601062.validator(path, query, header, formData, body)
  let scheme = call_601062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601062.url(scheme.get, call_601062.host, call_601062.base,
                         call_601062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601062, url, valid)

proc call*(call_601063: Call_GetUntagResource_601048; ResourceARN: string;
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
  var query_601064 = newJObject()
  add(query_601064, "ResourceARN", newJString(ResourceARN))
  add(query_601064, "Action", newJString(Action))
  if TagKeys != nil:
    query_601064.add "TagKeys", TagKeys
  add(query_601064, "Version", newJString(Version))
  result = call_601063.call(nil, query_601064, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_601048(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_601049,
    base: "/", url: url_GetUntagResource_601050,
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
