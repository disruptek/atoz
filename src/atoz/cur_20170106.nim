
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Cost and Usage Report Service
## version: 2017-01-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>The AWS Cost and Usage Report API enables you to programmatically create, query, and delete AWS Cost and Usage report definitions.</p> <p>AWS Cost and Usage reports track the monthly AWS costs and usage associated with your AWS account. The report contains line items for each unique combination of AWS product, usage type, and operation that your AWS account uses. You can configure the AWS Cost and Usage report to show only the data that you want, using the AWS Cost and Usage API.</p> <p>Service Endpoint</p> <p>The AWS Cost and Usage Report API provides the following endpoint:</p> <ul> <li> <p>cur.us-east-1.amazonaws.com</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cur/
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

  OpenApiRestCall_592355 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592355](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592355): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cur.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cur.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cur.us-west-2.amazonaws.com",
                           "eu-west-2": "cur.eu-west-2.amazonaws.com", "ap-northeast-3": "cur.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "cur.eu-central-1.amazonaws.com",
                           "us-east-2": "cur.us-east-2.amazonaws.com",
                           "us-east-1": "cur.us-east-1.amazonaws.com", "cn-northwest-1": "cur.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "cur.ap-south-1.amazonaws.com",
                           "eu-north-1": "cur.eu-north-1.amazonaws.com", "ap-northeast-2": "cur.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cur.us-west-1.amazonaws.com",
                           "us-gov-east-1": "cur.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cur.eu-west-3.amazonaws.com",
                           "cn-north-1": "cur.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cur.sa-east-1.amazonaws.com",
                           "eu-west-1": "cur.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "cur.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cur.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "cur.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cur.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cur.ap-southeast-1.amazonaws.com",
      "us-west-2": "cur.us-west-2.amazonaws.com",
      "eu-west-2": "cur.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cur.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cur.eu-central-1.amazonaws.com",
      "us-east-2": "cur.us-east-2.amazonaws.com",
      "us-east-1": "cur.us-east-1.amazonaws.com",
      "cn-northwest-1": "cur.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cur.ap-south-1.amazonaws.com",
      "eu-north-1": "cur.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cur.ap-northeast-2.amazonaws.com",
      "us-west-1": "cur.us-west-1.amazonaws.com",
      "us-gov-east-1": "cur.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cur.eu-west-3.amazonaws.com",
      "cn-north-1": "cur.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cur.sa-east-1.amazonaws.com",
      "eu-west-1": "cur.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cur.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cur.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cur.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cur"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DeleteReportDefinition_592694 = ref object of OpenApiRestCall_592355
