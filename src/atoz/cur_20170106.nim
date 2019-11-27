
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599359 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599359](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599359): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DeleteReportDefinition_599696 = ref object of OpenApiRestCall_599359
proc url_DeleteReportDefinition_599698(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteReportDefinition_599697(path: JsonNode; query: JsonNode;
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
  var valid_599810 = header.getOrDefault("X-Amz-Date")
  valid_599810 = validateParameter(valid_599810, JString, required = false,
                                 default = nil)
  if valid_599810 != nil:
    section.add "X-Amz-Date", valid_599810
  var valid_599811 = header.getOrDefault("X-Amz-Security-Token")
  valid_599811 = validateParameter(valid_599811, JString, required = false,
                                 default = nil)
  if valid_599811 != nil:
    section.add "X-Amz-Security-Token", valid_599811
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599825 = header.getOrDefault("X-Amz-Target")
  valid_599825 = validateParameter(valid_599825, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.DeleteReportDefinition"))
  if valid_599825 != nil:
    section.add "X-Amz-Target", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Content-Sha256", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Algorithm")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Algorithm", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-Signature")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Signature", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-SignedHeaders", valid_599829
  var valid_599830 = header.getOrDefault("X-Amz-Credential")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = nil)
  if valid_599830 != nil:
    section.add "X-Amz-Credential", valid_599830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599854: Call_DeleteReportDefinition_599696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified report.
  ## 
  let valid = call_599854.validator(path, query, header, formData, body)
  let scheme = call_599854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599854.url(scheme.get, call_599854.host, call_599854.base,
                         call_599854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599854, url, valid)

proc call*(call_599925: Call_DeleteReportDefinition_599696; body: JsonNode): Recallable =
  ## deleteReportDefinition
  ## Deletes the specified report.
  ##   body: JObject (required)
  var body_599926 = newJObject()
  if body != nil:
    body_599926 = body
  result = call_599925.call(nil, nil, nil, nil, body_599926)

var deleteReportDefinition* = Call_DeleteReportDefinition_599696(
    name: "deleteReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.DeleteReportDefinition",
    validator: validate_DeleteReportDefinition_599697, base: "/",
    url: url_DeleteReportDefinition_599698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReportDefinitions_599965 = ref object of OpenApiRestCall_599359
proc url_DescribeReportDefinitions_599967(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReportDefinitions_599966(path: JsonNode; query: JsonNode;
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
  var valid_599968 = query.getOrDefault("NextToken")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "NextToken", valid_599968
  var valid_599969 = query.getOrDefault("MaxResults")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "MaxResults", valid_599969
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
  var valid_599970 = header.getOrDefault("X-Amz-Date")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Date", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Security-Token")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Security-Token", valid_599971
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599972 = header.getOrDefault("X-Amz-Target")
  valid_599972 = validateParameter(valid_599972, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.DescribeReportDefinitions"))
  if valid_599972 != nil:
    section.add "X-Amz-Target", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-Content-Sha256", valid_599973
  var valid_599974 = header.getOrDefault("X-Amz-Algorithm")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-Algorithm", valid_599974
  var valid_599975 = header.getOrDefault("X-Amz-Signature")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-Signature", valid_599975
  var valid_599976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599976 = validateParameter(valid_599976, JString, required = false,
                                 default = nil)
  if valid_599976 != nil:
    section.add "X-Amz-SignedHeaders", valid_599976
  var valid_599977 = header.getOrDefault("X-Amz-Credential")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Credential", valid_599977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599979: Call_DescribeReportDefinitions_599965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS Cost and Usage reports available to this account.
  ## 
  let valid = call_599979.validator(path, query, header, formData, body)
  let scheme = call_599979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599979.url(scheme.get, call_599979.host, call_599979.base,
                         call_599979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599979, url, valid)

proc call*(call_599980: Call_DescribeReportDefinitions_599965; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeReportDefinitions
  ## Lists the AWS Cost and Usage reports available to this account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_599981 = newJObject()
  var body_599982 = newJObject()
  add(query_599981, "NextToken", newJString(NextToken))
  if body != nil:
    body_599982 = body
  add(query_599981, "MaxResults", newJString(MaxResults))
  result = call_599980.call(nil, query_599981, nil, nil, body_599982)

var describeReportDefinitions* = Call_DescribeReportDefinitions_599965(
    name: "describeReportDefinitions", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.DescribeReportDefinitions",
    validator: validate_DescribeReportDefinitions_599966, base: "/",
    url: url_DescribeReportDefinitions_599967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReportDefinition_599984 = ref object of OpenApiRestCall_599359
proc url_ModifyReportDefinition_599986(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyReportDefinition_599985(path: JsonNode; query: JsonNode;
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
  var valid_599987 = header.getOrDefault("X-Amz-Date")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Date", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Security-Token")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Security-Token", valid_599988
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599989 = header.getOrDefault("X-Amz-Target")
  valid_599989 = validateParameter(valid_599989, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.ModifyReportDefinition"))
  if valid_599989 != nil:
    section.add "X-Amz-Target", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Content-Sha256", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-Algorithm")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Algorithm", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Signature")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Signature", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-SignedHeaders", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Credential")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Credential", valid_599994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599996: Call_ModifyReportDefinition_599984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows you to programatically update your report preferences.
  ## 
  let valid = call_599996.validator(path, query, header, formData, body)
  let scheme = call_599996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599996.url(scheme.get, call_599996.host, call_599996.base,
                         call_599996.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599996, url, valid)

proc call*(call_599997: Call_ModifyReportDefinition_599984; body: JsonNode): Recallable =
  ## modifyReportDefinition
  ## Allows you to programatically update your report preferences.
  ##   body: JObject (required)
  var body_599998 = newJObject()
  if body != nil:
    body_599998 = body
  result = call_599997.call(nil, nil, nil, nil, body_599998)

var modifyReportDefinition* = Call_ModifyReportDefinition_599984(
    name: "modifyReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.ModifyReportDefinition",
    validator: validate_ModifyReportDefinition_599985, base: "/",
    url: url_ModifyReportDefinition_599986, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutReportDefinition_599999 = ref object of OpenApiRestCall_599359
proc url_PutReportDefinition_600001(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutReportDefinition_600000(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600004 = header.getOrDefault("X-Amz-Target")
  valid_600004 = validateParameter(valid_600004, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.PutReportDefinition"))
  if valid_600004 != nil:
    section.add "X-Amz-Target", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Content-Sha256", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Algorithm")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Algorithm", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Signature")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Signature", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-SignedHeaders", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Credential")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Credential", valid_600009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600011: Call_PutReportDefinition_599999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new report using the description that you provide.
  ## 
  let valid = call_600011.validator(path, query, header, formData, body)
  let scheme = call_600011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600011.url(scheme.get, call_600011.host, call_600011.base,
                         call_600011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600011, url, valid)

proc call*(call_600012: Call_PutReportDefinition_599999; body: JsonNode): Recallable =
  ## putReportDefinition
  ## Creates a new report using the description that you provide.
  ##   body: JObject (required)
  var body_600013 = newJObject()
  if body != nil:
    body_600013 = body
  result = call_600012.call(nil, nil, nil, nil, body_600013)

var putReportDefinition* = Call_PutReportDefinition_599999(
    name: "putReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.PutReportDefinition",
    validator: validate_PutReportDefinition_600000, base: "/",
    url: url_PutReportDefinition_600001, schemes: {Scheme.Https, Scheme.Http})
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
