
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

  OpenApiRestCall_602457 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602457](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602457): Option[Scheme] {.used.} =
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
  Call_DeleteReportDefinition_602794 = ref object of OpenApiRestCall_602457
proc url_DeleteReportDefinition_602796(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteReportDefinition_602795(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602908 = header.getOrDefault("X-Amz-Date")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Date", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Security-Token")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Security-Token", valid_602909
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602923 = header.getOrDefault("X-Amz-Target")
  valid_602923 = validateParameter(valid_602923, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.DeleteReportDefinition"))
  if valid_602923 != nil:
    section.add "X-Amz-Target", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Content-Sha256", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Algorithm")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Algorithm", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Signature")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Signature", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-SignedHeaders", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-Credential")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Credential", valid_602928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602952: Call_DeleteReportDefinition_602794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified report.
  ## 
  let valid = call_602952.validator(path, query, header, formData, body)
  let scheme = call_602952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602952.url(scheme.get, call_602952.host, call_602952.base,
                         call_602952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602952, url, valid)

proc call*(call_603023: Call_DeleteReportDefinition_602794; body: JsonNode): Recallable =
  ## deleteReportDefinition
  ## Deletes the specified report.
  ##   body: JObject (required)
  var body_603024 = newJObject()
  if body != nil:
    body_603024 = body
  result = call_603023.call(nil, nil, nil, nil, body_603024)

var deleteReportDefinition* = Call_DeleteReportDefinition_602794(
    name: "deleteReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.DeleteReportDefinition",
    validator: validate_DeleteReportDefinition_602795, base: "/",
    url: url_DeleteReportDefinition_602796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReportDefinitions_603063 = ref object of OpenApiRestCall_602457
proc url_DescribeReportDefinitions_603065(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeReportDefinitions_603064(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the AWS Cost and Usage reports available to this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603066 = query.getOrDefault("NextToken")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "NextToken", valid_603066
  var valid_603067 = query.getOrDefault("MaxResults")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "MaxResults", valid_603067
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603068 = header.getOrDefault("X-Amz-Date")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Date", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Security-Token")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Security-Token", valid_603069
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603070 = header.getOrDefault("X-Amz-Target")
  valid_603070 = validateParameter(valid_603070, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.DescribeReportDefinitions"))
  if valid_603070 != nil:
    section.add "X-Amz-Target", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Content-Sha256", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Algorithm")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Algorithm", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Signature")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Signature", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-SignedHeaders", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Credential")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Credential", valid_603075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603077: Call_DescribeReportDefinitions_603063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS Cost and Usage reports available to this account.
  ## 
  let valid = call_603077.validator(path, query, header, formData, body)
  let scheme = call_603077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603077.url(scheme.get, call_603077.host, call_603077.base,
                         call_603077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603077, url, valid)

proc call*(call_603078: Call_DescribeReportDefinitions_603063; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeReportDefinitions
  ## Lists the AWS Cost and Usage reports available to this account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603079 = newJObject()
  var body_603080 = newJObject()
  add(query_603079, "NextToken", newJString(NextToken))
  if body != nil:
    body_603080 = body
  add(query_603079, "MaxResults", newJString(MaxResults))
  result = call_603078.call(nil, query_603079, nil, nil, body_603080)

var describeReportDefinitions* = Call_DescribeReportDefinitions_603063(
    name: "describeReportDefinitions", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.DescribeReportDefinitions",
    validator: validate_DescribeReportDefinitions_603064, base: "/",
    url: url_DescribeReportDefinitions_603065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReportDefinition_603082 = ref object of OpenApiRestCall_602457
proc url_ModifyReportDefinition_603084(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyReportDefinition_603083(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603085 = header.getOrDefault("X-Amz-Date")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Date", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Security-Token")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Security-Token", valid_603086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603087 = header.getOrDefault("X-Amz-Target")
  valid_603087 = validateParameter(valid_603087, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.ModifyReportDefinition"))
  if valid_603087 != nil:
    section.add "X-Amz-Target", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Content-Sha256", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Algorithm")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Algorithm", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Signature")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Signature", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-SignedHeaders", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Credential")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Credential", valid_603092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603094: Call_ModifyReportDefinition_603082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows you to programatically update your report preferences.
  ## 
  let valid = call_603094.validator(path, query, header, formData, body)
  let scheme = call_603094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603094.url(scheme.get, call_603094.host, call_603094.base,
                         call_603094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603094, url, valid)

proc call*(call_603095: Call_ModifyReportDefinition_603082; body: JsonNode): Recallable =
  ## modifyReportDefinition
  ## Allows you to programatically update your report preferences.
  ##   body: JObject (required)
  var body_603096 = newJObject()
  if body != nil:
    body_603096 = body
  result = call_603095.call(nil, nil, nil, nil, body_603096)

var modifyReportDefinition* = Call_ModifyReportDefinition_603082(
    name: "modifyReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.ModifyReportDefinition",
    validator: validate_ModifyReportDefinition_603083, base: "/",
    url: url_ModifyReportDefinition_603084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutReportDefinition_603097 = ref object of OpenApiRestCall_602457
proc url_PutReportDefinition_603099(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutReportDefinition_603098(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603102 = header.getOrDefault("X-Amz-Target")
  valid_603102 = validateParameter(valid_603102, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.PutReportDefinition"))
  if valid_603102 != nil:
    section.add "X-Amz-Target", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Content-Sha256", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Algorithm")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Algorithm", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Signature")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Signature", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-SignedHeaders", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Credential")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Credential", valid_603107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603109: Call_PutReportDefinition_603097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new report using the description that you provide.
  ## 
  let valid = call_603109.validator(path, query, header, formData, body)
  let scheme = call_603109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603109.url(scheme.get, call_603109.host, call_603109.base,
                         call_603109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603109, url, valid)

proc call*(call_603110: Call_PutReportDefinition_603097; body: JsonNode): Recallable =
  ## putReportDefinition
  ## Creates a new report using the description that you provide.
  ##   body: JObject (required)
  var body_603111 = newJObject()
  if body != nil:
    body_603111 = body
  result = call_603110.call(nil, nil, nil, nil, body_603111)

var putReportDefinition* = Call_PutReportDefinition_603097(
    name: "putReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.PutReportDefinition",
    validator: validate_PutReportDefinition_603098, base: "/",
    url: url_PutReportDefinition_603099, schemes: {Scheme.Https, Scheme.Http})
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