proc url_DeleteReportDefinition_592696(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteReportDefinition_592695(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified report.
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
  var valid_592821 = header.getOrDefault("X-Amz-Target")
  valid_592821 = validateParameter(valid_592821, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.DeleteReportDefinition"))
  if valid_592821 != nil:
    section.add "X-Amz-Target", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Signature")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Signature", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Content-Sha256", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Date")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Date", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-Credential")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-Credential", valid_592825
  var valid_592826 = header.getOrDefault("X-Amz-Security-Token")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "X-Amz-Security-Token", valid_592826
  var valid_592827 = header.getOrDefault("X-Amz-Algorithm")
  valid_592827 = validateParameter(valid_592827, JString, required = false,
                                 default = nil)
  if valid_592827 != nil:
    section.add "X-Amz-Algorithm", valid_592827
  var valid_592828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592828 = validateParameter(valid_592828, JString, required = false,
                                 default = nil)
  if valid_592828 != nil:
    section.add "X-Amz-SignedHeaders", valid_592828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592852: Call_DeleteReportDefinition_592694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified report.
  ## 
  let valid = call_592852.validator(path, query, header, formData, body)
  let scheme = call_592852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592852.url(scheme.get, call_592852.host, call_592852.base,
                         call_592852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592852, url, valid)

proc call*(call_592923: Call_DeleteReportDefinition_592694; body: JsonNode): Recallable =
  ## deleteReportDefinition
  ## Deletes the specified report.
  ##   body: JObject (required)
  var body_592924 = newJObject()
  if body != nil:
    body_592924 = body
  result = call_592923.call(nil, nil, nil, nil, body_592924)

var deleteReportDefinition* = Call_DeleteReportDefinition_592694(
    name: "deleteReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.DeleteReportDefinition",
    validator: validate_DeleteReportDefinition_592695, base: "/",
    url: url_DeleteReportDefinition_592696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReportDefinitions_592963 = ref object of OpenApiRestCall_592355
proc url_DescribeReportDefinitions_592965(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeReportDefinitions_592964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the AWS Cost and Usage reports available to this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592966 = query.getOrDefault("MaxResults")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "MaxResults", valid_592966
  var valid_592967 = query.getOrDefault("NextToken")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "NextToken", valid_592967
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
  var valid_592968 = header.getOrDefault("X-Amz-Target")
  valid_592968 = validateParameter(valid_592968, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.DescribeReportDefinitions"))
  if valid_592968 != nil:
    section.add "X-Amz-Target", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Signature")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Signature", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-Content-Sha256", valid_592970
  var valid_592971 = header.getOrDefault("X-Amz-Date")
  valid_592971 = validateParameter(valid_592971, JString, required = false,
                                 default = nil)
  if valid_592971 != nil:
    section.add "X-Amz-Date", valid_592971
  var valid_592972 = header.getOrDefault("X-Amz-Credential")
  valid_592972 = validateParameter(valid_592972, JString, required = false,
                                 default = nil)
  if valid_592972 != nil:
    section.add "X-Amz-Credential", valid_592972
  var valid_592973 = header.getOrDefault("X-Amz-Security-Token")
  valid_592973 = validateParameter(valid_592973, JString, required = false,
                                 default = nil)
  if valid_592973 != nil:
    section.add "X-Amz-Security-Token", valid_592973
  var valid_592974 = header.getOrDefault("X-Amz-Algorithm")
  valid_592974 = validateParameter(valid_592974, JString, required = false,
                                 default = nil)
  if valid_592974 != nil:
    section.add "X-Amz-Algorithm", valid_592974
  var valid_592975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592975 = validateParameter(valid_592975, JString, required = false,
                                 default = nil)
  if valid_592975 != nil:
    section.add "X-Amz-SignedHeaders", valid_592975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592977: Call_DescribeReportDefinitions_592963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS Cost and Usage reports available to this account.
  ## 
  let valid = call_592977.validator(path, query, header, formData, body)
  let scheme = call_592977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592977.url(scheme.get, call_592977.host, call_592977.base,
                         call_592977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592977, url, valid)

proc call*(call_592978: Call_DescribeReportDefinitions_592963; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeReportDefinitions
  ## Lists the AWS Cost and Usage reports available to this account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592979 = newJObject()
  var body_592980 = newJObject()
  add(query_592979, "MaxResults", newJString(MaxResults))
  add(query_592979, "NextToken", newJString(NextToken))
  if body != nil:
    body_592980 = body
  result = call_592978.call(nil, query_592979, nil, nil, body_592980)

var describeReportDefinitions* = Call_DescribeReportDefinitions_592963(
    name: "describeReportDefinitions", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.DescribeReportDefinitions",
    validator: validate_DescribeReportDefinitions_592964, base: "/",
    url: url_DescribeReportDefinitions_592965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReportDefinition_592982 = ref object of OpenApiRestCall_592355
proc url_ModifyReportDefinition_592984(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyReportDefinition_592983(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows you to programatically update your report preferences.
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
  var valid_592985 = header.getOrDefault("X-Amz-Target")
  valid_592985 = validateParameter(valid_592985, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.ModifyReportDefinition"))
  if valid_592985 != nil:
    section.add "X-Amz-Target", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Signature")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Signature", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Content-Sha256", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Date")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Date", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-Credential")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Credential", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Security-Token")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Security-Token", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Algorithm")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Algorithm", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-SignedHeaders", valid_592992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592994: Call_ModifyReportDefinition_592982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows you to programatically update your report preferences.
  ## 
  let valid = call_592994.validator(path, query, header, formData, body)
  let scheme = call_592994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592994.url(scheme.get, call_592994.host, call_592994.base,
                         call_592994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592994, url, valid)

proc call*(call_592995: Call_ModifyReportDefinition_592982; body: JsonNode): Recallable =
  ## modifyReportDefinition
  ## Allows you to programatically update your report preferences.
  ##   body: JObject (required)
  var body_592996 = newJObject()
  if body != nil:
    body_592996 = body
  result = call_592995.call(nil, nil, nil, nil, body_592996)

var modifyReportDefinition* = Call_ModifyReportDefinition_592982(
    name: "modifyReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.ModifyReportDefinition",
    validator: validate_ModifyReportDefinition_592983, base: "/",
    url: url_ModifyReportDefinition_592984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutReportDefinition_592997 = ref object of OpenApiRestCall_592355
proc url_PutReportDefinition_592999(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutReportDefinition_592998(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a new report using the description that you provide.
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
  var valid_593000 = header.getOrDefault("X-Amz-Target")
  valid_593000 = validateParameter(valid_593000, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.PutReportDefinition"))
  if valid_593000 != nil:
    section.add "X-Amz-Target", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Signature")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Signature", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Content-Sha256", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Date")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Date", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Credential")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Credential", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Security-Token")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Security-Token", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Algorithm")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Algorithm", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-SignedHeaders", valid_593007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593009: Call_PutReportDefinition_592997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new report using the description that you provide.
  ## 
  let valid = call_593009.validator(path, query, header, formData, body)
  let scheme = call_593009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593009.url(scheme.get, call_593009.host, call_593009.base,
                         call_593009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593009, url, valid)

proc call*(call_593010: Call_PutReportDefinition_592997; body: JsonNode): Recallable =
  ## putReportDefinition
  ## Creates a new report using the description that you provide.
  ##   body: JObject (required)
  var body_593011 = newJObject()
  if body != nil:
    body_593011 = body
  result = call_593010.call(nil, nil, nil, nil, body_593011)

var putReportDefinition* = Call_PutReportDefinition_592997(
    name: "putReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.PutReportDefinition",
    validator: validate_PutReportDefinition_592998, base: "/",
    url: url_PutReportDefinition_592999, schemes: {Scheme.Https, Scheme.Http})
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
