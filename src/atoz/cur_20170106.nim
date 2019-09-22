
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602420 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602420](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602420): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_DeleteReportDefinition_602757 = ref object of OpenApiRestCall_602420
proc url_DeleteReportDefinition_602759(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteReportDefinition_602758(path: JsonNode; query: JsonNode;
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
  var valid_602871 = header.getOrDefault("X-Amz-Date")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Date", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Security-Token")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Security-Token", valid_602872
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602886 = header.getOrDefault("X-Amz-Target")
  valid_602886 = validateParameter(valid_602886, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.DeleteReportDefinition"))
  if valid_602886 != nil:
    section.add "X-Amz-Target", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Content-Sha256", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Algorithm")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Algorithm", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Signature")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Signature", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-SignedHeaders", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Credential")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Credential", valid_602891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602915: Call_DeleteReportDefinition_602757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified report.
  ## 
  let valid = call_602915.validator(path, query, header, formData, body)
  let scheme = call_602915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602915.url(scheme.get, call_602915.host, call_602915.base,
                         call_602915.route, valid.getOrDefault("path"))
  result = hook(call_602915, url, valid)

proc call*(call_602986: Call_DeleteReportDefinition_602757; body: JsonNode): Recallable =
  ## deleteReportDefinition
  ## Deletes the specified report.
  ##   body: JObject (required)
  var body_602987 = newJObject()
  if body != nil:
    body_602987 = body
  result = call_602986.call(nil, nil, nil, nil, body_602987)

var deleteReportDefinition* = Call_DeleteReportDefinition_602757(
    name: "deleteReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.DeleteReportDefinition",
    validator: validate_DeleteReportDefinition_602758, base: "/",
    url: url_DeleteReportDefinition_602759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReportDefinitions_603026 = ref object of OpenApiRestCall_602420
proc url_DescribeReportDefinitions_603028(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReportDefinitions_603027(path: JsonNode; query: JsonNode;
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
  var valid_603029 = query.getOrDefault("NextToken")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "NextToken", valid_603029
  var valid_603030 = query.getOrDefault("MaxResults")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "MaxResults", valid_603030
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
  var valid_603031 = header.getOrDefault("X-Amz-Date")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Date", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Security-Token")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Security-Token", valid_603032
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603033 = header.getOrDefault("X-Amz-Target")
  valid_603033 = validateParameter(valid_603033, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.DescribeReportDefinitions"))
  if valid_603033 != nil:
    section.add "X-Amz-Target", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Content-Sha256", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Algorithm")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Algorithm", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Signature")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Signature", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-SignedHeaders", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-Credential")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-Credential", valid_603038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603040: Call_DescribeReportDefinitions_603026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS Cost and Usage reports available to this account.
  ## 
  let valid = call_603040.validator(path, query, header, formData, body)
  let scheme = call_603040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603040.url(scheme.get, call_603040.host, call_603040.base,
                         call_603040.route, valid.getOrDefault("path"))
  result = hook(call_603040, url, valid)

proc call*(call_603041: Call_DescribeReportDefinitions_603026; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeReportDefinitions
  ## Lists the AWS Cost and Usage reports available to this account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603042 = newJObject()
  var body_603043 = newJObject()
  add(query_603042, "NextToken", newJString(NextToken))
  if body != nil:
    body_603043 = body
  add(query_603042, "MaxResults", newJString(MaxResults))
  result = call_603041.call(nil, query_603042, nil, nil, body_603043)

var describeReportDefinitions* = Call_DescribeReportDefinitions_603026(
    name: "describeReportDefinitions", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.DescribeReportDefinitions",
    validator: validate_DescribeReportDefinitions_603027, base: "/",
    url: url_DescribeReportDefinitions_603028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReportDefinition_603045 = ref object of OpenApiRestCall_602420
proc url_ModifyReportDefinition_603047(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyReportDefinition_603046(path: JsonNode; query: JsonNode;
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
  var valid_603048 = header.getOrDefault("X-Amz-Date")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Date", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Security-Token")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Security-Token", valid_603049
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603050 = header.getOrDefault("X-Amz-Target")
  valid_603050 = validateParameter(valid_603050, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.ModifyReportDefinition"))
  if valid_603050 != nil:
    section.add "X-Amz-Target", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Content-Sha256", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Algorithm")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Algorithm", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Signature")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Signature", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-SignedHeaders", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Credential")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Credential", valid_603055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603057: Call_ModifyReportDefinition_603045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows you to programatically update your report preferences.
  ## 
  let valid = call_603057.validator(path, query, header, formData, body)
  let scheme = call_603057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603057.url(scheme.get, call_603057.host, call_603057.base,
                         call_603057.route, valid.getOrDefault("path"))
  result = hook(call_603057, url, valid)

proc call*(call_603058: Call_ModifyReportDefinition_603045; body: JsonNode): Recallable =
  ## modifyReportDefinition
  ## Allows you to programatically update your report preferences.
  ##   body: JObject (required)
  var body_603059 = newJObject()
  if body != nil:
    body_603059 = body
  result = call_603058.call(nil, nil, nil, nil, body_603059)

var modifyReportDefinition* = Call_ModifyReportDefinition_603045(
    name: "modifyReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.ModifyReportDefinition",
    validator: validate_ModifyReportDefinition_603046, base: "/",
    url: url_ModifyReportDefinition_603047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutReportDefinition_603060 = ref object of OpenApiRestCall_602420
proc url_PutReportDefinition_603062(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutReportDefinition_603061(path: JsonNode; query: JsonNode;
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
  var valid_603063 = header.getOrDefault("X-Amz-Date")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Date", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Security-Token")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Security-Token", valid_603064
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603065 = header.getOrDefault("X-Amz-Target")
  valid_603065 = validateParameter(valid_603065, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.PutReportDefinition"))
  if valid_603065 != nil:
    section.add "X-Amz-Target", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Content-Sha256", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Algorithm")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Algorithm", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Signature")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Signature", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-SignedHeaders", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Credential")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Credential", valid_603070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603072: Call_PutReportDefinition_603060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new report using the description that you provide.
  ## 
  let valid = call_603072.validator(path, query, header, formData, body)
  let scheme = call_603072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603072.url(scheme.get, call_603072.host, call_603072.base,
                         call_603072.route, valid.getOrDefault("path"))
  result = hook(call_603072, url, valid)

proc call*(call_603073: Call_PutReportDefinition_603060; body: JsonNode): Recallable =
  ## putReportDefinition
  ## Creates a new report using the description that you provide.
  ##   body: JObject (required)
  var body_603074 = newJObject()
  if body != nil:
    body_603074 = body
  result = call_603073.call(nil, nil, nil, nil, body_603074)

var putReportDefinition* = Call_PutReportDefinition_603060(
    name: "putReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.PutReportDefinition",
    validator: validate_PutReportDefinition_603061, base: "/",
    url: url_PutReportDefinition_603062, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
