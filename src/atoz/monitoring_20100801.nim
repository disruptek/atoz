
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
  Call_PostDeleteAlarms_601998 = ref object of OpenApiRestCall_601389
proc url_PostDeleteAlarms_602000(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteAlarms_601999(path: JsonNode; query: JsonNode;
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
  var valid_602001 = query.getOrDefault("Action")
  valid_602001 = validateParameter(valid_602001, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_602001 != nil:
    section.add "Action", valid_602001
  var valid_602002 = query.getOrDefault("Version")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602002 != nil:
    section.add "Version", valid_602002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602003 = header.getOrDefault("X-Amz-Signature")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Signature", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Content-Sha256", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Date")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Date", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Credential")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Credential", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Security-Token")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Security-Token", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Algorithm")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Algorithm", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-SignedHeaders", valid_602009
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_602010 = formData.getOrDefault("AlarmNames")
  valid_602010 = validateParameter(valid_602010, JArray, required = true, default = nil)
  if valid_602010 != nil:
    section.add "AlarmNames", valid_602010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602011: Call_PostDeleteAlarms_601998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_602011.validator(path, query, header, formData, body)
  let scheme = call_602011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602011.url(scheme.get, call_602011.host, call_602011.base,
                         call_602011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602011, url, valid)

proc call*(call_602012: Call_PostDeleteAlarms_601998; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  var query_602013 = newJObject()
  var formData_602014 = newJObject()
  add(query_602013, "Action", newJString(Action))
  add(query_602013, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_602014.add "AlarmNames", AlarmNames
  result = call_602012.call(nil, query_602013, nil, formData_602014, nil)

var postDeleteAlarms* = Call_PostDeleteAlarms_601998(name: "postDeleteAlarms",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_PostDeleteAlarms_601999,
    base: "/", url: url_PostDeleteAlarms_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAlarms_601727 = ref object of OpenApiRestCall_601389
proc url_GetDeleteAlarms_601729(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteAlarms_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = query.getOrDefault("AlarmNames")
  valid_601841 = validateParameter(valid_601841, JArray, required = true, default = nil)
  if valid_601841 != nil:
    section.add "AlarmNames", valid_601841
  var valid_601855 = query.getOrDefault("Action")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = newJString("DeleteAlarms"))
  if valid_601855 != nil:
    section.add "Action", valid_601855
  var valid_601856 = query.getOrDefault("Version")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_601856 != nil:
    section.add "Version", valid_601856
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601857 = header.getOrDefault("X-Amz-Signature")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Signature", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Content-Sha256", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Date")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Date", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Credential")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Credential", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Security-Token")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Security-Token", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Algorithm")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Algorithm", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-SignedHeaders", valid_601863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601886: Call_GetDeleteAlarms_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601886, url, valid)

proc call*(call_601957: Call_GetDeleteAlarms_601727; AlarmNames: JsonNode;
          Action: string = "DeleteAlarms"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteAlarms
  ## Deletes the specified alarms. You can delete up to 50 alarms in one operation. In the event of an error, no alarms are deleted.
  ##   AlarmNames: JArray (required)
  ##             : The alarms to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601958 = newJObject()
  if AlarmNames != nil:
    query_601958.add "AlarmNames", AlarmNames
  add(query_601958, "Action", newJString(Action))
  add(query_601958, "Version", newJString(Version))
  result = call_601957.call(nil, query_601958, nil, nil, nil)

var getDeleteAlarms* = Call_GetDeleteAlarms_601727(name: "getDeleteAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DeleteAlarms", validator: validate_GetDeleteAlarms_601728,
    base: "/", url: url_GetDeleteAlarms_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnomalyDetector_602034 = ref object of OpenApiRestCall_601389
proc url_PostDeleteAnomalyDetector_602036(protocol: Scheme; host: string;
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

proc validate_PostDeleteAnomalyDetector_602035(path: JsonNode; query: JsonNode;
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
  var valid_602037 = query.getOrDefault("Action")
  valid_602037 = validateParameter(valid_602037, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_602037 != nil:
    section.add "Action", valid_602037
  var valid_602038 = query.getOrDefault("Version")
  valid_602038 = validateParameter(valid_602038, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602038 != nil:
    section.add "Version", valid_602038
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602039 = header.getOrDefault("X-Amz-Signature")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Signature", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Content-Sha256", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Date")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Date", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Credential")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Credential", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Security-Token")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Security-Token", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Algorithm")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Algorithm", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-SignedHeaders", valid_602045
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
  var valid_602046 = formData.getOrDefault("Stat")
  valid_602046 = validateParameter(valid_602046, JString, required = true,
                                 default = nil)
  if valid_602046 != nil:
    section.add "Stat", valid_602046
  var valid_602047 = formData.getOrDefault("MetricName")
  valid_602047 = validateParameter(valid_602047, JString, required = true,
                                 default = nil)
  if valid_602047 != nil:
    section.add "MetricName", valid_602047
  var valid_602048 = formData.getOrDefault("Dimensions")
  valid_602048 = validateParameter(valid_602048, JArray, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "Dimensions", valid_602048
  var valid_602049 = formData.getOrDefault("Namespace")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = nil)
  if valid_602049 != nil:
    section.add "Namespace", valid_602049
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602050: Call_PostDeleteAnomalyDetector_602034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_602050.validator(path, query, header, formData, body)
  let scheme = call_602050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602050.url(scheme.get, call_602050.host, call_602050.base,
                         call_602050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602050, url, valid)

proc call*(call_602051: Call_PostDeleteAnomalyDetector_602034; Stat: string;
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
  var query_602052 = newJObject()
  var formData_602053 = newJObject()
  add(formData_602053, "Stat", newJString(Stat))
  add(formData_602053, "MetricName", newJString(MetricName))
  add(query_602052, "Action", newJString(Action))
  if Dimensions != nil:
    formData_602053.add "Dimensions", Dimensions
  add(formData_602053, "Namespace", newJString(Namespace))
  add(query_602052, "Version", newJString(Version))
  result = call_602051.call(nil, query_602052, nil, formData_602053, nil)

var postDeleteAnomalyDetector* = Call_PostDeleteAnomalyDetector_602034(
    name: "postDeleteAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_PostDeleteAnomalyDetector_602035, base: "/",
    url: url_PostDeleteAnomalyDetector_602036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnomalyDetector_602015 = ref object of OpenApiRestCall_601389
proc url_GetDeleteAnomalyDetector_602017(protocol: Scheme; host: string;
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

proc validate_GetDeleteAnomalyDetector_602016(path: JsonNode; query: JsonNode;
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
  var valid_602018 = query.getOrDefault("Namespace")
  valid_602018 = validateParameter(valid_602018, JString, required = true,
                                 default = nil)
  if valid_602018 != nil:
    section.add "Namespace", valid_602018
  var valid_602019 = query.getOrDefault("Dimensions")
  valid_602019 = validateParameter(valid_602019, JArray, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "Dimensions", valid_602019
  var valid_602020 = query.getOrDefault("Action")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = newJString("DeleteAnomalyDetector"))
  if valid_602020 != nil:
    section.add "Action", valid_602020
  var valid_602021 = query.getOrDefault("Version")
  valid_602021 = validateParameter(valid_602021, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602021 != nil:
    section.add "Version", valid_602021
  var valid_602022 = query.getOrDefault("MetricName")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = nil)
  if valid_602022 != nil:
    section.add "MetricName", valid_602022
  var valid_602023 = query.getOrDefault("Stat")
  valid_602023 = validateParameter(valid_602023, JString, required = true,
                                 default = nil)
  if valid_602023 != nil:
    section.add "Stat", valid_602023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602024 = header.getOrDefault("X-Amz-Signature")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Signature", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Content-Sha256", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Date")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Date", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Credential")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Credential", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Security-Token")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Security-Token", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Algorithm")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Algorithm", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-SignedHeaders", valid_602030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602031: Call_GetDeleteAnomalyDetector_602015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified anomaly detection model from your account.
  ## 
  let valid = call_602031.validator(path, query, header, formData, body)
  let scheme = call_602031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602031.url(scheme.get, call_602031.host, call_602031.base,
                         call_602031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602031, url, valid)

proc call*(call_602032: Call_GetDeleteAnomalyDetector_602015; Namespace: string;
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
  var query_602033 = newJObject()
  add(query_602033, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_602033.add "Dimensions", Dimensions
  add(query_602033, "Action", newJString(Action))
  add(query_602033, "Version", newJString(Version))
  add(query_602033, "MetricName", newJString(MetricName))
  add(query_602033, "Stat", newJString(Stat))
  result = call_602032.call(nil, query_602033, nil, nil, nil)

var getDeleteAnomalyDetector* = Call_GetDeleteAnomalyDetector_602015(
    name: "getDeleteAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteAnomalyDetector",
    validator: validate_GetDeleteAnomalyDetector_602016, base: "/",
    url: url_GetDeleteAnomalyDetector_602017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDashboards_602070 = ref object of OpenApiRestCall_601389
proc url_PostDeleteDashboards_602072(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDashboards_602071(path: JsonNode; query: JsonNode;
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
  var valid_602073 = query.getOrDefault("Action")
  valid_602073 = validateParameter(valid_602073, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_602073 != nil:
    section.add "Action", valid_602073
  var valid_602074 = query.getOrDefault("Version")
  valid_602074 = validateParameter(valid_602074, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602074 != nil:
    section.add "Version", valid_602074
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  ## parameters in `formData` object:
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardNames` field"
  var valid_602082 = formData.getOrDefault("DashboardNames")
  valid_602082 = validateParameter(valid_602082, JArray, required = true, default = nil)
  if valid_602082 != nil:
    section.add "DashboardNames", valid_602082
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_PostDeleteDashboards_602070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_PostDeleteDashboards_602070; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602085 = newJObject()
  var formData_602086 = newJObject()
  if DashboardNames != nil:
    formData_602086.add "DashboardNames", DashboardNames
  add(query_602085, "Action", newJString(Action))
  add(query_602085, "Version", newJString(Version))
  result = call_602084.call(nil, query_602085, nil, formData_602086, nil)

var postDeleteDashboards* = Call_PostDeleteDashboards_602070(
    name: "postDeleteDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_PostDeleteDashboards_602071, base: "/",
    url: url_PostDeleteDashboards_602072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDashboards_602054 = ref object of OpenApiRestCall_601389
proc url_GetDeleteDashboards_602056(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDashboards_602055(path: JsonNode; query: JsonNode;
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
  var valid_602057 = query.getOrDefault("DashboardNames")
  valid_602057 = validateParameter(valid_602057, JArray, required = true, default = nil)
  if valid_602057 != nil:
    section.add "DashboardNames", valid_602057
  var valid_602058 = query.getOrDefault("Action")
  valid_602058 = validateParameter(valid_602058, JString, required = true,
                                 default = newJString("DeleteDashboards"))
  if valid_602058 != nil:
    section.add "Action", valid_602058
  var valid_602059 = query.getOrDefault("Version")
  valid_602059 = validateParameter(valid_602059, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602059 != nil:
    section.add "Version", valid_602059
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_602067: Call_GetDeleteDashboards_602054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ## 
  let valid = call_602067.validator(path, query, header, formData, body)
  let scheme = call_602067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602067.url(scheme.get, call_602067.host, call_602067.base,
                         call_602067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602067, url, valid)

proc call*(call_602068: Call_GetDeleteDashboards_602054; DashboardNames: JsonNode;
          Action: string = "DeleteDashboards"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteDashboards
  ## Deletes all dashboards that you specify. You may specify up to 100 dashboards to delete. If there is an error during this call, no dashboards are deleted.
  ##   DashboardNames: JArray (required)
  ##                 : The dashboards to be deleted. This parameter is required.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602069 = newJObject()
  if DashboardNames != nil:
    query_602069.add "DashboardNames", DashboardNames
  add(query_602069, "Action", newJString(Action))
  add(query_602069, "Version", newJString(Version))
  result = call_602068.call(nil, query_602069, nil, nil, nil)

var getDeleteDashboards* = Call_GetDeleteDashboards_602054(
    name: "getDeleteDashboards", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteDashboards",
    validator: validate_GetDeleteDashboards_602055, base: "/",
    url: url_GetDeleteDashboards_602056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteInsightRules_602103 = ref object of OpenApiRestCall_601389
proc url_PostDeleteInsightRules_602105(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteInsightRules_602104(path: JsonNode; query: JsonNode;
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
  var valid_602106 = query.getOrDefault("Action")
  valid_602106 = validateParameter(valid_602106, JString, required = true,
                                 default = newJString("DeleteInsightRules"))
  if valid_602106 != nil:
    section.add "Action", valid_602106
  var valid_602107 = query.getOrDefault("Version")
  valid_602107 = validateParameter(valid_602107, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602107 != nil:
    section.add "Version", valid_602107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602108 = header.getOrDefault("X-Amz-Signature")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Signature", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Content-Sha256", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Date")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Date", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Credential")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Credential", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Security-Token")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Security-Token", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Algorithm")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Algorithm", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-SignedHeaders", valid_602114
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_602115 = formData.getOrDefault("RuleNames")
  valid_602115 = validateParameter(valid_602115, JArray, required = true, default = nil)
  if valid_602115 != nil:
    section.add "RuleNames", valid_602115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602116: Call_PostDeleteInsightRules_602103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_602116.validator(path, query, header, formData, body)
  let scheme = call_602116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602116.url(scheme.get, call_602116.host, call_602116.base,
                         call_602116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602116, url, valid)

proc call*(call_602117: Call_PostDeleteInsightRules_602103; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602118 = newJObject()
  var formData_602119 = newJObject()
  if RuleNames != nil:
    formData_602119.add "RuleNames", RuleNames
  add(query_602118, "Action", newJString(Action))
  add(query_602118, "Version", newJString(Version))
  result = call_602117.call(nil, query_602118, nil, formData_602119, nil)

var postDeleteInsightRules* = Call_PostDeleteInsightRules_602103(
    name: "postDeleteInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_PostDeleteInsightRules_602104, base: "/",
    url: url_PostDeleteInsightRules_602105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteInsightRules_602087 = ref object of OpenApiRestCall_601389
proc url_GetDeleteInsightRules_602089(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteInsightRules_602088(path: JsonNode; query: JsonNode;
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
  var valid_602090 = query.getOrDefault("Action")
  valid_602090 = validateParameter(valid_602090, JString, required = true,
                                 default = newJString("DeleteInsightRules"))
  if valid_602090 != nil:
    section.add "Action", valid_602090
  var valid_602091 = query.getOrDefault("RuleNames")
  valid_602091 = validateParameter(valid_602091, JArray, required = true, default = nil)
  if valid_602091 != nil:
    section.add "RuleNames", valid_602091
  var valid_602092 = query.getOrDefault("Version")
  valid_602092 = validateParameter(valid_602092, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602092 != nil:
    section.add "Version", valid_602092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602093 = header.getOrDefault("X-Amz-Signature")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Signature", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Content-Sha256", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Date")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Date", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Credential")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Credential", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Security-Token")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Security-Token", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Algorithm")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Algorithm", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-SignedHeaders", valid_602099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602100: Call_GetDeleteInsightRules_602087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_602100.validator(path, query, header, formData, body)
  let scheme = call_602100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602100.url(scheme.get, call_602100.host, call_602100.base,
                         call_602100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602100, url, valid)

proc call*(call_602101: Call_GetDeleteInsightRules_602087; RuleNames: JsonNode;
          Action: string = "DeleteInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDeleteInsightRules
  ## <p>Permanently deletes the specified Contributor Insights rules.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to delete. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_602102 = newJObject()
  add(query_602102, "Action", newJString(Action))
  if RuleNames != nil:
    query_602102.add "RuleNames", RuleNames
  add(query_602102, "Version", newJString(Version))
  result = call_602101.call(nil, query_602102, nil, nil, nil)

var getDeleteInsightRules* = Call_GetDeleteInsightRules_602087(
    name: "getDeleteInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DeleteInsightRules",
    validator: validate_GetDeleteInsightRules_602088, base: "/",
    url: url_GetDeleteInsightRules_602089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmHistory_602141 = ref object of OpenApiRestCall_601389
proc url_PostDescribeAlarmHistory_602143(protocol: Scheme; host: string;
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

proc validate_PostDescribeAlarmHistory_602142(path: JsonNode; query: JsonNode;
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
  var valid_602144 = query.getOrDefault("Action")
  valid_602144 = validateParameter(valid_602144, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_602144 != nil:
    section.add "Action", valid_602144
  var valid_602145 = query.getOrDefault("Version")
  valid_602145 = validateParameter(valid_602145, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602145 != nil:
    section.add "Version", valid_602145
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602146 = header.getOrDefault("X-Amz-Signature")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Signature", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Content-Sha256", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Date")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Date", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Credential")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Credential", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Security-Token")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Security-Token", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Algorithm")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Algorithm", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-SignedHeaders", valid_602152
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
  var valid_602153 = formData.getOrDefault("AlarmName")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "AlarmName", valid_602153
  var valid_602154 = formData.getOrDefault("HistoryItemType")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_602154 != nil:
    section.add "HistoryItemType", valid_602154
  var valid_602155 = formData.getOrDefault("MaxRecords")
  valid_602155 = validateParameter(valid_602155, JInt, required = false, default = nil)
  if valid_602155 != nil:
    section.add "MaxRecords", valid_602155
  var valid_602156 = formData.getOrDefault("EndDate")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "EndDate", valid_602156
  var valid_602157 = formData.getOrDefault("NextToken")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "NextToken", valid_602157
  var valid_602158 = formData.getOrDefault("StartDate")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "StartDate", valid_602158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602159: Call_PostDescribeAlarmHistory_602141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_602159.validator(path, query, header, formData, body)
  let scheme = call_602159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602159.url(scheme.get, call_602159.host, call_602159.base,
                         call_602159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602159, url, valid)

proc call*(call_602160: Call_PostDescribeAlarmHistory_602141;
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
  var query_602161 = newJObject()
  var formData_602162 = newJObject()
  add(formData_602162, "AlarmName", newJString(AlarmName))
  add(formData_602162, "HistoryItemType", newJString(HistoryItemType))
  add(formData_602162, "MaxRecords", newJInt(MaxRecords))
  add(formData_602162, "EndDate", newJString(EndDate))
  add(formData_602162, "NextToken", newJString(NextToken))
  add(formData_602162, "StartDate", newJString(StartDate))
  add(query_602161, "Action", newJString(Action))
  add(query_602161, "Version", newJString(Version))
  result = call_602160.call(nil, query_602161, nil, formData_602162, nil)

var postDescribeAlarmHistory* = Call_PostDescribeAlarmHistory_602141(
    name: "postDescribeAlarmHistory", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_PostDescribeAlarmHistory_602142, base: "/",
    url: url_PostDescribeAlarmHistory_602143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmHistory_602120 = ref object of OpenApiRestCall_601389
proc url_GetDescribeAlarmHistory_602122(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeAlarmHistory_602121(path: JsonNode; query: JsonNode;
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
  var valid_602123 = query.getOrDefault("EndDate")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "EndDate", valid_602123
  var valid_602124 = query.getOrDefault("NextToken")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "NextToken", valid_602124
  var valid_602125 = query.getOrDefault("HistoryItemType")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = newJString("ConfigurationUpdate"))
  if valid_602125 != nil:
    section.add "HistoryItemType", valid_602125
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602126 = query.getOrDefault("Action")
  valid_602126 = validateParameter(valid_602126, JString, required = true,
                                 default = newJString("DescribeAlarmHistory"))
  if valid_602126 != nil:
    section.add "Action", valid_602126
  var valid_602127 = query.getOrDefault("AlarmName")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "AlarmName", valid_602127
  var valid_602128 = query.getOrDefault("StartDate")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "StartDate", valid_602128
  var valid_602129 = query.getOrDefault("Version")
  valid_602129 = validateParameter(valid_602129, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602129 != nil:
    section.add "Version", valid_602129
  var valid_602130 = query.getOrDefault("MaxRecords")
  valid_602130 = validateParameter(valid_602130, JInt, required = false, default = nil)
  if valid_602130 != nil:
    section.add "MaxRecords", valid_602130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602131 = header.getOrDefault("X-Amz-Signature")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Signature", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Content-Sha256", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Date")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Date", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Credential")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Credential", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Security-Token")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Security-Token", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Algorithm")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Algorithm", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-SignedHeaders", valid_602137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602138: Call_GetDescribeAlarmHistory_602120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the history for the specified alarm. You can filter the results by date range or item type. If an alarm name is not specified, the histories for all alarms are returned.</p> <p>CloudWatch retains the history of an alarm even if you delete the alarm.</p>
  ## 
  let valid = call_602138.validator(path, query, header, formData, body)
  let scheme = call_602138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602138.url(scheme.get, call_602138.host, call_602138.base,
                         call_602138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602138, url, valid)

proc call*(call_602139: Call_GetDescribeAlarmHistory_602120; EndDate: string = "";
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
  var query_602140 = newJObject()
  add(query_602140, "EndDate", newJString(EndDate))
  add(query_602140, "NextToken", newJString(NextToken))
  add(query_602140, "HistoryItemType", newJString(HistoryItemType))
  add(query_602140, "Action", newJString(Action))
  add(query_602140, "AlarmName", newJString(AlarmName))
  add(query_602140, "StartDate", newJString(StartDate))
  add(query_602140, "Version", newJString(Version))
  add(query_602140, "MaxRecords", newJInt(MaxRecords))
  result = call_602139.call(nil, query_602140, nil, nil, nil)

var getDescribeAlarmHistory* = Call_GetDescribeAlarmHistory_602120(
    name: "getDescribeAlarmHistory", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmHistory",
    validator: validate_GetDescribeAlarmHistory_602121, base: "/",
    url: url_GetDescribeAlarmHistory_602122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarms_602184 = ref object of OpenApiRestCall_601389
proc url_PostDescribeAlarms_602186(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeAlarms_602185(path: JsonNode; query: JsonNode;
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
  var valid_602187 = query.getOrDefault("Action")
  valid_602187 = validateParameter(valid_602187, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_602187 != nil:
    section.add "Action", valid_602187
  var valid_602188 = query.getOrDefault("Version")
  valid_602188 = validateParameter(valid_602188, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602188 != nil:
    section.add "Version", valid_602188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602189 = header.getOrDefault("X-Amz-Signature")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Signature", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Content-Sha256", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Date")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Date", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Credential")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Credential", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Security-Token")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Security-Token", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Algorithm")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Algorithm", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-SignedHeaders", valid_602195
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
  var valid_602196 = formData.getOrDefault("AlarmNamePrefix")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "AlarmNamePrefix", valid_602196
  var valid_602197 = formData.getOrDefault("StateValue")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = newJString("OK"))
  if valid_602197 != nil:
    section.add "StateValue", valid_602197
  var valid_602198 = formData.getOrDefault("NextToken")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "NextToken", valid_602198
  var valid_602199 = formData.getOrDefault("MaxRecords")
  valid_602199 = validateParameter(valid_602199, JInt, required = false, default = nil)
  if valid_602199 != nil:
    section.add "MaxRecords", valid_602199
  var valid_602200 = formData.getOrDefault("ActionPrefix")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "ActionPrefix", valid_602200
  var valid_602201 = formData.getOrDefault("AlarmNames")
  valid_602201 = validateParameter(valid_602201, JArray, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "AlarmNames", valid_602201
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602202: Call_PostDescribeAlarms_602184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_602202.validator(path, query, header, formData, body)
  let scheme = call_602202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602202.url(scheme.get, call_602202.host, call_602202.base,
                         call_602202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602202, url, valid)

proc call*(call_602203: Call_PostDescribeAlarms_602184;
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
  var query_602204 = newJObject()
  var formData_602205 = newJObject()
  add(formData_602205, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  add(formData_602205, "StateValue", newJString(StateValue))
  add(formData_602205, "NextToken", newJString(NextToken))
  add(formData_602205, "MaxRecords", newJInt(MaxRecords))
  add(query_602204, "Action", newJString(Action))
  add(formData_602205, "ActionPrefix", newJString(ActionPrefix))
  add(query_602204, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_602205.add "AlarmNames", AlarmNames
  result = call_602203.call(nil, query_602204, nil, formData_602205, nil)

var postDescribeAlarms* = Call_PostDescribeAlarms_602184(
    name: "postDescribeAlarms", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarms",
    validator: validate_PostDescribeAlarms_602185, base: "/",
    url: url_PostDescribeAlarms_602186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarms_602163 = ref object of OpenApiRestCall_601389
proc url_GetDescribeAlarms_602165(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeAlarms_602164(path: JsonNode; query: JsonNode;
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
  var valid_602166 = query.getOrDefault("StateValue")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = newJString("OK"))
  if valid_602166 != nil:
    section.add "StateValue", valid_602166
  var valid_602167 = query.getOrDefault("ActionPrefix")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "ActionPrefix", valid_602167
  var valid_602168 = query.getOrDefault("NextToken")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "NextToken", valid_602168
  var valid_602169 = query.getOrDefault("AlarmNamePrefix")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "AlarmNamePrefix", valid_602169
  var valid_602170 = query.getOrDefault("AlarmNames")
  valid_602170 = validateParameter(valid_602170, JArray, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "AlarmNames", valid_602170
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602171 = query.getOrDefault("Action")
  valid_602171 = validateParameter(valid_602171, JString, required = true,
                                 default = newJString("DescribeAlarms"))
  if valid_602171 != nil:
    section.add "Action", valid_602171
  var valid_602172 = query.getOrDefault("Version")
  valid_602172 = validateParameter(valid_602172, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602172 != nil:
    section.add "Version", valid_602172
  var valid_602173 = query.getOrDefault("MaxRecords")
  valid_602173 = validateParameter(valid_602173, JInt, required = false, default = nil)
  if valid_602173 != nil:
    section.add "MaxRecords", valid_602173
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602174 = header.getOrDefault("X-Amz-Signature")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Signature", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Content-Sha256", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Date")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Date", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Credential")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Credential", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Security-Token")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Security-Token", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Algorithm")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Algorithm", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-SignedHeaders", valid_602180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602181: Call_GetDescribeAlarms_602163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified alarms. If no alarms are specified, all alarms are returned. Alarms can be retrieved by using only a prefix for the alarm name, the alarm state, or a prefix for any action.
  ## 
  let valid = call_602181.validator(path, query, header, formData, body)
  let scheme = call_602181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602181.url(scheme.get, call_602181.host, call_602181.base,
                         call_602181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602181, url, valid)

proc call*(call_602182: Call_GetDescribeAlarms_602163; StateValue: string = "OK";
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
  var query_602183 = newJObject()
  add(query_602183, "StateValue", newJString(StateValue))
  add(query_602183, "ActionPrefix", newJString(ActionPrefix))
  add(query_602183, "NextToken", newJString(NextToken))
  add(query_602183, "AlarmNamePrefix", newJString(AlarmNamePrefix))
  if AlarmNames != nil:
    query_602183.add "AlarmNames", AlarmNames
  add(query_602183, "Action", newJString(Action))
  add(query_602183, "Version", newJString(Version))
  add(query_602183, "MaxRecords", newJInt(MaxRecords))
  result = call_602182.call(nil, query_602183, nil, nil, nil)

var getDescribeAlarms* = Call_GetDescribeAlarms_602163(name: "getDescribeAlarms",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=DescribeAlarms", validator: validate_GetDescribeAlarms_602164,
    base: "/", url: url_GetDescribeAlarms_602165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAlarmsForMetric_602228 = ref object of OpenApiRestCall_601389
proc url_PostDescribeAlarmsForMetric_602230(protocol: Scheme; host: string;
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

proc validate_PostDescribeAlarmsForMetric_602229(path: JsonNode; query: JsonNode;
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
  var valid_602231 = query.getOrDefault("Action")
  valid_602231 = validateParameter(valid_602231, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_602231 != nil:
    section.add "Action", valid_602231
  var valid_602232 = query.getOrDefault("Version")
  valid_602232 = validateParameter(valid_602232, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602232 != nil:
    section.add "Version", valid_602232
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602233 = header.getOrDefault("X-Amz-Signature")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Signature", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Content-Sha256", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Date")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Date", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Credential")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Credential", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Security-Token")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Security-Token", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Algorithm")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Algorithm", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-SignedHeaders", valid_602239
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
  var valid_602240 = formData.getOrDefault("Unit")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_602240 != nil:
    section.add "Unit", valid_602240
  var valid_602241 = formData.getOrDefault("Period")
  valid_602241 = validateParameter(valid_602241, JInt, required = false, default = nil)
  if valid_602241 != nil:
    section.add "Period", valid_602241
  var valid_602242 = formData.getOrDefault("Statistic")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_602242 != nil:
    section.add "Statistic", valid_602242
  assert formData != nil,
        "formData argument is necessary due to required `MetricName` field"
  var valid_602243 = formData.getOrDefault("MetricName")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = nil)
  if valid_602243 != nil:
    section.add "MetricName", valid_602243
  var valid_602244 = formData.getOrDefault("Dimensions")
  valid_602244 = validateParameter(valid_602244, JArray, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "Dimensions", valid_602244
  var valid_602245 = formData.getOrDefault("Namespace")
  valid_602245 = validateParameter(valid_602245, JString, required = true,
                                 default = nil)
  if valid_602245 != nil:
    section.add "Namespace", valid_602245
  var valid_602246 = formData.getOrDefault("ExtendedStatistic")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "ExtendedStatistic", valid_602246
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602247: Call_PostDescribeAlarmsForMetric_602228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_602247.validator(path, query, header, formData, body)
  let scheme = call_602247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602247.url(scheme.get, call_602247.host, call_602247.base,
                         call_602247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602247, url, valid)

proc call*(call_602248: Call_PostDescribeAlarmsForMetric_602228;
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
  var query_602249 = newJObject()
  var formData_602250 = newJObject()
  add(formData_602250, "Unit", newJString(Unit))
  add(formData_602250, "Period", newJInt(Period))
  add(formData_602250, "Statistic", newJString(Statistic))
  add(formData_602250, "MetricName", newJString(MetricName))
  add(query_602249, "Action", newJString(Action))
  if Dimensions != nil:
    formData_602250.add "Dimensions", Dimensions
  add(formData_602250, "Namespace", newJString(Namespace))
  add(formData_602250, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_602249, "Version", newJString(Version))
  result = call_602248.call(nil, query_602249, nil, formData_602250, nil)

var postDescribeAlarmsForMetric* = Call_PostDescribeAlarmsForMetric_602228(
    name: "postDescribeAlarmsForMetric", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_PostDescribeAlarmsForMetric_602229, base: "/",
    url: url_PostDescribeAlarmsForMetric_602230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAlarmsForMetric_602206 = ref object of OpenApiRestCall_601389
proc url_GetDescribeAlarmsForMetric_602208(protocol: Scheme; host: string;
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

proc validate_GetDescribeAlarmsForMetric_602207(path: JsonNode; query: JsonNode;
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
  var valid_602209 = query.getOrDefault("Statistic")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_602209 != nil:
    section.add "Statistic", valid_602209
  var valid_602210 = query.getOrDefault("Unit")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_602210 != nil:
    section.add "Unit", valid_602210
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_602211 = query.getOrDefault("Namespace")
  valid_602211 = validateParameter(valid_602211, JString, required = true,
                                 default = nil)
  if valid_602211 != nil:
    section.add "Namespace", valid_602211
  var valid_602212 = query.getOrDefault("ExtendedStatistic")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "ExtendedStatistic", valid_602212
  var valid_602213 = query.getOrDefault("Period")
  valid_602213 = validateParameter(valid_602213, JInt, required = false, default = nil)
  if valid_602213 != nil:
    section.add "Period", valid_602213
  var valid_602214 = query.getOrDefault("Dimensions")
  valid_602214 = validateParameter(valid_602214, JArray, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "Dimensions", valid_602214
  var valid_602215 = query.getOrDefault("Action")
  valid_602215 = validateParameter(valid_602215, JString, required = true, default = newJString(
      "DescribeAlarmsForMetric"))
  if valid_602215 != nil:
    section.add "Action", valid_602215
  var valid_602216 = query.getOrDefault("Version")
  valid_602216 = validateParameter(valid_602216, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602216 != nil:
    section.add "Version", valid_602216
  var valid_602217 = query.getOrDefault("MetricName")
  valid_602217 = validateParameter(valid_602217, JString, required = true,
                                 default = nil)
  if valid_602217 != nil:
    section.add "MetricName", valid_602217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602218 = header.getOrDefault("X-Amz-Signature")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Signature", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Content-Sha256", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Date")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Date", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Credential")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Credential", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Security-Token")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Security-Token", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Algorithm")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Algorithm", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-SignedHeaders", valid_602224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602225: Call_GetDescribeAlarmsForMetric_602206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the alarms for the specified metric. To filter the results, specify a statistic, period, or unit.
  ## 
  let valid = call_602225.validator(path, query, header, formData, body)
  let scheme = call_602225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602225.url(scheme.get, call_602225.host, call_602225.base,
                         call_602225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602225, url, valid)

proc call*(call_602226: Call_GetDescribeAlarmsForMetric_602206; Namespace: string;
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
  var query_602227 = newJObject()
  add(query_602227, "Statistic", newJString(Statistic))
  add(query_602227, "Unit", newJString(Unit))
  add(query_602227, "Namespace", newJString(Namespace))
  add(query_602227, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_602227, "Period", newJInt(Period))
  if Dimensions != nil:
    query_602227.add "Dimensions", Dimensions
  add(query_602227, "Action", newJString(Action))
  add(query_602227, "Version", newJString(Version))
  add(query_602227, "MetricName", newJString(MetricName))
  result = call_602226.call(nil, query_602227, nil, nil, nil)

var getDescribeAlarmsForMetric* = Call_GetDescribeAlarmsForMetric_602206(
    name: "getDescribeAlarmsForMetric", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAlarmsForMetric",
    validator: validate_GetDescribeAlarmsForMetric_602207, base: "/",
    url: url_GetDescribeAlarmsForMetric_602208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnomalyDetectors_602271 = ref object of OpenApiRestCall_601389
proc url_PostDescribeAnomalyDetectors_602273(protocol: Scheme; host: string;
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

proc validate_PostDescribeAnomalyDetectors_602272(path: JsonNode; query: JsonNode;
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
  var valid_602274 = query.getOrDefault("Action")
  valid_602274 = validateParameter(valid_602274, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_602274 != nil:
    section.add "Action", valid_602274
  var valid_602275 = query.getOrDefault("Version")
  valid_602275 = validateParameter(valid_602275, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602275 != nil:
    section.add "Version", valid_602275
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602276 = header.getOrDefault("X-Amz-Signature")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Signature", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Content-Sha256", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Date")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Date", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Credential")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Credential", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Security-Token")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Security-Token", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Algorithm")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Algorithm", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-SignedHeaders", valid_602282
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
  var valid_602283 = formData.getOrDefault("NextToken")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "NextToken", valid_602283
  var valid_602284 = formData.getOrDefault("MetricName")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "MetricName", valid_602284
  var valid_602285 = formData.getOrDefault("Dimensions")
  valid_602285 = validateParameter(valid_602285, JArray, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "Dimensions", valid_602285
  var valid_602286 = formData.getOrDefault("Namespace")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "Namespace", valid_602286
  var valid_602287 = formData.getOrDefault("MaxResults")
  valid_602287 = validateParameter(valid_602287, JInt, required = false, default = nil)
  if valid_602287 != nil:
    section.add "MaxResults", valid_602287
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602288: Call_PostDescribeAnomalyDetectors_602271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_602288.validator(path, query, header, formData, body)
  let scheme = call_602288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602288.url(scheme.get, call_602288.host, call_602288.base,
                         call_602288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602288, url, valid)

proc call*(call_602289: Call_PostDescribeAnomalyDetectors_602271;
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
  var query_602290 = newJObject()
  var formData_602291 = newJObject()
  add(formData_602291, "NextToken", newJString(NextToken))
  add(formData_602291, "MetricName", newJString(MetricName))
  add(query_602290, "Action", newJString(Action))
  if Dimensions != nil:
    formData_602291.add "Dimensions", Dimensions
  add(formData_602291, "Namespace", newJString(Namespace))
  add(query_602290, "Version", newJString(Version))
  add(formData_602291, "MaxResults", newJInt(MaxResults))
  result = call_602289.call(nil, query_602290, nil, formData_602291, nil)

var postDescribeAnomalyDetectors* = Call_PostDescribeAnomalyDetectors_602271(
    name: "postDescribeAnomalyDetectors", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_PostDescribeAnomalyDetectors_602272, base: "/",
    url: url_PostDescribeAnomalyDetectors_602273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnomalyDetectors_602251 = ref object of OpenApiRestCall_601389
proc url_GetDescribeAnomalyDetectors_602253(protocol: Scheme; host: string;
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

proc validate_GetDescribeAnomalyDetectors_602252(path: JsonNode; query: JsonNode;
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
  var valid_602254 = query.getOrDefault("MaxResults")
  valid_602254 = validateParameter(valid_602254, JInt, required = false, default = nil)
  if valid_602254 != nil:
    section.add "MaxResults", valid_602254
  var valid_602255 = query.getOrDefault("NextToken")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "NextToken", valid_602255
  var valid_602256 = query.getOrDefault("Namespace")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "Namespace", valid_602256
  var valid_602257 = query.getOrDefault("Dimensions")
  valid_602257 = validateParameter(valid_602257, JArray, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "Dimensions", valid_602257
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602258 = query.getOrDefault("Action")
  valid_602258 = validateParameter(valid_602258, JString, required = true, default = newJString(
      "DescribeAnomalyDetectors"))
  if valid_602258 != nil:
    section.add "Action", valid_602258
  var valid_602259 = query.getOrDefault("Version")
  valid_602259 = validateParameter(valid_602259, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602259 != nil:
    section.add "Version", valid_602259
  var valid_602260 = query.getOrDefault("MetricName")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "MetricName", valid_602260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602261 = header.getOrDefault("X-Amz-Signature")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Signature", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Content-Sha256", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Date")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Date", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Credential")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Credential", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Security-Token")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Security-Token", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Algorithm")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Algorithm", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-SignedHeaders", valid_602267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602268: Call_GetDescribeAnomalyDetectors_602251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the anomaly detection models that you have created in your account. You can list all models in your account or filter the results to only the models that are related to a certain namespace, metric name, or metric dimension.
  ## 
  let valid = call_602268.validator(path, query, header, formData, body)
  let scheme = call_602268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602268.url(scheme.get, call_602268.host, call_602268.base,
                         call_602268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602268, url, valid)

proc call*(call_602269: Call_GetDescribeAnomalyDetectors_602251;
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
  var query_602270 = newJObject()
  add(query_602270, "MaxResults", newJInt(MaxResults))
  add(query_602270, "NextToken", newJString(NextToken))
  add(query_602270, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_602270.add "Dimensions", Dimensions
  add(query_602270, "Action", newJString(Action))
  add(query_602270, "Version", newJString(Version))
  add(query_602270, "MetricName", newJString(MetricName))
  result = call_602269.call(nil, query_602270, nil, nil, nil)

var getDescribeAnomalyDetectors* = Call_GetDescribeAnomalyDetectors_602251(
    name: "getDescribeAnomalyDetectors", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeAnomalyDetectors",
    validator: validate_GetDescribeAnomalyDetectors_602252, base: "/",
    url: url_GetDescribeAnomalyDetectors_602253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInsightRules_602309 = ref object of OpenApiRestCall_601389
proc url_PostDescribeInsightRules_602311(protocol: Scheme; host: string;
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

proc validate_PostDescribeInsightRules_602310(path: JsonNode; query: JsonNode;
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
  var valid_602312 = query.getOrDefault("Action")
  valid_602312 = validateParameter(valid_602312, JString, required = true,
                                 default = newJString("DescribeInsightRules"))
  if valid_602312 != nil:
    section.add "Action", valid_602312
  var valid_602313 = query.getOrDefault("Version")
  valid_602313 = validateParameter(valid_602313, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602313 != nil:
    section.add "Version", valid_602313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602314 = header.getOrDefault("X-Amz-Signature")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Signature", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Content-Sha256", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Date")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Date", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Credential")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Credential", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Security-Token")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Security-Token", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Algorithm")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Algorithm", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-SignedHeaders", valid_602320
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Reserved for future use.
  ##   MaxResults: JInt
  ##             : This parameter is not currently used. Reserved for future use. If it is used in the future, the maximum value may be different.
  section = newJObject()
  var valid_602321 = formData.getOrDefault("NextToken")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "NextToken", valid_602321
  var valid_602322 = formData.getOrDefault("MaxResults")
  valid_602322 = validateParameter(valid_602322, JInt, required = false, default = nil)
  if valid_602322 != nil:
    section.add "MaxResults", valid_602322
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602323: Call_PostDescribeInsightRules_602309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_602323.validator(path, query, header, formData, body)
  let scheme = call_602323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602323.url(scheme.get, call_602323.host, call_602323.base,
                         call_602323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602323, url, valid)

proc call*(call_602324: Call_PostDescribeInsightRules_602309;
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
  var query_602325 = newJObject()
  var formData_602326 = newJObject()
  add(formData_602326, "NextToken", newJString(NextToken))
  add(query_602325, "Action", newJString(Action))
  add(query_602325, "Version", newJString(Version))
  add(formData_602326, "MaxResults", newJInt(MaxResults))
  result = call_602324.call(nil, query_602325, nil, formData_602326, nil)

var postDescribeInsightRules* = Call_PostDescribeInsightRules_602309(
    name: "postDescribeInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_PostDescribeInsightRules_602310, base: "/",
    url: url_PostDescribeInsightRules_602311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInsightRules_602292 = ref object of OpenApiRestCall_601389
proc url_GetDescribeInsightRules_602294(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeInsightRules_602293(path: JsonNode; query: JsonNode;
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
  var valid_602295 = query.getOrDefault("MaxResults")
  valid_602295 = validateParameter(valid_602295, JInt, required = false, default = nil)
  if valid_602295 != nil:
    section.add "MaxResults", valid_602295
  var valid_602296 = query.getOrDefault("NextToken")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "NextToken", valid_602296
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602297 = query.getOrDefault("Action")
  valid_602297 = validateParameter(valid_602297, JString, required = true,
                                 default = newJString("DescribeInsightRules"))
  if valid_602297 != nil:
    section.add "Action", valid_602297
  var valid_602298 = query.getOrDefault("Version")
  valid_602298 = validateParameter(valid_602298, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602298 != nil:
    section.add "Version", valid_602298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602299 = header.getOrDefault("X-Amz-Signature")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Signature", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Content-Sha256", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Date")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Date", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Credential")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Credential", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Security-Token")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Security-Token", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Algorithm")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Algorithm", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-SignedHeaders", valid_602305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602306: Call_GetDescribeInsightRules_602292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all the Contributor Insights rules in your account. All rules in your account are returned with a single operation.</p> <p>For more information about Contributor Insights, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p>
  ## 
  let valid = call_602306.validator(path, query, header, formData, body)
  let scheme = call_602306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602306.url(scheme.get, call_602306.host, call_602306.base,
                         call_602306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602306, url, valid)

proc call*(call_602307: Call_GetDescribeInsightRules_602292; MaxResults: int = 0;
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
  var query_602308 = newJObject()
  add(query_602308, "MaxResults", newJInt(MaxResults))
  add(query_602308, "NextToken", newJString(NextToken))
  add(query_602308, "Action", newJString(Action))
  add(query_602308, "Version", newJString(Version))
  result = call_602307.call(nil, query_602308, nil, nil, nil)

var getDescribeInsightRules* = Call_GetDescribeInsightRules_602292(
    name: "getDescribeInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DescribeInsightRules",
    validator: validate_GetDescribeInsightRules_602293, base: "/",
    url: url_GetDescribeInsightRules_602294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAlarmActions_602343 = ref object of OpenApiRestCall_601389
proc url_PostDisableAlarmActions_602345(protocol: Scheme; host: string; base: string;
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

proc validate_PostDisableAlarmActions_602344(path: JsonNode; query: JsonNode;
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
  var valid_602346 = query.getOrDefault("Action")
  valid_602346 = validateParameter(valid_602346, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_602346 != nil:
    section.add "Action", valid_602346
  var valid_602347 = query.getOrDefault("Version")
  valid_602347 = validateParameter(valid_602347, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602347 != nil:
    section.add "Version", valid_602347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602348 = header.getOrDefault("X-Amz-Signature")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Signature", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Content-Sha256", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Date")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Date", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Credential")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Credential", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Security-Token")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Security-Token", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Algorithm")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Algorithm", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-SignedHeaders", valid_602354
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_602355 = formData.getOrDefault("AlarmNames")
  valid_602355 = validateParameter(valid_602355, JArray, required = true, default = nil)
  if valid_602355 != nil:
    section.add "AlarmNames", valid_602355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602356: Call_PostDisableAlarmActions_602343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_602356.validator(path, query, header, formData, body)
  let scheme = call_602356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602356.url(scheme.get, call_602356.host, call_602356.base,
                         call_602356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602356, url, valid)

proc call*(call_602357: Call_PostDisableAlarmActions_602343; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_602358 = newJObject()
  var formData_602359 = newJObject()
  add(query_602358, "Action", newJString(Action))
  add(query_602358, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_602359.add "AlarmNames", AlarmNames
  result = call_602357.call(nil, query_602358, nil, formData_602359, nil)

var postDisableAlarmActions* = Call_PostDisableAlarmActions_602343(
    name: "postDisableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_PostDisableAlarmActions_602344, base: "/",
    url: url_PostDisableAlarmActions_602345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAlarmActions_602327 = ref object of OpenApiRestCall_601389
proc url_GetDisableAlarmActions_602329(protocol: Scheme; host: string; base: string;
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

proc validate_GetDisableAlarmActions_602328(path: JsonNode; query: JsonNode;
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
  var valid_602330 = query.getOrDefault("AlarmNames")
  valid_602330 = validateParameter(valid_602330, JArray, required = true, default = nil)
  if valid_602330 != nil:
    section.add "AlarmNames", valid_602330
  var valid_602331 = query.getOrDefault("Action")
  valid_602331 = validateParameter(valid_602331, JString, required = true,
                                 default = newJString("DisableAlarmActions"))
  if valid_602331 != nil:
    section.add "Action", valid_602331
  var valid_602332 = query.getOrDefault("Version")
  valid_602332 = validateParameter(valid_602332, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602332 != nil:
    section.add "Version", valid_602332
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602333 = header.getOrDefault("X-Amz-Signature")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Signature", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Content-Sha256", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Date")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Date", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Credential")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Credential", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Security-Token")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Security-Token", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Algorithm")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Algorithm", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-SignedHeaders", valid_602339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602340: Call_GetDisableAlarmActions_602327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ## 
  let valid = call_602340.validator(path, query, header, formData, body)
  let scheme = call_602340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602340.url(scheme.get, call_602340.host, call_602340.base,
                         call_602340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602340, url, valid)

proc call*(call_602341: Call_GetDisableAlarmActions_602327; AlarmNames: JsonNode;
          Action: string = "DisableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getDisableAlarmActions
  ## Disables the actions for the specified alarms. When an alarm's actions are disabled, the alarm actions do not execute when the alarm state changes.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602342 = newJObject()
  if AlarmNames != nil:
    query_602342.add "AlarmNames", AlarmNames
  add(query_602342, "Action", newJString(Action))
  add(query_602342, "Version", newJString(Version))
  result = call_602341.call(nil, query_602342, nil, nil, nil)

var getDisableAlarmActions* = Call_GetDisableAlarmActions_602327(
    name: "getDisableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableAlarmActions",
    validator: validate_GetDisableAlarmActions_602328, base: "/",
    url: url_GetDisableAlarmActions_602329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableInsightRules_602376 = ref object of OpenApiRestCall_601389
proc url_PostDisableInsightRules_602378(protocol: Scheme; host: string; base: string;
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

proc validate_PostDisableInsightRules_602377(path: JsonNode; query: JsonNode;
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
  var valid_602379 = query.getOrDefault("Action")
  valid_602379 = validateParameter(valid_602379, JString, required = true,
                                 default = newJString("DisableInsightRules"))
  if valid_602379 != nil:
    section.add "Action", valid_602379
  var valid_602380 = query.getOrDefault("Version")
  valid_602380 = validateParameter(valid_602380, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602380 != nil:
    section.add "Version", valid_602380
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602381 = header.getOrDefault("X-Amz-Signature")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Signature", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Content-Sha256", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Date")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Date", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Credential")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Credential", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Security-Token")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Security-Token", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Algorithm")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Algorithm", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-SignedHeaders", valid_602387
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_602388 = formData.getOrDefault("RuleNames")
  valid_602388 = validateParameter(valid_602388, JArray, required = true, default = nil)
  if valid_602388 != nil:
    section.add "RuleNames", valid_602388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602389: Call_PostDisableInsightRules_602376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_602389.validator(path, query, header, formData, body)
  let scheme = call_602389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602389.url(scheme.get, call_602389.host, call_602389.base,
                         call_602389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602389, url, valid)

proc call*(call_602390: Call_PostDisableInsightRules_602376; RuleNames: JsonNode;
          Action: string = "DisableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602391 = newJObject()
  var formData_602392 = newJObject()
  if RuleNames != nil:
    formData_602392.add "RuleNames", RuleNames
  add(query_602391, "Action", newJString(Action))
  add(query_602391, "Version", newJString(Version))
  result = call_602390.call(nil, query_602391, nil, formData_602392, nil)

var postDisableInsightRules* = Call_PostDisableInsightRules_602376(
    name: "postDisableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_PostDisableInsightRules_602377, base: "/",
    url: url_PostDisableInsightRules_602378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableInsightRules_602360 = ref object of OpenApiRestCall_601389
proc url_GetDisableInsightRules_602362(protocol: Scheme; host: string; base: string;
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

proc validate_GetDisableInsightRules_602361(path: JsonNode; query: JsonNode;
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
  var valid_602363 = query.getOrDefault("Action")
  valid_602363 = validateParameter(valid_602363, JString, required = true,
                                 default = newJString("DisableInsightRules"))
  if valid_602363 != nil:
    section.add "Action", valid_602363
  var valid_602364 = query.getOrDefault("RuleNames")
  valid_602364 = validateParameter(valid_602364, JArray, required = true, default = nil)
  if valid_602364 != nil:
    section.add "RuleNames", valid_602364
  var valid_602365 = query.getOrDefault("Version")
  valid_602365 = validateParameter(valid_602365, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602365 != nil:
    section.add "Version", valid_602365
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602366 = header.getOrDefault("X-Amz-Signature")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Signature", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Content-Sha256", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Date")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Date", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Credential")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Credential", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Security-Token")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Security-Token", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Algorithm")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Algorithm", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-SignedHeaders", valid_602372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602373: Call_GetDisableInsightRules_602360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ## 
  let valid = call_602373.validator(path, query, header, formData, body)
  let scheme = call_602373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602373.url(scheme.get, call_602373.host, call_602373.base,
                         call_602373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602373, url, valid)

proc call*(call_602374: Call_GetDisableInsightRules_602360; RuleNames: JsonNode;
          Action: string = "DisableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getDisableInsightRules
  ## Disables the specified Contributor Insights rules. When rules are disabled, they do not analyze log groups and do not incur costs.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to disable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_602375 = newJObject()
  add(query_602375, "Action", newJString(Action))
  if RuleNames != nil:
    query_602375.add "RuleNames", RuleNames
  add(query_602375, "Version", newJString(Version))
  result = call_602374.call(nil, query_602375, nil, nil, nil)

var getDisableInsightRules* = Call_GetDisableInsightRules_602360(
    name: "getDisableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=DisableInsightRules",
    validator: validate_GetDisableInsightRules_602361, base: "/",
    url: url_GetDisableInsightRules_602362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAlarmActions_602409 = ref object of OpenApiRestCall_601389
proc url_PostEnableAlarmActions_602411(protocol: Scheme; host: string; base: string;
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

proc validate_PostEnableAlarmActions_602410(path: JsonNode; query: JsonNode;
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
  var valid_602412 = query.getOrDefault("Action")
  valid_602412 = validateParameter(valid_602412, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_602412 != nil:
    section.add "Action", valid_602412
  var valid_602413 = query.getOrDefault("Version")
  valid_602413 = validateParameter(valid_602413, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602413 != nil:
    section.add "Version", valid_602413
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602414 = header.getOrDefault("X-Amz-Signature")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Signature", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Content-Sha256", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Date")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Date", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Credential")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Credential", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Security-Token")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Security-Token", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Algorithm")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Algorithm", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-SignedHeaders", valid_602420
  result.add "header", section
  ## parameters in `formData` object:
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AlarmNames` field"
  var valid_602421 = formData.getOrDefault("AlarmNames")
  valid_602421 = validateParameter(valid_602421, JArray, required = true, default = nil)
  if valid_602421 != nil:
    section.add "AlarmNames", valid_602421
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602422: Call_PostEnableAlarmActions_602409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_602422.validator(path, query, header, formData, body)
  let scheme = call_602422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602422.url(scheme.get, call_602422.host, call_602422.base,
                         call_602422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602422, url, valid)

proc call*(call_602423: Call_PostEnableAlarmActions_602409; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## postEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  var query_602424 = newJObject()
  var formData_602425 = newJObject()
  add(query_602424, "Action", newJString(Action))
  add(query_602424, "Version", newJString(Version))
  if AlarmNames != nil:
    formData_602425.add "AlarmNames", AlarmNames
  result = call_602423.call(nil, query_602424, nil, formData_602425, nil)

var postEnableAlarmActions* = Call_PostEnableAlarmActions_602409(
    name: "postEnableAlarmActions", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_PostEnableAlarmActions_602410, base: "/",
    url: url_PostEnableAlarmActions_602411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAlarmActions_602393 = ref object of OpenApiRestCall_601389
proc url_GetEnableAlarmActions_602395(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnableAlarmActions_602394(path: JsonNode; query: JsonNode;
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
  var valid_602396 = query.getOrDefault("AlarmNames")
  valid_602396 = validateParameter(valid_602396, JArray, required = true, default = nil)
  if valid_602396 != nil:
    section.add "AlarmNames", valid_602396
  var valid_602397 = query.getOrDefault("Action")
  valid_602397 = validateParameter(valid_602397, JString, required = true,
                                 default = newJString("EnableAlarmActions"))
  if valid_602397 != nil:
    section.add "Action", valid_602397
  var valid_602398 = query.getOrDefault("Version")
  valid_602398 = validateParameter(valid_602398, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602398 != nil:
    section.add "Version", valid_602398
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602399 = header.getOrDefault("X-Amz-Signature")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Signature", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Content-Sha256", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Date")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Date", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Credential")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Credential", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Security-Token")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Security-Token", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Algorithm")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Algorithm", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-SignedHeaders", valid_602405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602406: Call_GetEnableAlarmActions_602393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the actions for the specified alarms.
  ## 
  let valid = call_602406.validator(path, query, header, formData, body)
  let scheme = call_602406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602406.url(scheme.get, call_602406.host, call_602406.base,
                         call_602406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602406, url, valid)

proc call*(call_602407: Call_GetEnableAlarmActions_602393; AlarmNames: JsonNode;
          Action: string = "EnableAlarmActions"; Version: string = "2010-08-01"): Recallable =
  ## getEnableAlarmActions
  ## Enables the actions for the specified alarms.
  ##   AlarmNames: JArray (required)
  ##             : The names of the alarms.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602408 = newJObject()
  if AlarmNames != nil:
    query_602408.add "AlarmNames", AlarmNames
  add(query_602408, "Action", newJString(Action))
  add(query_602408, "Version", newJString(Version))
  result = call_602407.call(nil, query_602408, nil, nil, nil)

var getEnableAlarmActions* = Call_GetEnableAlarmActions_602393(
    name: "getEnableAlarmActions", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableAlarmActions",
    validator: validate_GetEnableAlarmActions_602394, base: "/",
    url: url_GetEnableAlarmActions_602395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableInsightRules_602442 = ref object of OpenApiRestCall_601389
proc url_PostEnableInsightRules_602444(protocol: Scheme; host: string; base: string;
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

proc validate_PostEnableInsightRules_602443(path: JsonNode; query: JsonNode;
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
  var valid_602445 = query.getOrDefault("Action")
  valid_602445 = validateParameter(valid_602445, JString, required = true,
                                 default = newJString("EnableInsightRules"))
  if valid_602445 != nil:
    section.add "Action", valid_602445
  var valid_602446 = query.getOrDefault("Version")
  valid_602446 = validateParameter(valid_602446, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602446 != nil:
    section.add "Version", valid_602446
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602447 = header.getOrDefault("X-Amz-Signature")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Signature", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Content-Sha256", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Date")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Date", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Credential")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Credential", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Security-Token")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Security-Token", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Algorithm")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Algorithm", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-SignedHeaders", valid_602453
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleNames` field"
  var valid_602454 = formData.getOrDefault("RuleNames")
  valid_602454 = validateParameter(valid_602454, JArray, required = true, default = nil)
  if valid_602454 != nil:
    section.add "RuleNames", valid_602454
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602455: Call_PostEnableInsightRules_602442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_602455.validator(path, query, header, formData, body)
  let scheme = call_602455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602455.url(scheme.get, call_602455.host, call_602455.base,
                         call_602455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602455, url, valid)

proc call*(call_602456: Call_PostEnableInsightRules_602442; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## postEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602457 = newJObject()
  var formData_602458 = newJObject()
  if RuleNames != nil:
    formData_602458.add "RuleNames", RuleNames
  add(query_602457, "Action", newJString(Action))
  add(query_602457, "Version", newJString(Version))
  result = call_602456.call(nil, query_602457, nil, formData_602458, nil)

var postEnableInsightRules* = Call_PostEnableInsightRules_602442(
    name: "postEnableInsightRules", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_PostEnableInsightRules_602443, base: "/",
    url: url_PostEnableInsightRules_602444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableInsightRules_602426 = ref object of OpenApiRestCall_601389
proc url_GetEnableInsightRules_602428(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnableInsightRules_602427(path: JsonNode; query: JsonNode;
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
  var valid_602429 = query.getOrDefault("Action")
  valid_602429 = validateParameter(valid_602429, JString, required = true,
                                 default = newJString("EnableInsightRules"))
  if valid_602429 != nil:
    section.add "Action", valid_602429
  var valid_602430 = query.getOrDefault("RuleNames")
  valid_602430 = validateParameter(valid_602430, JArray, required = true, default = nil)
  if valid_602430 != nil:
    section.add "RuleNames", valid_602430
  var valid_602431 = query.getOrDefault("Version")
  valid_602431 = validateParameter(valid_602431, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602431 != nil:
    section.add "Version", valid_602431
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602432 = header.getOrDefault("X-Amz-Signature")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Signature", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Content-Sha256", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Date")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Date", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Credential")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Credential", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Security-Token")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Security-Token", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Algorithm")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Algorithm", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-SignedHeaders", valid_602438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602439: Call_GetEnableInsightRules_602426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ## 
  let valid = call_602439.validator(path, query, header, formData, body)
  let scheme = call_602439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602439.url(scheme.get, call_602439.host, call_602439.base,
                         call_602439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602439, url, valid)

proc call*(call_602440: Call_GetEnableInsightRules_602426; RuleNames: JsonNode;
          Action: string = "EnableInsightRules"; Version: string = "2010-08-01"): Recallable =
  ## getEnableInsightRules
  ## Enables the specified Contributor Insights rules. When rules are enabled, they immediately begin analyzing log data.
  ##   Action: string (required)
  ##   RuleNames: JArray (required)
  ##            : An array of the rule names to enable. If you need to find out the names of your rules, use <a>DescribeInsightRules</a>.
  ##   Version: string (required)
  var query_602441 = newJObject()
  add(query_602441, "Action", newJString(Action))
  if RuleNames != nil:
    query_602441.add "RuleNames", RuleNames
  add(query_602441, "Version", newJString(Version))
  result = call_602440.call(nil, query_602441, nil, nil, nil)

var getEnableInsightRules* = Call_GetEnableInsightRules_602426(
    name: "getEnableInsightRules", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=EnableInsightRules",
    validator: validate_GetEnableInsightRules_602427, base: "/",
    url: url_GetEnableInsightRules_602428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetDashboard_602475 = ref object of OpenApiRestCall_601389
proc url_PostGetDashboard_602477(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetDashboard_602476(path: JsonNode; query: JsonNode;
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
  var valid_602478 = query.getOrDefault("Action")
  valid_602478 = validateParameter(valid_602478, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_602478 != nil:
    section.add "Action", valid_602478
  var valid_602479 = query.getOrDefault("Version")
  valid_602479 = validateParameter(valid_602479, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602479 != nil:
    section.add "Version", valid_602479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602480 = header.getOrDefault("X-Amz-Signature")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Signature", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Content-Sha256", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Date")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Date", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Credential")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Credential", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Security-Token")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Security-Token", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Algorithm")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Algorithm", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-SignedHeaders", valid_602486
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard to be described.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_602487 = formData.getOrDefault("DashboardName")
  valid_602487 = validateParameter(valid_602487, JString, required = true,
                                 default = nil)
  if valid_602487 != nil:
    section.add "DashboardName", valid_602487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602488: Call_PostGetDashboard_602475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_602488.validator(path, query, header, formData, body)
  let scheme = call_602488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602488.url(scheme.get, call_602488.host, call_602488.base,
                         call_602488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602488, url, valid)

proc call*(call_602489: Call_PostGetDashboard_602475; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## postGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602490 = newJObject()
  var formData_602491 = newJObject()
  add(formData_602491, "DashboardName", newJString(DashboardName))
  add(query_602490, "Action", newJString(Action))
  add(query_602490, "Version", newJString(Version))
  result = call_602489.call(nil, query_602490, nil, formData_602491, nil)

var postGetDashboard* = Call_PostGetDashboard_602475(name: "postGetDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_PostGetDashboard_602476,
    base: "/", url: url_PostGetDashboard_602477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetDashboard_602459 = ref object of OpenApiRestCall_601389
proc url_GetGetDashboard_602461(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetDashboard_602460(path: JsonNode; query: JsonNode;
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
  var valid_602462 = query.getOrDefault("Action")
  valid_602462 = validateParameter(valid_602462, JString, required = true,
                                 default = newJString("GetDashboard"))
  if valid_602462 != nil:
    section.add "Action", valid_602462
  var valid_602463 = query.getOrDefault("DashboardName")
  valid_602463 = validateParameter(valid_602463, JString, required = true,
                                 default = nil)
  if valid_602463 != nil:
    section.add "DashboardName", valid_602463
  var valid_602464 = query.getOrDefault("Version")
  valid_602464 = validateParameter(valid_602464, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602464 != nil:
    section.add "Version", valid_602464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602465 = header.getOrDefault("X-Amz-Signature")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Signature", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Content-Sha256", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Date")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Date", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Credential")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Credential", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Security-Token")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Security-Token", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Algorithm")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Algorithm", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-SignedHeaders", valid_602471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602472: Call_GetGetDashboard_602459; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ## 
  let valid = call_602472.validator(path, query, header, formData, body)
  let scheme = call_602472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602472.url(scheme.get, call_602472.host, call_602472.base,
                         call_602472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602472, url, valid)

proc call*(call_602473: Call_GetGetDashboard_602459; DashboardName: string;
          Action: string = "GetDashboard"; Version: string = "2010-08-01"): Recallable =
  ## getGetDashboard
  ## <p>Displays the details of the dashboard that you specify.</p> <p>To copy an existing dashboard, use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code> to create the copy.</p>
  ##   Action: string (required)
  ##   DashboardName: string (required)
  ##                : The name of the dashboard to be described.
  ##   Version: string (required)
  var query_602474 = newJObject()
  add(query_602474, "Action", newJString(Action))
  add(query_602474, "DashboardName", newJString(DashboardName))
  add(query_602474, "Version", newJString(Version))
  result = call_602473.call(nil, query_602474, nil, nil, nil)

var getGetDashboard* = Call_GetGetDashboard_602459(name: "getGetDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetDashboard", validator: validate_GetGetDashboard_602460,
    base: "/", url: url_GetGetDashboard_602461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetInsightRuleReport_602514 = ref object of OpenApiRestCall_601389
proc url_PostGetInsightRuleReport_602516(protocol: Scheme; host: string;
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

proc validate_PostGetInsightRuleReport_602515(path: JsonNode; query: JsonNode;
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
  var valid_602517 = query.getOrDefault("Action")
  valid_602517 = validateParameter(valid_602517, JString, required = true,
                                 default = newJString("GetInsightRuleReport"))
  if valid_602517 != nil:
    section.add "Action", valid_602517
  var valid_602518 = query.getOrDefault("Version")
  valid_602518 = validateParameter(valid_602518, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602518 != nil:
    section.add "Version", valid_602518
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602519 = header.getOrDefault("X-Amz-Signature")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Signature", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Content-Sha256", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Date")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Date", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Credential")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Credential", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Security-Token")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Security-Token", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Algorithm")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Algorithm", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-SignedHeaders", valid_602525
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
  var valid_602526 = formData.getOrDefault("RuleName")
  valid_602526 = validateParameter(valid_602526, JString, required = true,
                                 default = nil)
  if valid_602526 != nil:
    section.add "RuleName", valid_602526
  var valid_602527 = formData.getOrDefault("Period")
  valid_602527 = validateParameter(valid_602527, JInt, required = true, default = nil)
  if valid_602527 != nil:
    section.add "Period", valid_602527
  var valid_602528 = formData.getOrDefault("OrderBy")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "OrderBy", valid_602528
  var valid_602529 = formData.getOrDefault("EndTime")
  valid_602529 = validateParameter(valid_602529, JString, required = true,
                                 default = nil)
  if valid_602529 != nil:
    section.add "EndTime", valid_602529
  var valid_602530 = formData.getOrDefault("StartTime")
  valid_602530 = validateParameter(valid_602530, JString, required = true,
                                 default = nil)
  if valid_602530 != nil:
    section.add "StartTime", valid_602530
  var valid_602531 = formData.getOrDefault("MaxContributorCount")
  valid_602531 = validateParameter(valid_602531, JInt, required = false, default = nil)
  if valid_602531 != nil:
    section.add "MaxContributorCount", valid_602531
  var valid_602532 = formData.getOrDefault("Metrics")
  valid_602532 = validateParameter(valid_602532, JArray, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "Metrics", valid_602532
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602533: Call_PostGetInsightRuleReport_602514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_602533.validator(path, query, header, formData, body)
  let scheme = call_602533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602533.url(scheme.get, call_602533.host, call_602533.base,
                         call_602533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602533, url, valid)

proc call*(call_602534: Call_PostGetInsightRuleReport_602514; RuleName: string;
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
  var query_602535 = newJObject()
  var formData_602536 = newJObject()
  add(formData_602536, "RuleName", newJString(RuleName))
  add(formData_602536, "Period", newJInt(Period))
  add(formData_602536, "OrderBy", newJString(OrderBy))
  add(formData_602536, "EndTime", newJString(EndTime))
  add(formData_602536, "StartTime", newJString(StartTime))
  add(query_602535, "Action", newJString(Action))
  add(query_602535, "Version", newJString(Version))
  add(formData_602536, "MaxContributorCount", newJInt(MaxContributorCount))
  if Metrics != nil:
    formData_602536.add "Metrics", Metrics
  result = call_602534.call(nil, query_602535, nil, formData_602536, nil)

var postGetInsightRuleReport* = Call_PostGetInsightRuleReport_602514(
    name: "postGetInsightRuleReport", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_PostGetInsightRuleReport_602515, base: "/",
    url: url_PostGetInsightRuleReport_602516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetInsightRuleReport_602492 = ref object of OpenApiRestCall_601389
proc url_GetGetInsightRuleReport_602494(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetInsightRuleReport_602493(path: JsonNode; query: JsonNode;
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
  var valid_602495 = query.getOrDefault("RuleName")
  valid_602495 = validateParameter(valid_602495, JString, required = true,
                                 default = nil)
  if valid_602495 != nil:
    section.add "RuleName", valid_602495
  var valid_602496 = query.getOrDefault("MaxContributorCount")
  valid_602496 = validateParameter(valid_602496, JInt, required = false, default = nil)
  if valid_602496 != nil:
    section.add "MaxContributorCount", valid_602496
  var valid_602497 = query.getOrDefault("OrderBy")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "OrderBy", valid_602497
  var valid_602498 = query.getOrDefault("Period")
  valid_602498 = validateParameter(valid_602498, JInt, required = true, default = nil)
  if valid_602498 != nil:
    section.add "Period", valid_602498
  var valid_602499 = query.getOrDefault("Action")
  valid_602499 = validateParameter(valid_602499, JString, required = true,
                                 default = newJString("GetInsightRuleReport"))
  if valid_602499 != nil:
    section.add "Action", valid_602499
  var valid_602500 = query.getOrDefault("StartTime")
  valid_602500 = validateParameter(valid_602500, JString, required = true,
                                 default = nil)
  if valid_602500 != nil:
    section.add "StartTime", valid_602500
  var valid_602501 = query.getOrDefault("EndTime")
  valid_602501 = validateParameter(valid_602501, JString, required = true,
                                 default = nil)
  if valid_602501 != nil:
    section.add "EndTime", valid_602501
  var valid_602502 = query.getOrDefault("Metrics")
  valid_602502 = validateParameter(valid_602502, JArray, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "Metrics", valid_602502
  var valid_602503 = query.getOrDefault("Version")
  valid_602503 = validateParameter(valid_602503, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602503 != nil:
    section.add "Version", valid_602503
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602504 = header.getOrDefault("X-Amz-Signature")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Signature", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Content-Sha256", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Date")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Date", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Credential")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Credential", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Security-Token")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Security-Token", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Algorithm")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Algorithm", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-SignedHeaders", valid_602510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602511: Call_GetGetInsightRuleReport_602492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns the time series data collected by a Contributor Insights rule. The data includes the identity and number of contributors to the log group.</p> <p>You can also optionally return one or more statistics about each data point in the time series. These statistics can include the following:</p> <ul> <li> <p> <code>UniqueContributors</code> -- the number of unique contributors for each data point.</p> </li> <li> <p> <code>MaxContributorValue</code> -- the value of the top contributor for each data point. The identity of the contributor may change for each data point in the graph.</p> <p>If this rule aggregates by COUNT, the top contributor for each data point is the contributor with the most occurrences in that period. If the rule aggregates by SUM, the top contributor is the contributor with the highest sum in the log field specified by the rule's <code>Value</code>, during that period.</p> </li> <li> <p> <code>SampleCount</code> -- the number of data points matched by the rule.</p> </li> <li> <p> <code>Sum</code> -- the sum of the values from all contributors during the time period represented by that data point.</p> </li> <li> <p> <code>Minimum</code> -- the minimum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Maximum</code> -- the maximum value from a single observation during the time period represented by that data point.</p> </li> <li> <p> <code>Average</code> -- the average value from all contributors during the time period represented by that data point.</p> </li> </ul>
  ## 
  let valid = call_602511.validator(path, query, header, formData, body)
  let scheme = call_602511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602511.url(scheme.get, call_602511.host, call_602511.base,
                         call_602511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602511, url, valid)

proc call*(call_602512: Call_GetGetInsightRuleReport_602492; RuleName: string;
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
  var query_602513 = newJObject()
  add(query_602513, "RuleName", newJString(RuleName))
  add(query_602513, "MaxContributorCount", newJInt(MaxContributorCount))
  add(query_602513, "OrderBy", newJString(OrderBy))
  add(query_602513, "Period", newJInt(Period))
  add(query_602513, "Action", newJString(Action))
  add(query_602513, "StartTime", newJString(StartTime))
  add(query_602513, "EndTime", newJString(EndTime))
  if Metrics != nil:
    query_602513.add "Metrics", Metrics
  add(query_602513, "Version", newJString(Version))
  result = call_602512.call(nil, query_602513, nil, nil, nil)

var getGetInsightRuleReport* = Call_GetGetInsightRuleReport_602492(
    name: "getGetInsightRuleReport", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetInsightRuleReport",
    validator: validate_GetGetInsightRuleReport_602493, base: "/",
    url: url_GetGetInsightRuleReport_602494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricData_602558 = ref object of OpenApiRestCall_601389
proc url_PostGetMetricData_602560(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetMetricData_602559(path: JsonNode; query: JsonNode;
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
  var valid_602561 = query.getOrDefault("Action")
  valid_602561 = validateParameter(valid_602561, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_602561 != nil:
    section.add "Action", valid_602561
  var valid_602562 = query.getOrDefault("Version")
  valid_602562 = validateParameter(valid_602562, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602562 != nil:
    section.add "Version", valid_602562
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602563 = header.getOrDefault("X-Amz-Signature")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Signature", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Content-Sha256", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Date")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Date", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Credential")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Credential", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Security-Token")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Security-Token", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-Algorithm")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-Algorithm", valid_602568
  var valid_602569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "X-Amz-SignedHeaders", valid_602569
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
  var valid_602570 = formData.getOrDefault("NextToken")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "NextToken", valid_602570
  var valid_602571 = formData.getOrDefault("ScanBy")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_602571 != nil:
    section.add "ScanBy", valid_602571
  assert formData != nil,
        "formData argument is necessary due to required `EndTime` field"
  var valid_602572 = formData.getOrDefault("EndTime")
  valid_602572 = validateParameter(valid_602572, JString, required = true,
                                 default = nil)
  if valid_602572 != nil:
    section.add "EndTime", valid_602572
  var valid_602573 = formData.getOrDefault("StartTime")
  valid_602573 = validateParameter(valid_602573, JString, required = true,
                                 default = nil)
  if valid_602573 != nil:
    section.add "StartTime", valid_602573
  var valid_602574 = formData.getOrDefault("MetricDataQueries")
  valid_602574 = validateParameter(valid_602574, JArray, required = true, default = nil)
  if valid_602574 != nil:
    section.add "MetricDataQueries", valid_602574
  var valid_602575 = formData.getOrDefault("MaxDatapoints")
  valid_602575 = validateParameter(valid_602575, JInt, required = false, default = nil)
  if valid_602575 != nil:
    section.add "MaxDatapoints", valid_602575
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602576: Call_PostGetMetricData_602558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_602576.validator(path, query, header, formData, body)
  let scheme = call_602576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602576.url(scheme.get, call_602576.host, call_602576.base,
                         call_602576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602576, url, valid)

proc call*(call_602577: Call_PostGetMetricData_602558; EndTime: string;
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
  var query_602578 = newJObject()
  var formData_602579 = newJObject()
  add(formData_602579, "NextToken", newJString(NextToken))
  add(formData_602579, "ScanBy", newJString(ScanBy))
  add(formData_602579, "EndTime", newJString(EndTime))
  add(formData_602579, "StartTime", newJString(StartTime))
  add(query_602578, "Action", newJString(Action))
  add(query_602578, "Version", newJString(Version))
  if MetricDataQueries != nil:
    formData_602579.add "MetricDataQueries", MetricDataQueries
  add(formData_602579, "MaxDatapoints", newJInt(MaxDatapoints))
  result = call_602577.call(nil, query_602578, nil, formData_602579, nil)

var postGetMetricData* = Call_PostGetMetricData_602558(name: "postGetMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_PostGetMetricData_602559,
    base: "/", url: url_PostGetMetricData_602560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricData_602537 = ref object of OpenApiRestCall_601389
proc url_GetGetMetricData_602539(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricData_602538(path: JsonNode; query: JsonNode;
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
  var valid_602540 = query.getOrDefault("NextToken")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "NextToken", valid_602540
  var valid_602541 = query.getOrDefault("MaxDatapoints")
  valid_602541 = validateParameter(valid_602541, JInt, required = false, default = nil)
  if valid_602541 != nil:
    section.add "MaxDatapoints", valid_602541
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602542 = query.getOrDefault("Action")
  valid_602542 = validateParameter(valid_602542, JString, required = true,
                                 default = newJString("GetMetricData"))
  if valid_602542 != nil:
    section.add "Action", valid_602542
  var valid_602543 = query.getOrDefault("StartTime")
  valid_602543 = validateParameter(valid_602543, JString, required = true,
                                 default = nil)
  if valid_602543 != nil:
    section.add "StartTime", valid_602543
  var valid_602544 = query.getOrDefault("EndTime")
  valid_602544 = validateParameter(valid_602544, JString, required = true,
                                 default = nil)
  if valid_602544 != nil:
    section.add "EndTime", valid_602544
  var valid_602545 = query.getOrDefault("Version")
  valid_602545 = validateParameter(valid_602545, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602545 != nil:
    section.add "Version", valid_602545
  var valid_602546 = query.getOrDefault("MetricDataQueries")
  valid_602546 = validateParameter(valid_602546, JArray, required = true, default = nil)
  if valid_602546 != nil:
    section.add "MetricDataQueries", valid_602546
  var valid_602547 = query.getOrDefault("ScanBy")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = newJString("TimestampDescending"))
  if valid_602547 != nil:
    section.add "ScanBy", valid_602547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602548 = header.getOrDefault("X-Amz-Signature")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Signature", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Content-Sha256", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Date")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Date", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Credential")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Credential", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Security-Token")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Security-Token", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-Algorithm")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Algorithm", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-SignedHeaders", valid_602554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602555: Call_GetGetMetricData_602537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricData</code> API to retrieve as many as 100 different metrics in a single request, with a total of as many as 100,800 data points. You can also optionally perform math expressions on the values of the returned statistics, to create new time series that represent new insights into your data. For example, using Lambda metrics, you could divide the Errors metric by the Invocations metric to get an error rate time series. For more information about metric math expressions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax">Metric Math Syntax and Functions</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Calls to the <code>GetMetricData</code> API have a different pricing structure than calls to <code>GetMetricStatistics</code>. For more information about pricing, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>If you omit <code>Unit</code> in your request, all data that was collected with any unit is returned, along with the corresponding units that were specified when the data was reported to CloudWatch. If you specify a unit, the operation returns only data data that was collected with that unit specified. If you specify a unit that does not match the data collected, the results of the operation are null. CloudWatch does not perform unit conversions.</p>
  ## 
  let valid = call_602555.validator(path, query, header, formData, body)
  let scheme = call_602555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602555.url(scheme.get, call_602555.host, call_602555.base,
                         call_602555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602555, url, valid)

proc call*(call_602556: Call_GetGetMetricData_602537; StartTime: string;
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
  var query_602557 = newJObject()
  add(query_602557, "NextToken", newJString(NextToken))
  add(query_602557, "MaxDatapoints", newJInt(MaxDatapoints))
  add(query_602557, "Action", newJString(Action))
  add(query_602557, "StartTime", newJString(StartTime))
  add(query_602557, "EndTime", newJString(EndTime))
  add(query_602557, "Version", newJString(Version))
  if MetricDataQueries != nil:
    query_602557.add "MetricDataQueries", MetricDataQueries
  add(query_602557, "ScanBy", newJString(ScanBy))
  result = call_602556.call(nil, query_602557, nil, nil, nil)

var getGetMetricData* = Call_GetGetMetricData_602537(name: "getGetMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=GetMetricData", validator: validate_GetGetMetricData_602538,
    base: "/", url: url_GetGetMetricData_602539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricStatistics_602604 = ref object of OpenApiRestCall_601389
proc url_PostGetMetricStatistics_602606(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetMetricStatistics_602605(path: JsonNode; query: JsonNode;
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
  var valid_602607 = query.getOrDefault("Action")
  valid_602607 = validateParameter(valid_602607, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_602607 != nil:
    section.add "Action", valid_602607
  var valid_602608 = query.getOrDefault("Version")
  valid_602608 = validateParameter(valid_602608, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602608 != nil:
    section.add "Version", valid_602608
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602609 = header.getOrDefault("X-Amz-Signature")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Signature", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Content-Sha256", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Date")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Date", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Credential")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Credential", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Security-Token")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Security-Token", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Algorithm")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Algorithm", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-SignedHeaders", valid_602615
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
  var valid_602616 = formData.getOrDefault("Unit")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_602616 != nil:
    section.add "Unit", valid_602616
  assert formData != nil,
        "formData argument is necessary due to required `Period` field"
  var valid_602617 = formData.getOrDefault("Period")
  valid_602617 = validateParameter(valid_602617, JInt, required = true, default = nil)
  if valid_602617 != nil:
    section.add "Period", valid_602617
  var valid_602618 = formData.getOrDefault("Statistics")
  valid_602618 = validateParameter(valid_602618, JArray, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "Statistics", valid_602618
  var valid_602619 = formData.getOrDefault("ExtendedStatistics")
  valid_602619 = validateParameter(valid_602619, JArray, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "ExtendedStatistics", valid_602619
  var valid_602620 = formData.getOrDefault("EndTime")
  valid_602620 = validateParameter(valid_602620, JString, required = true,
                                 default = nil)
  if valid_602620 != nil:
    section.add "EndTime", valid_602620
  var valid_602621 = formData.getOrDefault("StartTime")
  valid_602621 = validateParameter(valid_602621, JString, required = true,
                                 default = nil)
  if valid_602621 != nil:
    section.add "StartTime", valid_602621
  var valid_602622 = formData.getOrDefault("MetricName")
  valid_602622 = validateParameter(valid_602622, JString, required = true,
                                 default = nil)
  if valid_602622 != nil:
    section.add "MetricName", valid_602622
  var valid_602623 = formData.getOrDefault("Dimensions")
  valid_602623 = validateParameter(valid_602623, JArray, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "Dimensions", valid_602623
  var valid_602624 = formData.getOrDefault("Namespace")
  valid_602624 = validateParameter(valid_602624, JString, required = true,
                                 default = nil)
  if valid_602624 != nil:
    section.add "Namespace", valid_602624
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602625: Call_PostGetMetricStatistics_602604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_602625.validator(path, query, header, formData, body)
  let scheme = call_602625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602625.url(scheme.get, call_602625.host, call_602625.base,
                         call_602625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602625, url, valid)

proc call*(call_602626: Call_PostGetMetricStatistics_602604; Period: int;
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
  var query_602627 = newJObject()
  var formData_602628 = newJObject()
  add(formData_602628, "Unit", newJString(Unit))
  add(formData_602628, "Period", newJInt(Period))
  if Statistics != nil:
    formData_602628.add "Statistics", Statistics
  if ExtendedStatistics != nil:
    formData_602628.add "ExtendedStatistics", ExtendedStatistics
  add(formData_602628, "EndTime", newJString(EndTime))
  add(formData_602628, "StartTime", newJString(StartTime))
  add(formData_602628, "MetricName", newJString(MetricName))
  add(query_602627, "Action", newJString(Action))
  if Dimensions != nil:
    formData_602628.add "Dimensions", Dimensions
  add(formData_602628, "Namespace", newJString(Namespace))
  add(query_602627, "Version", newJString(Version))
  result = call_602626.call(nil, query_602627, nil, formData_602628, nil)

var postGetMetricStatistics* = Call_PostGetMetricStatistics_602604(
    name: "postGetMetricStatistics", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_PostGetMetricStatistics_602605, base: "/",
    url: url_PostGetMetricStatistics_602606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricStatistics_602580 = ref object of OpenApiRestCall_601389
proc url_GetGetMetricStatistics_602582(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricStatistics_602581(path: JsonNode; query: JsonNode;
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
  var valid_602583 = query.getOrDefault("Unit")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_602583 != nil:
    section.add "Unit", valid_602583
  var valid_602584 = query.getOrDefault("ExtendedStatistics")
  valid_602584 = validateParameter(valid_602584, JArray, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "ExtendedStatistics", valid_602584
  assert query != nil,
        "query argument is necessary due to required `Namespace` field"
  var valid_602585 = query.getOrDefault("Namespace")
  valid_602585 = validateParameter(valid_602585, JString, required = true,
                                 default = nil)
  if valid_602585 != nil:
    section.add "Namespace", valid_602585
  var valid_602586 = query.getOrDefault("Statistics")
  valid_602586 = validateParameter(valid_602586, JArray, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "Statistics", valid_602586
  var valid_602587 = query.getOrDefault("Period")
  valid_602587 = validateParameter(valid_602587, JInt, required = true, default = nil)
  if valid_602587 != nil:
    section.add "Period", valid_602587
  var valid_602588 = query.getOrDefault("Dimensions")
  valid_602588 = validateParameter(valid_602588, JArray, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "Dimensions", valid_602588
  var valid_602589 = query.getOrDefault("Action")
  valid_602589 = validateParameter(valid_602589, JString, required = true,
                                 default = newJString("GetMetricStatistics"))
  if valid_602589 != nil:
    section.add "Action", valid_602589
  var valid_602590 = query.getOrDefault("StartTime")
  valid_602590 = validateParameter(valid_602590, JString, required = true,
                                 default = nil)
  if valid_602590 != nil:
    section.add "StartTime", valid_602590
  var valid_602591 = query.getOrDefault("EndTime")
  valid_602591 = validateParameter(valid_602591, JString, required = true,
                                 default = nil)
  if valid_602591 != nil:
    section.add "EndTime", valid_602591
  var valid_602592 = query.getOrDefault("Version")
  valid_602592 = validateParameter(valid_602592, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602592 != nil:
    section.add "Version", valid_602592
  var valid_602593 = query.getOrDefault("MetricName")
  valid_602593 = validateParameter(valid_602593, JString, required = true,
                                 default = nil)
  if valid_602593 != nil:
    section.add "MetricName", valid_602593
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602594 = header.getOrDefault("X-Amz-Signature")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Signature", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Content-Sha256", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Date")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Date", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Credential")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Credential", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Security-Token")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Security-Token", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Algorithm")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Algorithm", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-SignedHeaders", valid_602600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602601: Call_GetGetMetricStatistics_602580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets statistics for the specified metric.</p> <p>The maximum number of data points returned from a single call is 1,440. If you request more than 1,440 data points, CloudWatch returns an error. To reduce the number of data points, you can narrow the specified time range and make multiple requests across adjacent time ranges, or you can increase the specified period. Data points are not returned in chronological order.</p> <p>CloudWatch aggregates data points based on the length of the period that you specify. For example, if you request statistics with a one-hour period, CloudWatch aggregates all data points with time stamps that fall within each one-hour period. Therefore, the number of values aggregated by CloudWatch is larger than the number of data points returned.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The SampleCount value of the statistic set is 1.</p> </li> <li> <p>The Min and the Max values of the statistic set are equal.</p> </li> </ul> <p>Percentile statistics are not available for metrics when any of the metric values are negative numbers.</p> <p>Amazon CloudWatch retains metric data as follows:</p> <ul> <li> <p>Data points with a period of less than 60 seconds are available for 3 hours. These data points are high-resolution metrics and are available only for custom metrics that have been defined with a <code>StorageResolution</code> of 1.</p> </li> <li> <p>Data points with a period of 60 seconds (1-minute) are available for 15 days.</p> </li> <li> <p>Data points with a period of 300 seconds (5-minute) are available for 63 days.</p> </li> <li> <p>Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).</p> </li> </ul> <p>Data points that are initially published with a shorter period are aggregated together for long-term storage. For example, if you collect data using a period of 1 minute, the data remains available for 15 days with 1-minute resolution. After 15 days, this data is still available, but is aggregated and retrievable only with a resolution of 5 minutes. After 63 days, the data is further aggregated and is available with a resolution of 1 hour.</p> <p>CloudWatch started retaining 5-minute and 1-hour metric data as of July 9, 2016.</p> <p>For information about metrics and dimensions supported by AWS services, see the <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html">Amazon CloudWatch Metrics and Dimensions Reference</a> in the <i>Amazon CloudWatch User Guide</i>.</p>
  ## 
  let valid = call_602601.validator(path, query, header, formData, body)
  let scheme = call_602601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602601.url(scheme.get, call_602601.host, call_602601.base,
                         call_602601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602601, url, valid)

proc call*(call_602602: Call_GetGetMetricStatistics_602580; Namespace: string;
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
  var query_602603 = newJObject()
  add(query_602603, "Unit", newJString(Unit))
  if ExtendedStatistics != nil:
    query_602603.add "ExtendedStatistics", ExtendedStatistics
  add(query_602603, "Namespace", newJString(Namespace))
  if Statistics != nil:
    query_602603.add "Statistics", Statistics
  add(query_602603, "Period", newJInt(Period))
  if Dimensions != nil:
    query_602603.add "Dimensions", Dimensions
  add(query_602603, "Action", newJString(Action))
  add(query_602603, "StartTime", newJString(StartTime))
  add(query_602603, "EndTime", newJString(EndTime))
  add(query_602603, "Version", newJString(Version))
  add(query_602603, "MetricName", newJString(MetricName))
  result = call_602602.call(nil, query_602603, nil, nil, nil)

var getGetMetricStatistics* = Call_GetGetMetricStatistics_602580(
    name: "getGetMetricStatistics", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricStatistics",
    validator: validate_GetGetMetricStatistics_602581, base: "/",
    url: url_GetGetMetricStatistics_602582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetMetricWidgetImage_602646 = ref object of OpenApiRestCall_601389
proc url_PostGetMetricWidgetImage_602648(protocol: Scheme; host: string;
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

proc validate_PostGetMetricWidgetImage_602647(path: JsonNode; query: JsonNode;
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
  var valid_602649 = query.getOrDefault("Action")
  valid_602649 = validateParameter(valid_602649, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_602649 != nil:
    section.add "Action", valid_602649
  var valid_602650 = query.getOrDefault("Version")
  valid_602650 = validateParameter(valid_602650, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602650 != nil:
    section.add "Version", valid_602650
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602651 = header.getOrDefault("X-Amz-Signature")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-Signature", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Content-Sha256", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-Date")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-Date", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-Credential")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Credential", valid_602654
  var valid_602655 = header.getOrDefault("X-Amz-Security-Token")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-Security-Token", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Algorithm")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Algorithm", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-SignedHeaders", valid_602657
  result.add "header", section
  ## parameters in `formData` object:
  ##   MetricWidget: JString (required)
  ##               : <p>A JSON string that defines the bitmap graph to be retrieved. The string includes the metrics to include in the graph, statistics, annotations, title, axis limits, and so on. You can include only one <code>MetricWidget</code> parameter in each <code>GetMetricWidgetImage</code> call.</p> <p>For more information about the syntax of <code>MetricWidget</code> see <a>CloudWatch-Metric-Widget-Structure</a>.</p> <p>If any metric on the graph could not load all the requested data points, an orange triangle with an exclamation point appears next to the graph legend.</p>
  ##   OutputFormat: JString
  ##               : <p>The format of the resulting image. Only PNG images are supported.</p> <p>The default is <code>png</code>. If you specify <code>png</code>, the API returns an HTTP response with the content-type set to <code>text/xml</code>. The image data is in a <code>MetricWidgetImage</code> field. For example:</p> <p> <code> &lt;GetMetricWidgetImageResponse xmlns=&lt;URLstring&gt;&gt;</code> </p> <p> <code> &lt;GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;MetricWidgetImage&gt;</code> </p> <p> <code> iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQEAYAAAAip...</code> </p> <p> <code> &lt;/MetricWidgetImage&gt;</code> </p> <p> <code> &lt;/GetMetricWidgetImageResult&gt;</code> </p> <p> <code> &lt;ResponseMetadata&gt;</code> </p> <p> <code> &lt;RequestId&gt;6f0d4192-4d42-11e8-82c1-f539a07e0e3b&lt;/RequestId&gt;</code> </p> <p> <code> &lt;/ResponseMetadata&gt;</code> </p> <p> <code>&lt;/GetMetricWidgetImageResponse&gt;</code> </p> <p>The <code>image/png</code> setting is intended only for custom HTTP requests. For most use cases, and all actions using an AWS SDK, you should use <code>png</code>. If you specify <code>image/png</code>, the HTTP response has a content-type set to <code>image/png</code>, and the body of the response is a PNG image. </p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MetricWidget` field"
  var valid_602658 = formData.getOrDefault("MetricWidget")
  valid_602658 = validateParameter(valid_602658, JString, required = true,
                                 default = nil)
  if valid_602658 != nil:
    section.add "MetricWidget", valid_602658
  var valid_602659 = formData.getOrDefault("OutputFormat")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "OutputFormat", valid_602659
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602660: Call_PostGetMetricWidgetImage_602646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_602660.validator(path, query, header, formData, body)
  let scheme = call_602660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602660.url(scheme.get, call_602660.host, call_602660.base,
                         call_602660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602660, url, valid)

proc call*(call_602661: Call_PostGetMetricWidgetImage_602646; MetricWidget: string;
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
  var query_602662 = newJObject()
  var formData_602663 = newJObject()
  add(formData_602663, "MetricWidget", newJString(MetricWidget))
  add(formData_602663, "OutputFormat", newJString(OutputFormat))
  add(query_602662, "Action", newJString(Action))
  add(query_602662, "Version", newJString(Version))
  result = call_602661.call(nil, query_602662, nil, formData_602663, nil)

var postGetMetricWidgetImage* = Call_PostGetMetricWidgetImage_602646(
    name: "postGetMetricWidgetImage", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_PostGetMetricWidgetImage_602647, base: "/",
    url: url_PostGetMetricWidgetImage_602648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetMetricWidgetImage_602629 = ref object of OpenApiRestCall_601389
proc url_GetGetMetricWidgetImage_602631(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetMetricWidgetImage_602630(path: JsonNode; query: JsonNode;
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
  var valid_602632 = query.getOrDefault("OutputFormat")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "OutputFormat", valid_602632
  assert query != nil,
        "query argument is necessary due to required `MetricWidget` field"
  var valid_602633 = query.getOrDefault("MetricWidget")
  valid_602633 = validateParameter(valid_602633, JString, required = true,
                                 default = nil)
  if valid_602633 != nil:
    section.add "MetricWidget", valid_602633
  var valid_602634 = query.getOrDefault("Action")
  valid_602634 = validateParameter(valid_602634, JString, required = true,
                                 default = newJString("GetMetricWidgetImage"))
  if valid_602634 != nil:
    section.add "Action", valid_602634
  var valid_602635 = query.getOrDefault("Version")
  valid_602635 = validateParameter(valid_602635, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602635 != nil:
    section.add "Version", valid_602635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602636 = header.getOrDefault("X-Amz-Signature")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-Signature", valid_602636
  var valid_602637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Content-Sha256", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-Date")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-Date", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Credential")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Credential", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Security-Token")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Security-Token", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Algorithm")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Algorithm", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-SignedHeaders", valid_602642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602643: Call_GetGetMetricWidgetImage_602629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use the <code>GetMetricWidgetImage</code> API to retrieve a snapshot graph of one or more Amazon CloudWatch metrics as a bitmap image. You can then embed this image into your services and products, such as wiki pages, reports, and documents. You could also retrieve images regularly, such as every minute, and create your own custom live dashboard.</p> <p>The graph you retrieve can include all CloudWatch metric graph features, including metric math and horizontal and vertical annotations.</p> <p>There is a limit of 20 transactions per second for this API. Each <code>GetMetricWidgetImage</code> action has the following limits:</p> <ul> <li> <p>As many as 100 metrics in the graph.</p> </li> <li> <p>Up to 100 KB uncompressed payload.</p> </li> </ul>
  ## 
  let valid = call_602643.validator(path, query, header, formData, body)
  let scheme = call_602643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602643.url(scheme.get, call_602643.host, call_602643.base,
                         call_602643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602643, url, valid)

proc call*(call_602644: Call_GetGetMetricWidgetImage_602629; MetricWidget: string;
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
  var query_602645 = newJObject()
  add(query_602645, "OutputFormat", newJString(OutputFormat))
  add(query_602645, "MetricWidget", newJString(MetricWidget))
  add(query_602645, "Action", newJString(Action))
  add(query_602645, "Version", newJString(Version))
  result = call_602644.call(nil, query_602645, nil, nil, nil)

var getGetMetricWidgetImage* = Call_GetGetMetricWidgetImage_602629(
    name: "getGetMetricWidgetImage", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=GetMetricWidgetImage",
    validator: validate_GetGetMetricWidgetImage_602630, base: "/",
    url: url_GetGetMetricWidgetImage_602631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDashboards_602681 = ref object of OpenApiRestCall_601389
proc url_PostListDashboards_602683(protocol: Scheme; host: string; base: string;
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

proc validate_PostListDashboards_602682(path: JsonNode; query: JsonNode;
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
  var valid_602684 = query.getOrDefault("Action")
  valid_602684 = validateParameter(valid_602684, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_602684 != nil:
    section.add "Action", valid_602684
  var valid_602685 = query.getOrDefault("Version")
  valid_602685 = validateParameter(valid_602685, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602685 != nil:
    section.add "Version", valid_602685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602686 = header.getOrDefault("X-Amz-Signature")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Signature", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Content-Sha256", valid_602687
  var valid_602688 = header.getOrDefault("X-Amz-Date")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Date", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-Credential")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Credential", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Security-Token")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Security-Token", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Algorithm")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Algorithm", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-SignedHeaders", valid_602692
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The token returned by a previous call to indicate that there is more data available.
  ##   DashboardNamePrefix: JString
  ##                      : If you specify this parameter, only the dashboards with names starting with the specified string are listed. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, ".", "-", and "_". 
  section = newJObject()
  var valid_602693 = formData.getOrDefault("NextToken")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "NextToken", valid_602693
  var valid_602694 = formData.getOrDefault("DashboardNamePrefix")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "DashboardNamePrefix", valid_602694
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602695: Call_PostListDashboards_602681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_602695.validator(path, query, header, formData, body)
  let scheme = call_602695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602695.url(scheme.get, call_602695.host, call_602695.base,
                         call_602695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602695, url, valid)

proc call*(call_602696: Call_PostListDashboards_602681; NextToken: string = "";
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
  var query_602697 = newJObject()
  var formData_602698 = newJObject()
  add(formData_602698, "NextToken", newJString(NextToken))
  add(formData_602698, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_602697, "Action", newJString(Action))
  add(query_602697, "Version", newJString(Version))
  result = call_602696.call(nil, query_602697, nil, formData_602698, nil)

var postListDashboards* = Call_PostListDashboards_602681(
    name: "postListDashboards", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListDashboards",
    validator: validate_PostListDashboards_602682, base: "/",
    url: url_PostListDashboards_602683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDashboards_602664 = ref object of OpenApiRestCall_601389
proc url_GetListDashboards_602666(protocol: Scheme; host: string; base: string;
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

proc validate_GetListDashboards_602665(path: JsonNode; query: JsonNode;
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
  var valid_602667 = query.getOrDefault("DashboardNamePrefix")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "DashboardNamePrefix", valid_602667
  var valid_602668 = query.getOrDefault("NextToken")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "NextToken", valid_602668
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602669 = query.getOrDefault("Action")
  valid_602669 = validateParameter(valid_602669, JString, required = true,
                                 default = newJString("ListDashboards"))
  if valid_602669 != nil:
    section.add "Action", valid_602669
  var valid_602670 = query.getOrDefault("Version")
  valid_602670 = validateParameter(valid_602670, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602670 != nil:
    section.add "Version", valid_602670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602671 = header.getOrDefault("X-Amz-Signature")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Signature", valid_602671
  var valid_602672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Content-Sha256", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-Date")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-Date", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-Credential")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Credential", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Security-Token")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Security-Token", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Algorithm")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Algorithm", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-SignedHeaders", valid_602677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602678: Call_GetListDashboards_602664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the dashboards for your account. If you include <code>DashboardNamePrefix</code>, only those dashboards with names starting with the prefix are listed. Otherwise, all dashboards in your account are listed. </p> <p> <code>ListDashboards</code> returns up to 1000 results on one page. If there are more than 1000 dashboards, you can call <code>ListDashboards</code> again and include the value you received for <code>NextToken</code> in the first call, to receive the next 1000 results.</p>
  ## 
  let valid = call_602678.validator(path, query, header, formData, body)
  let scheme = call_602678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602678.url(scheme.get, call_602678.host, call_602678.base,
                         call_602678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602678, url, valid)

proc call*(call_602679: Call_GetListDashboards_602664;
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
  var query_602680 = newJObject()
  add(query_602680, "DashboardNamePrefix", newJString(DashboardNamePrefix))
  add(query_602680, "NextToken", newJString(NextToken))
  add(query_602680, "Action", newJString(Action))
  add(query_602680, "Version", newJString(Version))
  result = call_602679.call(nil, query_602680, nil, nil, nil)

var getListDashboards* = Call_GetListDashboards_602664(name: "getListDashboards",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListDashboards", validator: validate_GetListDashboards_602665,
    base: "/", url: url_GetListDashboards_602666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListMetrics_602718 = ref object of OpenApiRestCall_601389
proc url_PostListMetrics_602720(protocol: Scheme; host: string; base: string;
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

proc validate_PostListMetrics_602719(path: JsonNode; query: JsonNode;
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
  var valid_602721 = query.getOrDefault("Action")
  valid_602721 = validateParameter(valid_602721, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_602721 != nil:
    section.add "Action", valid_602721
  var valid_602722 = query.getOrDefault("Version")
  valid_602722 = validateParameter(valid_602722, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602722 != nil:
    section.add "Version", valid_602722
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602723 = header.getOrDefault("X-Amz-Signature")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Signature", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Content-Sha256", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Date")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Date", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-Credential")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Credential", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-Security-Token")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Security-Token", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-Algorithm")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Algorithm", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-SignedHeaders", valid_602729
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
  var valid_602730 = formData.getOrDefault("NextToken")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "NextToken", valid_602730
  var valid_602731 = formData.getOrDefault("MetricName")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "MetricName", valid_602731
  var valid_602732 = formData.getOrDefault("Dimensions")
  valid_602732 = validateParameter(valid_602732, JArray, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "Dimensions", valid_602732
  var valid_602733 = formData.getOrDefault("Namespace")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "Namespace", valid_602733
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602734: Call_PostListMetrics_602718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_602734.validator(path, query, header, formData, body)
  let scheme = call_602734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602734.url(scheme.get, call_602734.host, call_602734.base,
                         call_602734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602734, url, valid)

proc call*(call_602735: Call_PostListMetrics_602718; NextToken: string = "";
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
  var query_602736 = newJObject()
  var formData_602737 = newJObject()
  add(formData_602737, "NextToken", newJString(NextToken))
  add(formData_602737, "MetricName", newJString(MetricName))
  add(query_602736, "Action", newJString(Action))
  if Dimensions != nil:
    formData_602737.add "Dimensions", Dimensions
  add(formData_602737, "Namespace", newJString(Namespace))
  add(query_602736, "Version", newJString(Version))
  result = call_602735.call(nil, query_602736, nil, formData_602737, nil)

var postListMetrics* = Call_PostListMetrics_602718(name: "postListMetrics",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_PostListMetrics_602719,
    base: "/", url: url_PostListMetrics_602720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListMetrics_602699 = ref object of OpenApiRestCall_601389
proc url_GetListMetrics_602701(protocol: Scheme; host: string; base: string;
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

proc validate_GetListMetrics_602700(path: JsonNode; query: JsonNode;
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
  var valid_602702 = query.getOrDefault("NextToken")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "NextToken", valid_602702
  var valid_602703 = query.getOrDefault("Namespace")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "Namespace", valid_602703
  var valid_602704 = query.getOrDefault("Dimensions")
  valid_602704 = validateParameter(valid_602704, JArray, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "Dimensions", valid_602704
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602705 = query.getOrDefault("Action")
  valid_602705 = validateParameter(valid_602705, JString, required = true,
                                 default = newJString("ListMetrics"))
  if valid_602705 != nil:
    section.add "Action", valid_602705
  var valid_602706 = query.getOrDefault("Version")
  valid_602706 = validateParameter(valid_602706, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602706 != nil:
    section.add "Version", valid_602706
  var valid_602707 = query.getOrDefault("MetricName")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "MetricName", valid_602707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602708 = header.getOrDefault("X-Amz-Signature")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Signature", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Content-Sha256", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Date")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Date", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Credential")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Credential", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Security-Token")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Security-Token", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Algorithm")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Algorithm", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-SignedHeaders", valid_602714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602715: Call_GetListMetrics_602699; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List the specified metrics. You can use the returned metrics with <a>GetMetricData</a> or <a>GetMetricStatistics</a> to obtain statistical data.</p> <p>Up to 500 results are returned for any one call. To retrieve additional results, use the returned token with subsequent calls.</p> <p>After you create a metric, allow up to fifteen minutes before the metric appears. Statistics about the metric, however, are available sooner using <a>GetMetricData</a> or <a>GetMetricStatistics</a>.</p>
  ## 
  let valid = call_602715.validator(path, query, header, formData, body)
  let scheme = call_602715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602715.url(scheme.get, call_602715.host, call_602715.base,
                         call_602715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602715, url, valid)

proc call*(call_602716: Call_GetListMetrics_602699; NextToken: string = "";
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
  var query_602717 = newJObject()
  add(query_602717, "NextToken", newJString(NextToken))
  add(query_602717, "Namespace", newJString(Namespace))
  if Dimensions != nil:
    query_602717.add "Dimensions", Dimensions
  add(query_602717, "Action", newJString(Action))
  add(query_602717, "Version", newJString(Version))
  add(query_602717, "MetricName", newJString(MetricName))
  result = call_602716.call(nil, query_602717, nil, nil, nil)

var getListMetrics* = Call_GetListMetrics_602699(name: "getListMetrics",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=ListMetrics", validator: validate_GetListMetrics_602700,
    base: "/", url: url_GetListMetrics_602701, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602754 = ref object of OpenApiRestCall_601389
proc url_PostListTagsForResource_602756(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_602755(path: JsonNode; query: JsonNode;
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
  var valid_602757 = query.getOrDefault("Action")
  valid_602757 = validateParameter(valid_602757, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602757 != nil:
    section.add "Action", valid_602757
  var valid_602758 = query.getOrDefault("Version")
  valid_602758 = validateParameter(valid_602758, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602758 != nil:
    section.add "Version", valid_602758
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602759 = header.getOrDefault("X-Amz-Signature")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Signature", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-Content-Sha256", valid_602760
  var valid_602761 = header.getOrDefault("X-Amz-Date")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "X-Amz-Date", valid_602761
  var valid_602762 = header.getOrDefault("X-Amz-Credential")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "X-Amz-Credential", valid_602762
  var valid_602763 = header.getOrDefault("X-Amz-Security-Token")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-Security-Token", valid_602763
  var valid_602764 = header.getOrDefault("X-Amz-Algorithm")
  valid_602764 = validateParameter(valid_602764, JString, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "X-Amz-Algorithm", valid_602764
  var valid_602765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "X-Amz-SignedHeaders", valid_602765
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceARN: JString (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceARN` field"
  var valid_602766 = formData.getOrDefault("ResourceARN")
  valid_602766 = validateParameter(valid_602766, JString, required = true,
                                 default = nil)
  if valid_602766 != nil:
    section.add "ResourceARN", valid_602766
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602767: Call_PostListTagsForResource_602754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_602767.validator(path, query, header, formData, body)
  let scheme = call_602767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602767.url(scheme.get, call_602767.host, call_602767.base,
                         call_602767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602767, url, valid)

proc call*(call_602768: Call_PostListTagsForResource_602754; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## postListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  var query_602769 = newJObject()
  var formData_602770 = newJObject()
  add(query_602769, "Action", newJString(Action))
  add(query_602769, "Version", newJString(Version))
  add(formData_602770, "ResourceARN", newJString(ResourceARN))
  result = call_602768.call(nil, query_602769, nil, formData_602770, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602754(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602755, base: "/",
    url: url_PostListTagsForResource_602756, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602738 = ref object of OpenApiRestCall_601389
proc url_GetListTagsForResource_602740(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_602739(path: JsonNode; query: JsonNode;
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
  var valid_602741 = query.getOrDefault("Action")
  valid_602741 = validateParameter(valid_602741, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602741 != nil:
    section.add "Action", valid_602741
  var valid_602742 = query.getOrDefault("ResourceARN")
  valid_602742 = validateParameter(valid_602742, JString, required = true,
                                 default = nil)
  if valid_602742 != nil:
    section.add "ResourceARN", valid_602742
  var valid_602743 = query.getOrDefault("Version")
  valid_602743 = validateParameter(valid_602743, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602743 != nil:
    section.add "Version", valid_602743
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602744 = header.getOrDefault("X-Amz-Signature")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Signature", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-Content-Sha256", valid_602745
  var valid_602746 = header.getOrDefault("X-Amz-Date")
  valid_602746 = validateParameter(valid_602746, JString, required = false,
                                 default = nil)
  if valid_602746 != nil:
    section.add "X-Amz-Date", valid_602746
  var valid_602747 = header.getOrDefault("X-Amz-Credential")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-Credential", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-Security-Token")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-Security-Token", valid_602748
  var valid_602749 = header.getOrDefault("X-Amz-Algorithm")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "X-Amz-Algorithm", valid_602749
  var valid_602750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-SignedHeaders", valid_602750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602751: Call_GetListTagsForResource_602738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ## 
  let valid = call_602751.validator(path, query, header, formData, body)
  let scheme = call_602751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602751.url(scheme.get, call_602751.host, call_602751.base,
                         call_602751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602751, url, valid)

proc call*(call_602752: Call_GetListTagsForResource_602738; ResourceARN: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-08-01"): Recallable =
  ## getListTagsForResource
  ## Displays the tags associated with a CloudWatch resource. Alarms support tagging.
  ##   Action: string (required)
  ##   ResourceARN: string (required)
  ##              : The ARN of the CloudWatch resource that you want to view tags for. For more information on ARN format, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-cloudwatch">Example ARNs</a> in the <i>Amazon Web Services General Reference</i>.
  ##   Version: string (required)
  var query_602753 = newJObject()
  add(query_602753, "Action", newJString(Action))
  add(query_602753, "ResourceARN", newJString(ResourceARN))
  add(query_602753, "Version", newJString(Version))
  result = call_602752.call(nil, query_602753, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602738(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602739, base: "/",
    url: url_GetListTagsForResource_602740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAnomalyDetector_602792 = ref object of OpenApiRestCall_601389
proc url_PostPutAnomalyDetector_602794(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutAnomalyDetector_602793(path: JsonNode; query: JsonNode;
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
  var valid_602795 = query.getOrDefault("Action")
  valid_602795 = validateParameter(valid_602795, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_602795 != nil:
    section.add "Action", valid_602795
  var valid_602796 = query.getOrDefault("Version")
  valid_602796 = validateParameter(valid_602796, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602796 != nil:
    section.add "Version", valid_602796
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602797 = header.getOrDefault("X-Amz-Signature")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Signature", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Content-Sha256", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Date")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Date", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Credential")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Credential", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-Security-Token")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-Security-Token", valid_602801
  var valid_602802 = header.getOrDefault("X-Amz-Algorithm")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-Algorithm", valid_602802
  var valid_602803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-SignedHeaders", valid_602803
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
  var valid_602804 = formData.getOrDefault("Stat")
  valid_602804 = validateParameter(valid_602804, JString, required = true,
                                 default = nil)
  if valid_602804 != nil:
    section.add "Stat", valid_602804
  var valid_602805 = formData.getOrDefault("Configuration.MetricTimezone")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "Configuration.MetricTimezone", valid_602805
  var valid_602806 = formData.getOrDefault("MetricName")
  valid_602806 = validateParameter(valid_602806, JString, required = true,
                                 default = nil)
  if valid_602806 != nil:
    section.add "MetricName", valid_602806
  var valid_602807 = formData.getOrDefault("Dimensions")
  valid_602807 = validateParameter(valid_602807, JArray, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "Dimensions", valid_602807
  var valid_602808 = formData.getOrDefault("Namespace")
  valid_602808 = validateParameter(valid_602808, JString, required = true,
                                 default = nil)
  if valid_602808 != nil:
    section.add "Namespace", valid_602808
  var valid_602809 = formData.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_602809 = validateParameter(valid_602809, JArray, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_602809
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602810: Call_PostPutAnomalyDetector_602792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_602810.validator(path, query, header, formData, body)
  let scheme = call_602810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602810.url(scheme.get, call_602810.host, call_602810.base,
                         call_602810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602810, url, valid)

proc call*(call_602811: Call_PostPutAnomalyDetector_602792; Stat: string;
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
  var query_602812 = newJObject()
  var formData_602813 = newJObject()
  add(formData_602813, "Stat", newJString(Stat))
  add(formData_602813, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  add(formData_602813, "MetricName", newJString(MetricName))
  add(query_602812, "Action", newJString(Action))
  if Dimensions != nil:
    formData_602813.add "Dimensions", Dimensions
  add(formData_602813, "Namespace", newJString(Namespace))
  if ConfigurationExcludedTimeRanges != nil:
    formData_602813.add "Configuration.ExcludedTimeRanges",
                       ConfigurationExcludedTimeRanges
  add(query_602812, "Version", newJString(Version))
  result = call_602811.call(nil, query_602812, nil, formData_602813, nil)

var postPutAnomalyDetector* = Call_PostPutAnomalyDetector_602792(
    name: "postPutAnomalyDetector", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_PostPutAnomalyDetector_602793, base: "/",
    url: url_PostPutAnomalyDetector_602794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAnomalyDetector_602771 = ref object of OpenApiRestCall_601389
proc url_GetPutAnomalyDetector_602773(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutAnomalyDetector_602772(path: JsonNode; query: JsonNode;
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
  var valid_602774 = query.getOrDefault("Namespace")
  valid_602774 = validateParameter(valid_602774, JString, required = true,
                                 default = nil)
  if valid_602774 != nil:
    section.add "Namespace", valid_602774
  var valid_602775 = query.getOrDefault("Configuration.MetricTimezone")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "Configuration.MetricTimezone", valid_602775
  var valid_602776 = query.getOrDefault("Configuration.ExcludedTimeRanges")
  valid_602776 = validateParameter(valid_602776, JArray, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "Configuration.ExcludedTimeRanges", valid_602776
  var valid_602777 = query.getOrDefault("Dimensions")
  valid_602777 = validateParameter(valid_602777, JArray, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "Dimensions", valid_602777
  var valid_602778 = query.getOrDefault("Action")
  valid_602778 = validateParameter(valid_602778, JString, required = true,
                                 default = newJString("PutAnomalyDetector"))
  if valid_602778 != nil:
    section.add "Action", valid_602778
  var valid_602779 = query.getOrDefault("Version")
  valid_602779 = validateParameter(valid_602779, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602779 != nil:
    section.add "Version", valid_602779
  var valid_602780 = query.getOrDefault("MetricName")
  valid_602780 = validateParameter(valid_602780, JString, required = true,
                                 default = nil)
  if valid_602780 != nil:
    section.add "MetricName", valid_602780
  var valid_602781 = query.getOrDefault("Stat")
  valid_602781 = validateParameter(valid_602781, JString, required = true,
                                 default = nil)
  if valid_602781 != nil:
    section.add "Stat", valid_602781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602782 = header.getOrDefault("X-Amz-Signature")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "X-Amz-Signature", valid_602782
  var valid_602783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-Content-Sha256", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Date")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Date", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Credential")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Credential", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Security-Token")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Security-Token", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Algorithm")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Algorithm", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-SignedHeaders", valid_602788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602789: Call_GetPutAnomalyDetector_602771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an anomaly detection model for a CloudWatch metric. You can use the model to display a band of expected normal values when the metric is graphed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html">CloudWatch Anomaly Detection</a>.</p>
  ## 
  let valid = call_602789.validator(path, query, header, formData, body)
  let scheme = call_602789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602789.url(scheme.get, call_602789.host, call_602789.base,
                         call_602789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602789, url, valid)

proc call*(call_602790: Call_GetPutAnomalyDetector_602771; Namespace: string;
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
  var query_602791 = newJObject()
  add(query_602791, "Namespace", newJString(Namespace))
  add(query_602791, "Configuration.MetricTimezone",
      newJString(ConfigurationMetricTimezone))
  if ConfigurationExcludedTimeRanges != nil:
    query_602791.add "Configuration.ExcludedTimeRanges",
                    ConfigurationExcludedTimeRanges
  if Dimensions != nil:
    query_602791.add "Dimensions", Dimensions
  add(query_602791, "Action", newJString(Action))
  add(query_602791, "Version", newJString(Version))
  add(query_602791, "MetricName", newJString(MetricName))
  add(query_602791, "Stat", newJString(Stat))
  result = call_602790.call(nil, query_602791, nil, nil, nil)

var getPutAnomalyDetector* = Call_GetPutAnomalyDetector_602771(
    name: "getPutAnomalyDetector", meth: HttpMethod.HttpGet,
    host: "monitoring.amazonaws.com", route: "/#Action=PutAnomalyDetector",
    validator: validate_GetPutAnomalyDetector_602772, base: "/",
    url: url_GetPutAnomalyDetector_602773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutDashboard_602831 = ref object of OpenApiRestCall_601389
proc url_PostPutDashboard_602833(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutDashboard_602832(path: JsonNode; query: JsonNode;
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
  var valid_602834 = query.getOrDefault("Action")
  valid_602834 = validateParameter(valid_602834, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_602834 != nil:
    section.add "Action", valid_602834
  var valid_602835 = query.getOrDefault("Version")
  valid_602835 = validateParameter(valid_602835, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602835 != nil:
    section.add "Version", valid_602835
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602836 = header.getOrDefault("X-Amz-Signature")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Signature", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Content-Sha256", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-Date")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Date", valid_602838
  var valid_602839 = header.getOrDefault("X-Amz-Credential")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "X-Amz-Credential", valid_602839
  var valid_602840 = header.getOrDefault("X-Amz-Security-Token")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "X-Amz-Security-Token", valid_602840
  var valid_602841 = header.getOrDefault("X-Amz-Algorithm")
  valid_602841 = validateParameter(valid_602841, JString, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "X-Amz-Algorithm", valid_602841
  var valid_602842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "X-Amz-SignedHeaders", valid_602842
  result.add "header", section
  ## parameters in `formData` object:
  ##   DashboardName: JString (required)
  ##                : The name of the dashboard. If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created. The maximum length is 255, and valid characters are A-Z, a-z, 0-9, "-", and "_". This parameter is required.
  ##   DashboardBody: JString (required)
  ##                : <p>The detailed information about the dashboard in JSON format, including the widgets to include and their location on the dashboard. This parameter is required.</p> <p>For more information about the syntax, see <a>CloudWatch-Dashboard-Body-Structure</a>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DashboardName` field"
  var valid_602843 = formData.getOrDefault("DashboardName")
  valid_602843 = validateParameter(valid_602843, JString, required = true,
                                 default = nil)
  if valid_602843 != nil:
    section.add "DashboardName", valid_602843
  var valid_602844 = formData.getOrDefault("DashboardBody")
  valid_602844 = validateParameter(valid_602844, JString, required = true,
                                 default = nil)
  if valid_602844 != nil:
    section.add "DashboardBody", valid_602844
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602845: Call_PostPutDashboard_602831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_602845.validator(path, query, header, formData, body)
  let scheme = call_602845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602845.url(scheme.get, call_602845.host, call_602845.base,
                         call_602845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602845, url, valid)

proc call*(call_602846: Call_PostPutDashboard_602831; DashboardName: string;
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
  var query_602847 = newJObject()
  var formData_602848 = newJObject()
  add(formData_602848, "DashboardName", newJString(DashboardName))
  add(query_602847, "Action", newJString(Action))
  add(formData_602848, "DashboardBody", newJString(DashboardBody))
  add(query_602847, "Version", newJString(Version))
  result = call_602846.call(nil, query_602847, nil, formData_602848, nil)

var postPutDashboard* = Call_PostPutDashboard_602831(name: "postPutDashboard",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_PostPutDashboard_602832,
    base: "/", url: url_PostPutDashboard_602833,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutDashboard_602814 = ref object of OpenApiRestCall_601389
proc url_GetPutDashboard_602816(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutDashboard_602815(path: JsonNode; query: JsonNode;
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
  var valid_602817 = query.getOrDefault("DashboardBody")
  valid_602817 = validateParameter(valid_602817, JString, required = true,
                                 default = nil)
  if valid_602817 != nil:
    section.add "DashboardBody", valid_602817
  var valid_602818 = query.getOrDefault("Action")
  valid_602818 = validateParameter(valid_602818, JString, required = true,
                                 default = newJString("PutDashboard"))
  if valid_602818 != nil:
    section.add "Action", valid_602818
  var valid_602819 = query.getOrDefault("DashboardName")
  valid_602819 = validateParameter(valid_602819, JString, required = true,
                                 default = nil)
  if valid_602819 != nil:
    section.add "DashboardName", valid_602819
  var valid_602820 = query.getOrDefault("Version")
  valid_602820 = validateParameter(valid_602820, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602820 != nil:
    section.add "Version", valid_602820
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602821 = header.getOrDefault("X-Amz-Signature")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Signature", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Content-Sha256", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Date")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Date", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-Credential")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-Credential", valid_602824
  var valid_602825 = header.getOrDefault("X-Amz-Security-Token")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "X-Amz-Security-Token", valid_602825
  var valid_602826 = header.getOrDefault("X-Amz-Algorithm")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "X-Amz-Algorithm", valid_602826
  var valid_602827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602827 = validateParameter(valid_602827, JString, required = false,
                                 default = nil)
  if valid_602827 != nil:
    section.add "X-Amz-SignedHeaders", valid_602827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602828: Call_GetPutDashboard_602814; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard if it does not already exist, or updates an existing dashboard. If you update a dashboard, the entire contents are replaced with what you specify here.</p> <p>All dashboards in your account are global, not region-specific.</p> <p>A simple way to create a dashboard using <code>PutDashboard</code> is to copy an existing dashboard. To copy an existing dashboard using the console, you can load the dashboard and then use the View/edit source command in the Actions menu to display the JSON block for that dashboard. Another way to copy a dashboard is to use <code>GetDashboard</code>, and then use the data returned within <code>DashboardBody</code> as the template for the new dashboard when you call <code>PutDashboard</code>.</p> <p>When you create a dashboard with <code>PutDashboard</code>, a good practice is to add a text widget at the top of the dashboard with a message that the dashboard was created by script and should not be changed in the console. This message could also point console users to the location of the <code>DashboardBody</code> script or the CloudFormation template used to create the dashboard.</p>
  ## 
  let valid = call_602828.validator(path, query, header, formData, body)
  let scheme = call_602828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602828.url(scheme.get, call_602828.host, call_602828.base,
                         call_602828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602828, url, valid)

proc call*(call_602829: Call_GetPutDashboard_602814; DashboardBody: string;
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
  var query_602830 = newJObject()
  add(query_602830, "DashboardBody", newJString(DashboardBody))
  add(query_602830, "Action", newJString(Action))
  add(query_602830, "DashboardName", newJString(DashboardName))
  add(query_602830, "Version", newJString(Version))
  result = call_602829.call(nil, query_602830, nil, nil, nil)

var getPutDashboard* = Call_GetPutDashboard_602814(name: "getPutDashboard",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutDashboard", validator: validate_GetPutDashboard_602815,
    base: "/", url: url_GetPutDashboard_602816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutInsightRule_602867 = ref object of OpenApiRestCall_601389
proc url_PostPutInsightRule_602869(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutInsightRule_602868(path: JsonNode; query: JsonNode;
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
  var valid_602870 = query.getOrDefault("Action")
  valid_602870 = validateParameter(valid_602870, JString, required = true,
                                 default = newJString("PutInsightRule"))
  if valid_602870 != nil:
    section.add "Action", valid_602870
  var valid_602871 = query.getOrDefault("Version")
  valid_602871 = validateParameter(valid_602871, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602871 != nil:
    section.add "Version", valid_602871
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602872 = header.getOrDefault("X-Amz-Signature")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Signature", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Content-Sha256", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Date")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Date", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Credential")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Credential", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Security-Token")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Security-Token", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Algorithm")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Algorithm", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-SignedHeaders", valid_602878
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
  var valid_602879 = formData.getOrDefault("RuleName")
  valid_602879 = validateParameter(valid_602879, JString, required = true,
                                 default = nil)
  if valid_602879 != nil:
    section.add "RuleName", valid_602879
  var valid_602880 = formData.getOrDefault("RuleState")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "RuleState", valid_602880
  var valid_602881 = formData.getOrDefault("RuleDefinition")
  valid_602881 = validateParameter(valid_602881, JString, required = true,
                                 default = nil)
  if valid_602881 != nil:
    section.add "RuleDefinition", valid_602881
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602882: Call_PostPutInsightRule_602867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_602882.validator(path, query, header, formData, body)
  let scheme = call_602882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602882.url(scheme.get, call_602882.host, call_602882.base,
                         call_602882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602882, url, valid)

proc call*(call_602883: Call_PostPutInsightRule_602867; RuleName: string;
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
  var query_602884 = newJObject()
  var formData_602885 = newJObject()
  add(formData_602885, "RuleName", newJString(RuleName))
  add(formData_602885, "RuleState", newJString(RuleState))
  add(query_602884, "Action", newJString(Action))
  add(query_602884, "Version", newJString(Version))
  add(formData_602885, "RuleDefinition", newJString(RuleDefinition))
  result = call_602883.call(nil, query_602884, nil, formData_602885, nil)

var postPutInsightRule* = Call_PostPutInsightRule_602867(
    name: "postPutInsightRule", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutInsightRule",
    validator: validate_PostPutInsightRule_602868, base: "/",
    url: url_PostPutInsightRule_602869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutInsightRule_602849 = ref object of OpenApiRestCall_601389
proc url_GetPutInsightRule_602851(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutInsightRule_602850(path: JsonNode; query: JsonNode;
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
  var valid_602852 = query.getOrDefault("RuleName")
  valid_602852 = validateParameter(valid_602852, JString, required = true,
                                 default = nil)
  if valid_602852 != nil:
    section.add "RuleName", valid_602852
  var valid_602853 = query.getOrDefault("RuleDefinition")
  valid_602853 = validateParameter(valid_602853, JString, required = true,
                                 default = nil)
  if valid_602853 != nil:
    section.add "RuleDefinition", valid_602853
  var valid_602854 = query.getOrDefault("Action")
  valid_602854 = validateParameter(valid_602854, JString, required = true,
                                 default = newJString("PutInsightRule"))
  if valid_602854 != nil:
    section.add "Action", valid_602854
  var valid_602855 = query.getOrDefault("Version")
  valid_602855 = validateParameter(valid_602855, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602855 != nil:
    section.add "Version", valid_602855
  var valid_602856 = query.getOrDefault("RuleState")
  valid_602856 = validateParameter(valid_602856, JString, required = false,
                                 default = nil)
  if valid_602856 != nil:
    section.add "RuleState", valid_602856
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602857 = header.getOrDefault("X-Amz-Signature")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "X-Amz-Signature", valid_602857
  var valid_602858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-Content-Sha256", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Date")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Date", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Credential")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Credential", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-Security-Token")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Security-Token", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Algorithm")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Algorithm", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-SignedHeaders", valid_602863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602864: Call_GetPutInsightRule_602849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Contributor Insights rule. Rules evaluate log events in a CloudWatch Logs log group, enabling you to find contributor data for the log events in that log group. For more information, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContributorInsights.html">Using Contributor Insights to Analyze High-Cardinality Data</a>.</p> <p>If you create a rule, delete it, and then re-create it with the same name, historical data from the first time the rule was created may or may not be available.</p>
  ## 
  let valid = call_602864.validator(path, query, header, formData, body)
  let scheme = call_602864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602864.url(scheme.get, call_602864.host, call_602864.base,
                         call_602864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602864, url, valid)

proc call*(call_602865: Call_GetPutInsightRule_602849; RuleName: string;
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
  var query_602866 = newJObject()
  add(query_602866, "RuleName", newJString(RuleName))
  add(query_602866, "RuleDefinition", newJString(RuleDefinition))
  add(query_602866, "Action", newJString(Action))
  add(query_602866, "Version", newJString(Version))
  add(query_602866, "RuleState", newJString(RuleState))
  result = call_602865.call(nil, query_602866, nil, nil, nil)

var getPutInsightRule* = Call_GetPutInsightRule_602849(name: "getPutInsightRule",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutInsightRule", validator: validate_GetPutInsightRule_602850,
    base: "/", url: url_GetPutInsightRule_602851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricAlarm_602923 = ref object of OpenApiRestCall_601389
proc url_PostPutMetricAlarm_602925(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutMetricAlarm_602924(path: JsonNode; query: JsonNode;
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
  var valid_602926 = query.getOrDefault("Action")
  valid_602926 = validateParameter(valid_602926, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_602926 != nil:
    section.add "Action", valid_602926
  var valid_602927 = query.getOrDefault("Version")
  valid_602927 = validateParameter(valid_602927, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602927 != nil:
    section.add "Version", valid_602927
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602928 = header.getOrDefault("X-Amz-Signature")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Signature", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-Content-Sha256", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Date")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Date", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-Credential")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-Credential", valid_602931
  var valid_602932 = header.getOrDefault("X-Amz-Security-Token")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Security-Token", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Algorithm")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Algorithm", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-SignedHeaders", valid_602934
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
  var valid_602935 = formData.getOrDefault("ActionsEnabled")
  valid_602935 = validateParameter(valid_602935, JBool, required = false, default = nil)
  if valid_602935 != nil:
    section.add "ActionsEnabled", valid_602935
  var valid_602936 = formData.getOrDefault("AlarmDescription")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "AlarmDescription", valid_602936
  assert formData != nil,
        "formData argument is necessary due to required `AlarmName` field"
  var valid_602937 = formData.getOrDefault("AlarmName")
  valid_602937 = validateParameter(valid_602937, JString, required = true,
                                 default = nil)
  if valid_602937 != nil:
    section.add "AlarmName", valid_602937
  var valid_602938 = formData.getOrDefault("ThresholdMetricId")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "ThresholdMetricId", valid_602938
  var valid_602939 = formData.getOrDefault("Unit")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_602939 != nil:
    section.add "Unit", valid_602939
  var valid_602940 = formData.getOrDefault("Period")
  valid_602940 = validateParameter(valid_602940, JInt, required = false, default = nil)
  if valid_602940 != nil:
    section.add "Period", valid_602940
  var valid_602941 = formData.getOrDefault("AlarmActions")
  valid_602941 = validateParameter(valid_602941, JArray, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "AlarmActions", valid_602941
  var valid_602942 = formData.getOrDefault("ComparisonOperator")
  valid_602942 = validateParameter(valid_602942, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_602942 != nil:
    section.add "ComparisonOperator", valid_602942
  var valid_602943 = formData.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_602943
  var valid_602944 = formData.getOrDefault("OKActions")
  valid_602944 = validateParameter(valid_602944, JArray, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "OKActions", valid_602944
  var valid_602945 = formData.getOrDefault("Statistic")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_602945 != nil:
    section.add "Statistic", valid_602945
  var valid_602946 = formData.getOrDefault("TreatMissingData")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "TreatMissingData", valid_602946
  var valid_602947 = formData.getOrDefault("InsufficientDataActions")
  valid_602947 = validateParameter(valid_602947, JArray, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "InsufficientDataActions", valid_602947
  var valid_602948 = formData.getOrDefault("DatapointsToAlarm")
  valid_602948 = validateParameter(valid_602948, JInt, required = false, default = nil)
  if valid_602948 != nil:
    section.add "DatapointsToAlarm", valid_602948
  var valid_602949 = formData.getOrDefault("MetricName")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "MetricName", valid_602949
  var valid_602950 = formData.getOrDefault("Dimensions")
  valid_602950 = validateParameter(valid_602950, JArray, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "Dimensions", valid_602950
  var valid_602951 = formData.getOrDefault("Tags")
  valid_602951 = validateParameter(valid_602951, JArray, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "Tags", valid_602951
  var valid_602952 = formData.getOrDefault("Namespace")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "Namespace", valid_602952
  var valid_602953 = formData.getOrDefault("ExtendedStatistic")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "ExtendedStatistic", valid_602953
  var valid_602954 = formData.getOrDefault("EvaluationPeriods")
  valid_602954 = validateParameter(valid_602954, JInt, required = true, default = nil)
  if valid_602954 != nil:
    section.add "EvaluationPeriods", valid_602954
  var valid_602955 = formData.getOrDefault("Threshold")
  valid_602955 = validateParameter(valid_602955, JFloat, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "Threshold", valid_602955
  var valid_602956 = formData.getOrDefault("Metrics")
  valid_602956 = validateParameter(valid_602956, JArray, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "Metrics", valid_602956
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602957: Call_PostPutMetricAlarm_602923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_602957.validator(path, query, header, formData, body)
  let scheme = call_602957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602957.url(scheme.get, call_602957.host, call_602957.base,
                         call_602957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602957, url, valid)

proc call*(call_602958: Call_PostPutMetricAlarm_602923; AlarmName: string;
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
  var query_602959 = newJObject()
  var formData_602960 = newJObject()
  add(formData_602960, "ActionsEnabled", newJBool(ActionsEnabled))
  add(formData_602960, "AlarmDescription", newJString(AlarmDescription))
  add(formData_602960, "AlarmName", newJString(AlarmName))
  add(formData_602960, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(formData_602960, "Unit", newJString(Unit))
  add(formData_602960, "Period", newJInt(Period))
  if AlarmActions != nil:
    formData_602960.add "AlarmActions", AlarmActions
  add(formData_602960, "ComparisonOperator", newJString(ComparisonOperator))
  add(formData_602960, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  if OKActions != nil:
    formData_602960.add "OKActions", OKActions
  add(formData_602960, "Statistic", newJString(Statistic))
  add(formData_602960, "TreatMissingData", newJString(TreatMissingData))
  if InsufficientDataActions != nil:
    formData_602960.add "InsufficientDataActions", InsufficientDataActions
  add(formData_602960, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(formData_602960, "MetricName", newJString(MetricName))
  add(query_602959, "Action", newJString(Action))
  if Dimensions != nil:
    formData_602960.add "Dimensions", Dimensions
  if Tags != nil:
    formData_602960.add "Tags", Tags
  add(formData_602960, "Namespace", newJString(Namespace))
  add(formData_602960, "ExtendedStatistic", newJString(ExtendedStatistic))
  add(query_602959, "Version", newJString(Version))
  add(formData_602960, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(formData_602960, "Threshold", newJFloat(Threshold))
  if Metrics != nil:
    formData_602960.add "Metrics", Metrics
  result = call_602958.call(nil, query_602959, nil, formData_602960, nil)

var postPutMetricAlarm* = Call_PostPutMetricAlarm_602923(
    name: "postPutMetricAlarm", meth: HttpMethod.HttpPost,
    host: "monitoring.amazonaws.com", route: "/#Action=PutMetricAlarm",
    validator: validate_PostPutMetricAlarm_602924, base: "/",
    url: url_PostPutMetricAlarm_602925, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricAlarm_602886 = ref object of OpenApiRestCall_601389
proc url_GetPutMetricAlarm_602888(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutMetricAlarm_602887(path: JsonNode; query: JsonNode;
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
  var valid_602889 = query.getOrDefault("InsufficientDataActions")
  valid_602889 = validateParameter(valid_602889, JArray, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "InsufficientDataActions", valid_602889
  var valid_602890 = query.getOrDefault("Statistic")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = newJString("SampleCount"))
  if valid_602890 != nil:
    section.add "Statistic", valid_602890
  var valid_602891 = query.getOrDefault("AlarmDescription")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "AlarmDescription", valid_602891
  var valid_602892 = query.getOrDefault("Unit")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = newJString("Seconds"))
  if valid_602892 != nil:
    section.add "Unit", valid_602892
  var valid_602893 = query.getOrDefault("DatapointsToAlarm")
  valid_602893 = validateParameter(valid_602893, JInt, required = false, default = nil)
  if valid_602893 != nil:
    section.add "DatapointsToAlarm", valid_602893
  var valid_602894 = query.getOrDefault("Threshold")
  valid_602894 = validateParameter(valid_602894, JFloat, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "Threshold", valid_602894
  var valid_602895 = query.getOrDefault("Tags")
  valid_602895 = validateParameter(valid_602895, JArray, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "Tags", valid_602895
  var valid_602896 = query.getOrDefault("ThresholdMetricId")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "ThresholdMetricId", valid_602896
  var valid_602897 = query.getOrDefault("Namespace")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "Namespace", valid_602897
  var valid_602898 = query.getOrDefault("TreatMissingData")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "TreatMissingData", valid_602898
  var valid_602899 = query.getOrDefault("ExtendedStatistic")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "ExtendedStatistic", valid_602899
  var valid_602900 = query.getOrDefault("OKActions")
  valid_602900 = validateParameter(valid_602900, JArray, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "OKActions", valid_602900
  var valid_602901 = query.getOrDefault("Dimensions")
  valid_602901 = validateParameter(valid_602901, JArray, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "Dimensions", valid_602901
  var valid_602902 = query.getOrDefault("Period")
  valid_602902 = validateParameter(valid_602902, JInt, required = false, default = nil)
  if valid_602902 != nil:
    section.add "Period", valid_602902
  assert query != nil,
        "query argument is necessary due to required `AlarmName` field"
  var valid_602903 = query.getOrDefault("AlarmName")
  valid_602903 = validateParameter(valid_602903, JString, required = true,
                                 default = nil)
  if valid_602903 != nil:
    section.add "AlarmName", valid_602903
  var valid_602904 = query.getOrDefault("Action")
  valid_602904 = validateParameter(valid_602904, JString, required = true,
                                 default = newJString("PutMetricAlarm"))
  if valid_602904 != nil:
    section.add "Action", valid_602904
  var valid_602905 = query.getOrDefault("EvaluationPeriods")
  valid_602905 = validateParameter(valid_602905, JInt, required = true, default = nil)
  if valid_602905 != nil:
    section.add "EvaluationPeriods", valid_602905
  var valid_602906 = query.getOrDefault("ActionsEnabled")
  valid_602906 = validateParameter(valid_602906, JBool, required = false, default = nil)
  if valid_602906 != nil:
    section.add "ActionsEnabled", valid_602906
  var valid_602907 = query.getOrDefault("ComparisonOperator")
  valid_602907 = validateParameter(valid_602907, JString, required = true, default = newJString(
      "GreaterThanOrEqualToThreshold"))
  if valid_602907 != nil:
    section.add "ComparisonOperator", valid_602907
  var valid_602908 = query.getOrDefault("AlarmActions")
  valid_602908 = validateParameter(valid_602908, JArray, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "AlarmActions", valid_602908
  var valid_602909 = query.getOrDefault("Metrics")
  valid_602909 = validateParameter(valid_602909, JArray, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "Metrics", valid_602909
  var valid_602910 = query.getOrDefault("Version")
  valid_602910 = validateParameter(valid_602910, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602910 != nil:
    section.add "Version", valid_602910
  var valid_602911 = query.getOrDefault("EvaluateLowSampleCountPercentile")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "EvaluateLowSampleCountPercentile", valid_602911
  var valid_602912 = query.getOrDefault("MetricName")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "MetricName", valid_602912
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602913 = header.getOrDefault("X-Amz-Signature")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Signature", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Content-Sha256", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-Date")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-Date", valid_602915
  var valid_602916 = header.getOrDefault("X-Amz-Credential")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-Credential", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Security-Token")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Security-Token", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Algorithm")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Algorithm", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-SignedHeaders", valid_602919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602920: Call_GetPutMetricAlarm_602886; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates an alarm and associates it with the specified metric, metric math expression, or anomaly detection model.</p> <p>Alarms based on anomaly detection models cannot have Auto Scaling actions.</p> <p>When this operation creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm.</p> <p>If you are an IAM user, you must have Amazon EC2 permissions for some alarm operations:</p> <ul> <li> <p> <code>iam:CreateServiceLinkedRole</code> for all alarms with EC2 actions</p> </li> <li> <p> <code>ec2:DescribeInstanceStatus</code> and <code>ec2:DescribeInstances</code> for all alarms on EC2 instance status metrics</p> </li> <li> <p> <code>ec2:StopInstances</code> for alarms with stop actions</p> </li> <li> <p> <code>ec2:TerminateInstances</code> for alarms with terminate actions</p> </li> <li> <p>No specific permissions are needed for alarms with recover actions</p> </li> </ul> <p>If you have read/write permissions for Amazon CloudWatch but not for Amazon EC2, you can still create an alarm, but the stop or terminate actions are not performed. However, if you are later granted the required permissions, the alarm actions that you created earlier are performed.</p> <p>If you are using an IAM role (for example, an EC2 instance profile), you cannot stop or terminate the instance using alarm actions. However, you can still see the alarm state and perform any other actions such as Amazon SNS notifications or Auto Scaling policies.</p> <p>If you are using temporary security credentials granted using AWS STS, you cannot stop or terminate an EC2 instance using alarm actions.</p> <p>The first time you create an alarm in the AWS Management Console, the CLI, or by using the PutMetricAlarm API, CloudWatch creates the necessary service-linked role for you. The service-linked role is called <code>AWSServiceRoleForCloudWatchEvents</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-service-linked-role">AWS service-linked role</a>.</p>
  ## 
  let valid = call_602920.validator(path, query, header, formData, body)
  let scheme = call_602920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602920.url(scheme.get, call_602920.host, call_602920.base,
                         call_602920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602920, url, valid)

proc call*(call_602921: Call_GetPutMetricAlarm_602886; AlarmName: string;
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
  var query_602922 = newJObject()
  if InsufficientDataActions != nil:
    query_602922.add "InsufficientDataActions", InsufficientDataActions
  add(query_602922, "Statistic", newJString(Statistic))
  add(query_602922, "AlarmDescription", newJString(AlarmDescription))
  add(query_602922, "Unit", newJString(Unit))
  add(query_602922, "DatapointsToAlarm", newJInt(DatapointsToAlarm))
  add(query_602922, "Threshold", newJFloat(Threshold))
  if Tags != nil:
    query_602922.add "Tags", Tags
  add(query_602922, "ThresholdMetricId", newJString(ThresholdMetricId))
  add(query_602922, "Namespace", newJString(Namespace))
  add(query_602922, "TreatMissingData", newJString(TreatMissingData))
  add(query_602922, "ExtendedStatistic", newJString(ExtendedStatistic))
  if OKActions != nil:
    query_602922.add "OKActions", OKActions
  if Dimensions != nil:
    query_602922.add "Dimensions", Dimensions
  add(query_602922, "Period", newJInt(Period))
  add(query_602922, "AlarmName", newJString(AlarmName))
  add(query_602922, "Action", newJString(Action))
  add(query_602922, "EvaluationPeriods", newJInt(EvaluationPeriods))
  add(query_602922, "ActionsEnabled", newJBool(ActionsEnabled))
  add(query_602922, "ComparisonOperator", newJString(ComparisonOperator))
  if AlarmActions != nil:
    query_602922.add "AlarmActions", AlarmActions
  if Metrics != nil:
    query_602922.add "Metrics", Metrics
  add(query_602922, "Version", newJString(Version))
  add(query_602922, "EvaluateLowSampleCountPercentile",
      newJString(EvaluateLowSampleCountPercentile))
  add(query_602922, "MetricName", newJString(MetricName))
  result = call_602921.call(nil, query_602922, nil, nil, nil)

var getPutMetricAlarm* = Call_GetPutMetricAlarm_602886(name: "getPutMetricAlarm",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricAlarm", validator: validate_GetPutMetricAlarm_602887,
    base: "/", url: url_GetPutMetricAlarm_602888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutMetricData_602978 = ref object of OpenApiRestCall_601389
proc url_PostPutMetricData_602980(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutMetricData_602979(path: JsonNode; query: JsonNode;
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
  var valid_602981 = query.getOrDefault("Action")
  valid_602981 = validateParameter(valid_602981, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_602981 != nil:
    section.add "Action", valid_602981
  var valid_602982 = query.getOrDefault("Version")
  valid_602982 = validateParameter(valid_602982, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602982 != nil:
    section.add "Version", valid_602982
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602983 = header.getOrDefault("X-Amz-Signature")
  valid_602983 = validateParameter(valid_602983, JString, required = false,
                                 default = nil)
  if valid_602983 != nil:
    section.add "X-Amz-Signature", valid_602983
  var valid_602984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "X-Amz-Content-Sha256", valid_602984
  var valid_602985 = header.getOrDefault("X-Amz-Date")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "X-Amz-Date", valid_602985
  var valid_602986 = header.getOrDefault("X-Amz-Credential")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "X-Amz-Credential", valid_602986
  var valid_602987 = header.getOrDefault("X-Amz-Security-Token")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "X-Amz-Security-Token", valid_602987
  var valid_602988 = header.getOrDefault("X-Amz-Algorithm")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "X-Amz-Algorithm", valid_602988
  var valid_602989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602989 = validateParameter(valid_602989, JString, required = false,
                                 default = nil)
  if valid_602989 != nil:
    section.add "X-Amz-SignedHeaders", valid_602989
  result.add "header", section
  ## parameters in `formData` object:
  ##   Namespace: JString (required)
  ##            : <p>The namespace for the metric data.</p> <p>To avoid conflicts with AWS service namespaces, you should not specify a namespace that begins with <code>AWS/</code> </p>
  ##   MetricData: JArray (required)
  ##             : The data for the metric. The array can include no more than 20 metrics per call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Namespace` field"
  var valid_602990 = formData.getOrDefault("Namespace")
  valid_602990 = validateParameter(valid_602990, JString, required = true,
                                 default = nil)
  if valid_602990 != nil:
    section.add "Namespace", valid_602990
  var valid_602991 = formData.getOrDefault("MetricData")
  valid_602991 = validateParameter(valid_602991, JArray, required = true, default = nil)
  if valid_602991 != nil:
    section.add "MetricData", valid_602991
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602992: Call_PostPutMetricData_602978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_602992.validator(path, query, header, formData, body)
  let scheme = call_602992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602992.url(scheme.get, call_602992.host, call_602992.base,
                         call_602992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602992, url, valid)

proc call*(call_602993: Call_PostPutMetricData_602978; Namespace: string;
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
  var query_602994 = newJObject()
  var formData_602995 = newJObject()
  add(query_602994, "Action", newJString(Action))
  add(formData_602995, "Namespace", newJString(Namespace))
  if MetricData != nil:
    formData_602995.add "MetricData", MetricData
  add(query_602994, "Version", newJString(Version))
  result = call_602993.call(nil, query_602994, nil, formData_602995, nil)

var postPutMetricData* = Call_PostPutMetricData_602978(name: "postPutMetricData",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_PostPutMetricData_602979,
    base: "/", url: url_PostPutMetricData_602980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutMetricData_602961 = ref object of OpenApiRestCall_601389
proc url_GetPutMetricData_602963(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutMetricData_602962(path: JsonNode; query: JsonNode;
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
  var valid_602964 = query.getOrDefault("Namespace")
  valid_602964 = validateParameter(valid_602964, JString, required = true,
                                 default = nil)
  if valid_602964 != nil:
    section.add "Namespace", valid_602964
  var valid_602965 = query.getOrDefault("Action")
  valid_602965 = validateParameter(valid_602965, JString, required = true,
                                 default = newJString("PutMetricData"))
  if valid_602965 != nil:
    section.add "Action", valid_602965
  var valid_602966 = query.getOrDefault("Version")
  valid_602966 = validateParameter(valid_602966, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_602966 != nil:
    section.add "Version", valid_602966
  var valid_602967 = query.getOrDefault("MetricData")
  valid_602967 = validateParameter(valid_602967, JArray, required = true, default = nil)
  if valid_602967 != nil:
    section.add "MetricData", valid_602967
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602968 = header.getOrDefault("X-Amz-Signature")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "X-Amz-Signature", valid_602968
  var valid_602969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "X-Amz-Content-Sha256", valid_602969
  var valid_602970 = header.getOrDefault("X-Amz-Date")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "X-Amz-Date", valid_602970
  var valid_602971 = header.getOrDefault("X-Amz-Credential")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "X-Amz-Credential", valid_602971
  var valid_602972 = header.getOrDefault("X-Amz-Security-Token")
  valid_602972 = validateParameter(valid_602972, JString, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "X-Amz-Security-Token", valid_602972
  var valid_602973 = header.getOrDefault("X-Amz-Algorithm")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "X-Amz-Algorithm", valid_602973
  var valid_602974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "X-Amz-SignedHeaders", valid_602974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602975: Call_GetPutMetricData_602961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes metric data points to Amazon CloudWatch. CloudWatch associates the data points with the specified metric. If the specified metric does not exist, CloudWatch creates the metric. When CloudWatch creates a metric, it can take up to fifteen minutes for the metric to appear in calls to <a>ListMetrics</a>.</p> <p>You can publish either individual data points in the <code>Value</code> field, or arrays of values and the number of times each value occurred during the period by using the <code>Values</code> and <code>Counts</code> fields in the <code>MetricDatum</code> structure. Using the <code>Values</code> and <code>Counts</code> method enables you to publish up to 150 values per metric with one <code>PutMetricData</code> request, and supports retrieving percentile statistics on this data.</p> <p>Each <code>PutMetricData</code> request is limited to 40 KB in size for HTTP POST requests. You can send a payload compressed by gzip. Each request is also limited to no more than 20 different metrics.</p> <p>Although the <code>Value</code> parameter accepts numbers of type <code>Double</code>, CloudWatch rejects values that are either too small or too large. Values must be in the range of -2^360 to 2^360. In addition, special values (for example, NaN, +Infinity, -Infinity) are not supported.</p> <p>You can use up to 10 dimensions per metric to further clarify what data the metric collects. Each dimension consists of a Name and Value pair. For more information about specifying dimensions, see <a href="https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html">Publishing Metrics</a> in the <i>Amazon CloudWatch User Guide</i>.</p> <p>Data points with time stamps from 24 hours ago or longer can take at least 48 hours to become available for <a>GetMetricData</a> or <a>GetMetricStatistics</a> from the time they are submitted.</p> <p>CloudWatch needs raw data points to calculate percentile statistics. If you publish data using a statistic set instead, you can only retrieve percentile statistics for this data if one of the following conditions is true:</p> <ul> <li> <p>The <code>SampleCount</code> value of the statistic set is 1 and <code>Min</code>, <code>Max</code>, and <code>Sum</code> are all equal.</p> </li> <li> <p>The <code>Min</code> and <code>Max</code> are equal, and <code>Sum</code> is equal to <code>Min</code> multiplied by <code>SampleCount</code>.</p> </li> </ul>
  ## 
  let valid = call_602975.validator(path, query, header, formData, body)
  let scheme = call_602975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602975.url(scheme.get, call_602975.host, call_602975.base,
                         call_602975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602975, url, valid)

proc call*(call_602976: Call_GetPutMetricData_602961; Namespace: string;
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
  var query_602977 = newJObject()
  add(query_602977, "Namespace", newJString(Namespace))
  add(query_602977, "Action", newJString(Action))
  add(query_602977, "Version", newJString(Version))
  if MetricData != nil:
    query_602977.add "MetricData", MetricData
  result = call_602976.call(nil, query_602977, nil, nil, nil)

var getPutMetricData* = Call_GetPutMetricData_602961(name: "getPutMetricData",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=PutMetricData", validator: validate_GetPutMetricData_602962,
    base: "/", url: url_GetPutMetricData_602963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetAlarmState_603015 = ref object of OpenApiRestCall_601389
proc url_PostSetAlarmState_603017(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetAlarmState_603016(path: JsonNode; query: JsonNode;
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
  var valid_603018 = query.getOrDefault("Action")
  valid_603018 = validateParameter(valid_603018, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_603018 != nil:
    section.add "Action", valid_603018
  var valid_603019 = query.getOrDefault("Version")
  valid_603019 = validateParameter(valid_603019, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603019 != nil:
    section.add "Version", valid_603019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603020 = header.getOrDefault("X-Amz-Signature")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-Signature", valid_603020
  var valid_603021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "X-Amz-Content-Sha256", valid_603021
  var valid_603022 = header.getOrDefault("X-Amz-Date")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "X-Amz-Date", valid_603022
  var valid_603023 = header.getOrDefault("X-Amz-Credential")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-Credential", valid_603023
  var valid_603024 = header.getOrDefault("X-Amz-Security-Token")
  valid_603024 = validateParameter(valid_603024, JString, required = false,
                                 default = nil)
  if valid_603024 != nil:
    section.add "X-Amz-Security-Token", valid_603024
  var valid_603025 = header.getOrDefault("X-Amz-Algorithm")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-Algorithm", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-SignedHeaders", valid_603026
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
  var valid_603027 = formData.getOrDefault("AlarmName")
  valid_603027 = validateParameter(valid_603027, JString, required = true,
                                 default = nil)
  if valid_603027 != nil:
    section.add "AlarmName", valid_603027
  var valid_603028 = formData.getOrDefault("StateValue")
  valid_603028 = validateParameter(valid_603028, JString, required = true,
                                 default = newJString("OK"))
  if valid_603028 != nil:
    section.add "StateValue", valid_603028
  var valid_603029 = formData.getOrDefault("StateReason")
  valid_603029 = validateParameter(valid_603029, JString, required = true,
                                 default = nil)
  if valid_603029 != nil:
    section.add "StateReason", valid_603029
  var valid_603030 = formData.getOrDefault("StateReasonData")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "StateReasonData", valid_603030
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603031: Call_PostSetAlarmState_603015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_603031.validator(path, query, header, formData, body)
  let scheme = call_603031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603031.url(scheme.get, call_603031.host, call_603031.base,
                         call_603031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603031, url, valid)

proc call*(call_603032: Call_PostSetAlarmState_603015; AlarmName: string;
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
  var query_603033 = newJObject()
  var formData_603034 = newJObject()
  add(formData_603034, "AlarmName", newJString(AlarmName))
  add(formData_603034, "StateValue", newJString(StateValue))
  add(formData_603034, "StateReason", newJString(StateReason))
  add(formData_603034, "StateReasonData", newJString(StateReasonData))
  add(query_603033, "Action", newJString(Action))
  add(query_603033, "Version", newJString(Version))
  result = call_603032.call(nil, query_603033, nil, formData_603034, nil)

var postSetAlarmState* = Call_PostSetAlarmState_603015(name: "postSetAlarmState",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_PostSetAlarmState_603016,
    base: "/", url: url_PostSetAlarmState_603017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetAlarmState_602996 = ref object of OpenApiRestCall_601389
proc url_GetSetAlarmState_602998(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetAlarmState_602997(path: JsonNode; query: JsonNode;
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
  var valid_602999 = query.getOrDefault("StateReason")
  valid_602999 = validateParameter(valid_602999, JString, required = true,
                                 default = nil)
  if valid_602999 != nil:
    section.add "StateReason", valid_602999
  var valid_603000 = query.getOrDefault("StateValue")
  valid_603000 = validateParameter(valid_603000, JString, required = true,
                                 default = newJString("OK"))
  if valid_603000 != nil:
    section.add "StateValue", valid_603000
  var valid_603001 = query.getOrDefault("Action")
  valid_603001 = validateParameter(valid_603001, JString, required = true,
                                 default = newJString("SetAlarmState"))
  if valid_603001 != nil:
    section.add "Action", valid_603001
  var valid_603002 = query.getOrDefault("AlarmName")
  valid_603002 = validateParameter(valid_603002, JString, required = true,
                                 default = nil)
  if valid_603002 != nil:
    section.add "AlarmName", valid_603002
  var valid_603003 = query.getOrDefault("StateReasonData")
  valid_603003 = validateParameter(valid_603003, JString, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "StateReasonData", valid_603003
  var valid_603004 = query.getOrDefault("Version")
  valid_603004 = validateParameter(valid_603004, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603004 != nil:
    section.add "Version", valid_603004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603005 = header.getOrDefault("X-Amz-Signature")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "X-Amz-Signature", valid_603005
  var valid_603006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "X-Amz-Content-Sha256", valid_603006
  var valid_603007 = header.getOrDefault("X-Amz-Date")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "X-Amz-Date", valid_603007
  var valid_603008 = header.getOrDefault("X-Amz-Credential")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "X-Amz-Credential", valid_603008
  var valid_603009 = header.getOrDefault("X-Amz-Security-Token")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "X-Amz-Security-Token", valid_603009
  var valid_603010 = header.getOrDefault("X-Amz-Algorithm")
  valid_603010 = validateParameter(valid_603010, JString, required = false,
                                 default = nil)
  if valid_603010 != nil:
    section.add "X-Amz-Algorithm", valid_603010
  var valid_603011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "X-Amz-SignedHeaders", valid_603011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603012: Call_GetSetAlarmState_602996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Temporarily sets the state of an alarm for testing purposes. When the updated state differs from the previous value, the action configured for the appropriate state is invoked. For example, if your alarm is configured to send an Amazon SNS message when an alarm is triggered, temporarily changing the alarm state to <code>ALARM</code> sends an SNS message. The alarm returns to its actual state (often within seconds). Because the alarm state change happens quickly, it is typically only visible in the alarm's <b>History</b> tab in the Amazon CloudWatch console or through <a>DescribeAlarmHistory</a>.
  ## 
  let valid = call_603012.validator(path, query, header, formData, body)
  let scheme = call_603012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603012.url(scheme.get, call_603012.host, call_603012.base,
                         call_603012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603012, url, valid)

proc call*(call_603013: Call_GetSetAlarmState_602996; StateReason: string;
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
  var query_603014 = newJObject()
  add(query_603014, "StateReason", newJString(StateReason))
  add(query_603014, "StateValue", newJString(StateValue))
  add(query_603014, "Action", newJString(Action))
  add(query_603014, "AlarmName", newJString(AlarmName))
  add(query_603014, "StateReasonData", newJString(StateReasonData))
  add(query_603014, "Version", newJString(Version))
  result = call_603013.call(nil, query_603014, nil, nil, nil)

var getSetAlarmState* = Call_GetSetAlarmState_602996(name: "getSetAlarmState",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=SetAlarmState", validator: validate_GetSetAlarmState_602997,
    base: "/", url: url_GetSetAlarmState_602998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_603052 = ref object of OpenApiRestCall_601389
proc url_PostTagResource_603054(protocol: Scheme; host: string; base: string;
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

proc validate_PostTagResource_603053(path: JsonNode; query: JsonNode;
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
  var valid_603055 = query.getOrDefault("Action")
  valid_603055 = validateParameter(valid_603055, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_603055 != nil:
    section.add "Action", valid_603055
  var valid_603056 = query.getOrDefault("Version")
  valid_603056 = validateParameter(valid_603056, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603056 != nil:
    section.add "Version", valid_603056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603057 = header.getOrDefault("X-Amz-Signature")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Signature", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Content-Sha256", valid_603058
  var valid_603059 = header.getOrDefault("X-Amz-Date")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Date", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Credential")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Credential", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Security-Token")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Security-Token", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Algorithm")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Algorithm", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-SignedHeaders", valid_603063
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
  var valid_603064 = formData.getOrDefault("Tags")
  valid_603064 = validateParameter(valid_603064, JArray, required = true, default = nil)
  if valid_603064 != nil:
    section.add "Tags", valid_603064
  var valid_603065 = formData.getOrDefault("ResourceARN")
  valid_603065 = validateParameter(valid_603065, JString, required = true,
                                 default = nil)
  if valid_603065 != nil:
    section.add "ResourceARN", valid_603065
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603066: Call_PostTagResource_603052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603066, url, valid)

proc call*(call_603067: Call_PostTagResource_603052; Tags: JsonNode;
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
  var query_603068 = newJObject()
  var formData_603069 = newJObject()
  add(query_603068, "Action", newJString(Action))
  if Tags != nil:
    formData_603069.add "Tags", Tags
  add(query_603068, "Version", newJString(Version))
  add(formData_603069, "ResourceARN", newJString(ResourceARN))
  result = call_603067.call(nil, query_603068, nil, formData_603069, nil)

var postTagResource* = Call_PostTagResource_603052(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_603053,
    base: "/", url: url_PostTagResource_603054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_603035 = ref object of OpenApiRestCall_601389
proc url_GetTagResource_603037(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagResource_603036(path: JsonNode; query: JsonNode;
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
  var valid_603038 = query.getOrDefault("Tags")
  valid_603038 = validateParameter(valid_603038, JArray, required = true, default = nil)
  if valid_603038 != nil:
    section.add "Tags", valid_603038
  var valid_603039 = query.getOrDefault("Action")
  valid_603039 = validateParameter(valid_603039, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_603039 != nil:
    section.add "Action", valid_603039
  var valid_603040 = query.getOrDefault("ResourceARN")
  valid_603040 = validateParameter(valid_603040, JString, required = true,
                                 default = nil)
  if valid_603040 != nil:
    section.add "ResourceARN", valid_603040
  var valid_603041 = query.getOrDefault("Version")
  valid_603041 = validateParameter(valid_603041, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603041 != nil:
    section.add "Version", valid_603041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603042 = header.getOrDefault("X-Amz-Signature")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Signature", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Content-Sha256", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Date")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Date", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Credential")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Credential", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Security-Token")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Security-Token", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Algorithm")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Algorithm", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-SignedHeaders", valid_603048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603049: Call_GetTagResource_603035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified CloudWatch resource. Currently, the only CloudWatch resources that can be tagged are alarms.</p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with an alarm that already has tags. If you specify a new tag key for the alarm, this tag is appended to the list of tags associated with the alarm. If you specify a tag key that is already associated with the alarm, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_603049.validator(path, query, header, formData, body)
  let scheme = call_603049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603049.url(scheme.get, call_603049.host, call_603049.base,
                         call_603049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603049, url, valid)

proc call*(call_603050: Call_GetTagResource_603035; Tags: JsonNode;
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
  var query_603051 = newJObject()
  if Tags != nil:
    query_603051.add "Tags", Tags
  add(query_603051, "Action", newJString(Action))
  add(query_603051, "ResourceARN", newJString(ResourceARN))
  add(query_603051, "Version", newJString(Version))
  result = call_603050.call(nil, query_603051, nil, nil, nil)

var getTagResource* = Call_GetTagResource_603035(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_603036,
    base: "/", url: url_GetTagResource_603037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_603087 = ref object of OpenApiRestCall_601389
proc url_PostUntagResource_603089(protocol: Scheme; host: string; base: string;
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

proc validate_PostUntagResource_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = query.getOrDefault("Action")
  valid_603090 = validateParameter(valid_603090, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_603090 != nil:
    section.add "Action", valid_603090
  var valid_603091 = query.getOrDefault("Version")
  valid_603091 = validateParameter(valid_603091, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603091 != nil:
    section.add "Version", valid_603091
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603092 = header.getOrDefault("X-Amz-Signature")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Signature", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Date")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Date", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Credential")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Credential", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Security-Token")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Security-Token", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Algorithm")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Algorithm", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-SignedHeaders", valid_603098
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
  var valid_603099 = formData.getOrDefault("TagKeys")
  valid_603099 = validateParameter(valid_603099, JArray, required = true, default = nil)
  if valid_603099 != nil:
    section.add "TagKeys", valid_603099
  var valid_603100 = formData.getOrDefault("ResourceARN")
  valid_603100 = validateParameter(valid_603100, JString, required = true,
                                 default = nil)
  if valid_603100 != nil:
    section.add "ResourceARN", valid_603100
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603101: Call_PostUntagResource_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_603101.validator(path, query, header, formData, body)
  let scheme = call_603101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603101.url(scheme.get, call_603101.host, call_603101.base,
                         call_603101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603101, url, valid)

proc call*(call_603102: Call_PostUntagResource_603087; TagKeys: JsonNode;
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
  var query_603103 = newJObject()
  var formData_603104 = newJObject()
  if TagKeys != nil:
    formData_603104.add "TagKeys", TagKeys
  add(query_603103, "Action", newJString(Action))
  add(query_603103, "Version", newJString(Version))
  add(formData_603104, "ResourceARN", newJString(ResourceARN))
  result = call_603102.call(nil, query_603103, nil, formData_603104, nil)

var postUntagResource* = Call_PostUntagResource_603087(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_603088,
    base: "/", url: url_PostUntagResource_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_603070 = ref object of OpenApiRestCall_601389
proc url_GetUntagResource_603072(protocol: Scheme; host: string; base: string;
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

proc validate_GetUntagResource_603071(path: JsonNode; query: JsonNode;
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
  var valid_603073 = query.getOrDefault("TagKeys")
  valid_603073 = validateParameter(valid_603073, JArray, required = true, default = nil)
  if valid_603073 != nil:
    section.add "TagKeys", valid_603073
  var valid_603074 = query.getOrDefault("Action")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_603074 != nil:
    section.add "Action", valid_603074
  var valid_603075 = query.getOrDefault("ResourceARN")
  valid_603075 = validateParameter(valid_603075, JString, required = true,
                                 default = nil)
  if valid_603075 != nil:
    section.add "ResourceARN", valid_603075
  var valid_603076 = query.getOrDefault("Version")
  valid_603076 = validateParameter(valid_603076, JString, required = true,
                                 default = newJString("2010-08-01"))
  if valid_603076 != nil:
    section.add "Version", valid_603076
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Date")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Date", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Credential")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Credential", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Security-Token")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Security-Token", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Algorithm")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Algorithm", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-SignedHeaders", valid_603083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_GetUntagResource_603070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603084, url, valid)

proc call*(call_603085: Call_GetUntagResource_603070; TagKeys: JsonNode;
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
  var query_603086 = newJObject()
  if TagKeys != nil:
    query_603086.add "TagKeys", TagKeys
  add(query_603086, "Action", newJString(Action))
  add(query_603086, "ResourceARN", newJString(ResourceARN))
  add(query_603086, "Version", newJString(Version))
  result = call_603085.call(nil, query_603086, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_603070(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "monitoring.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_603071,
    base: "/", url: url_GetUntagResource_603072,
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
