
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

  OpenApiRestCall_772588 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772588](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772588): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
  Call_DeleteReportDefinition_772924 = ref object of OpenApiRestCall_772588
proc url_DeleteReportDefinition_772926(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteReportDefinition_772925(path: JsonNode; query: JsonNode;
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
  var valid_773038 = header.getOrDefault("X-Amz-Date")
  valid_773038 = validateParameter(valid_773038, JString, required = false,
                                 default = nil)
  if valid_773038 != nil:
    section.add "X-Amz-Date", valid_773038
  var valid_773039 = header.getOrDefault("X-Amz-Security-Token")
  valid_773039 = validateParameter(valid_773039, JString, required = false,
                                 default = nil)
  if valid_773039 != nil:
    section.add "X-Amz-Security-Token", valid_773039
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773053 = header.getOrDefault("X-Amz-Target")
  valid_773053 = validateParameter(valid_773053, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.DeleteReportDefinition"))
  if valid_773053 != nil:
    section.add "X-Amz-Target", valid_773053
  var valid_773054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773054 = validateParameter(valid_773054, JString, required = false,
                                 default = nil)
  if valid_773054 != nil:
    section.add "X-Amz-Content-Sha256", valid_773054
  var valid_773055 = header.getOrDefault("X-Amz-Algorithm")
  valid_773055 = validateParameter(valid_773055, JString, required = false,
                                 default = nil)
  if valid_773055 != nil:
    section.add "X-Amz-Algorithm", valid_773055
  var valid_773056 = header.getOrDefault("X-Amz-Signature")
  valid_773056 = validateParameter(valid_773056, JString, required = false,
                                 default = nil)
  if valid_773056 != nil:
    section.add "X-Amz-Signature", valid_773056
  var valid_773057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773057 = validateParameter(valid_773057, JString, required = false,
                                 default = nil)
  if valid_773057 != nil:
    section.add "X-Amz-SignedHeaders", valid_773057
  var valid_773058 = header.getOrDefault("X-Amz-Credential")
  valid_773058 = validateParameter(valid_773058, JString, required = false,
                                 default = nil)
  if valid_773058 != nil:
    section.add "X-Amz-Credential", valid_773058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773082: Call_DeleteReportDefinition_772924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified report.
  ## 
  let valid = call_773082.validator(path, query, header, formData, body)
  let scheme = call_773082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773082.url(scheme.get, call_773082.host, call_773082.base,
                         call_773082.route, valid.getOrDefault("path"))
  result = hook(call_773082, url, valid)

proc call*(call_773153: Call_DeleteReportDefinition_772924; body: JsonNode): Recallable =
  ## deleteReportDefinition
  ## Deletes the specified report.
  ##   body: JObject (required)
  var body_773154 = newJObject()
  if body != nil:
    body_773154 = body
  result = call_773153.call(nil, nil, nil, nil, body_773154)

var deleteReportDefinition* = Call_DeleteReportDefinition_772924(
    name: "deleteReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.DeleteReportDefinition",
    validator: validate_DeleteReportDefinition_772925, base: "/",
    url: url_DeleteReportDefinition_772926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReportDefinitions_773193 = ref object of OpenApiRestCall_772588
proc url_DescribeReportDefinitions_773195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReportDefinitions_773194(path: JsonNode; query: JsonNode;
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
  var valid_773196 = query.getOrDefault("NextToken")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "NextToken", valid_773196
  var valid_773197 = query.getOrDefault("MaxResults")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "MaxResults", valid_773197
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
  var valid_773198 = header.getOrDefault("X-Amz-Date")
  valid_773198 = validateParameter(valid_773198, JString, required = false,
                                 default = nil)
  if valid_773198 != nil:
    section.add "X-Amz-Date", valid_773198
  var valid_773199 = header.getOrDefault("X-Amz-Security-Token")
  valid_773199 = validateParameter(valid_773199, JString, required = false,
                                 default = nil)
  if valid_773199 != nil:
    section.add "X-Amz-Security-Token", valid_773199
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773200 = header.getOrDefault("X-Amz-Target")
  valid_773200 = validateParameter(valid_773200, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.DescribeReportDefinitions"))
  if valid_773200 != nil:
    section.add "X-Amz-Target", valid_773200
  var valid_773201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773201 = validateParameter(valid_773201, JString, required = false,
                                 default = nil)
  if valid_773201 != nil:
    section.add "X-Amz-Content-Sha256", valid_773201
  var valid_773202 = header.getOrDefault("X-Amz-Algorithm")
  valid_773202 = validateParameter(valid_773202, JString, required = false,
                                 default = nil)
  if valid_773202 != nil:
    section.add "X-Amz-Algorithm", valid_773202
  var valid_773203 = header.getOrDefault("X-Amz-Signature")
  valid_773203 = validateParameter(valid_773203, JString, required = false,
                                 default = nil)
  if valid_773203 != nil:
    section.add "X-Amz-Signature", valid_773203
  var valid_773204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773204 = validateParameter(valid_773204, JString, required = false,
                                 default = nil)
  if valid_773204 != nil:
    section.add "X-Amz-SignedHeaders", valid_773204
  var valid_773205 = header.getOrDefault("X-Amz-Credential")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Credential", valid_773205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773207: Call_DescribeReportDefinitions_773193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS Cost and Usage reports available to this account.
  ## 
  let valid = call_773207.validator(path, query, header, formData, body)
  let scheme = call_773207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773207.url(scheme.get, call_773207.host, call_773207.base,
                         call_773207.route, valid.getOrDefault("path"))
  result = hook(call_773207, url, valid)

proc call*(call_773208: Call_DescribeReportDefinitions_773193; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeReportDefinitions
  ## Lists the AWS Cost and Usage reports available to this account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773209 = newJObject()
  var body_773210 = newJObject()
  add(query_773209, "NextToken", newJString(NextToken))
  if body != nil:
    body_773210 = body
  add(query_773209, "MaxResults", newJString(MaxResults))
  result = call_773208.call(nil, query_773209, nil, nil, body_773210)

var describeReportDefinitions* = Call_DescribeReportDefinitions_773193(
    name: "describeReportDefinitions", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.DescribeReportDefinitions",
    validator: validate_DescribeReportDefinitions_773194, base: "/",
    url: url_DescribeReportDefinitions_773195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReportDefinition_773212 = ref object of OpenApiRestCall_772588
proc url_ModifyReportDefinition_773214(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyReportDefinition_773213(path: JsonNode; query: JsonNode;
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
  var valid_773215 = header.getOrDefault("X-Amz-Date")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Date", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Security-Token")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Security-Token", valid_773216
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773217 = header.getOrDefault("X-Amz-Target")
  valid_773217 = validateParameter(valid_773217, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.ModifyReportDefinition"))
  if valid_773217 != nil:
    section.add "X-Amz-Target", valid_773217
  var valid_773218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Content-Sha256", valid_773218
  var valid_773219 = header.getOrDefault("X-Amz-Algorithm")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-Algorithm", valid_773219
  var valid_773220 = header.getOrDefault("X-Amz-Signature")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Signature", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-SignedHeaders", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Credential")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Credential", valid_773222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773224: Call_ModifyReportDefinition_773212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows you to programatically update your report preferences.
  ## 
  let valid = call_773224.validator(path, query, header, formData, body)
  let scheme = call_773224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773224.url(scheme.get, call_773224.host, call_773224.base,
                         call_773224.route, valid.getOrDefault("path"))
  result = hook(call_773224, url, valid)

proc call*(call_773225: Call_ModifyReportDefinition_773212; body: JsonNode): Recallable =
  ## modifyReportDefinition
  ## Allows you to programatically update your report preferences.
  ##   body: JObject (required)
  var body_773226 = newJObject()
  if body != nil:
    body_773226 = body
  result = call_773225.call(nil, nil, nil, nil, body_773226)

var modifyReportDefinition* = Call_ModifyReportDefinition_773212(
    name: "modifyReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.ModifyReportDefinition",
    validator: validate_ModifyReportDefinition_773213, base: "/",
    url: url_ModifyReportDefinition_773214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutReportDefinition_773227 = ref object of OpenApiRestCall_772588
proc url_PutReportDefinition_773229(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutReportDefinition_773228(path: JsonNode; query: JsonNode;
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
  var valid_773230 = header.getOrDefault("X-Amz-Date")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Date", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Security-Token")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Security-Token", valid_773231
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773232 = header.getOrDefault("X-Amz-Target")
  valid_773232 = validateParameter(valid_773232, JString, required = true, default = newJString(
      "AWSOrigamiServiceGatewayService.PutReportDefinition"))
  if valid_773232 != nil:
    section.add "X-Amz-Target", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Content-Sha256", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Algorithm")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Algorithm", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Signature")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Signature", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-SignedHeaders", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Credential")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Credential", valid_773237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773239: Call_PutReportDefinition_773227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new report using the description that you provide.
  ## 
  let valid = call_773239.validator(path, query, header, formData, body)
  let scheme = call_773239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773239.url(scheme.get, call_773239.host, call_773239.base,
                         call_773239.route, valid.getOrDefault("path"))
  result = hook(call_773239, url, valid)

proc call*(call_773240: Call_PutReportDefinition_773227; body: JsonNode): Recallable =
  ## putReportDefinition
  ## Creates a new report using the description that you provide.
  ##   body: JObject (required)
  var body_773241 = newJObject()
  if body != nil:
    body_773241 = body
  result = call_773240.call(nil, nil, nil, nil, body_773241)

var putReportDefinition* = Call_PutReportDefinition_773227(
    name: "putReportDefinition", meth: HttpMethod.HttpPost,
    host: "cur.amazonaws.com", route: "/#X-Amz-Target=AWSOrigamiServiceGatewayService.PutReportDefinition",
    validator: validate_PutReportDefinition_773228, base: "/",
    url: url_PutReportDefinition_773229, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
