
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWSServerlessApplicationRepository
## version: 2017-09-08
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>The AWS Serverless Application Repository makes it easy for developers and enterprises to quickly find
##  and deploy serverless applications in the AWS Cloud. For more information about serverless applications,
##  see Serverless Computing and Applications on the AWS website.</p><p>The AWS Serverless Application Repository is deeply integrated with the AWS Lambda console, so that developers of 
##  all levels can get started with serverless computing without needing to learn anything new. You can use category 
##  keywords to browse for applications such as web and mobile backends, data processing applications, or chatbots. 
##  You can also search for applications by name, publisher, or event source. To use an application, you simply choose it, 
##  configure any required fields, and deploy it with a few clicks. </p><p>You can also easily publish applications, sharing them publicly with the community at large, or privately
##  within your team or across your organization. To publish a serverless application (or app), you can use the
##  AWS Management Console, AWS Command Line Interface (AWS CLI), or AWS SDKs to upload the code. Along with the
##  code, you upload a simple manifest file, also known as the AWS Serverless Application Model (AWS SAM) template.
##  For more information about AWS SAM, see AWS Serverless Application Model (AWS SAM) on the AWS Labs
##  GitHub repository.</p><p>The AWS Serverless Application Repository Developer Guide contains more information about the two developer
##  experiences available:</p><ul>
##  <li>
##  <p>Consuming Applications – Browse for applications and view information about them, including
##  source code and readme files. Also install, configure, and deploy applications of your choosing. </p>
##  <p>Publishing Applications – Configure and upload applications to make them available to other
##  developers, and publish new versions of applications. </p>
##  </li>
##  </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/serverlessrepo/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "serverlessrepo.ap-northeast-1.amazonaws.com", "ap-southeast-1": "serverlessrepo.ap-southeast-1.amazonaws.com", "us-west-2": "serverlessrepo.us-west-2.amazonaws.com", "eu-west-2": "serverlessrepo.eu-west-2.amazonaws.com", "ap-northeast-3": "serverlessrepo.ap-northeast-3.amazonaws.com", "eu-central-1": "serverlessrepo.eu-central-1.amazonaws.com", "us-east-2": "serverlessrepo.us-east-2.amazonaws.com", "us-east-1": "serverlessrepo.us-east-1.amazonaws.com", "cn-northwest-1": "serverlessrepo.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "serverlessrepo.ap-south-1.amazonaws.com", "eu-north-1": "serverlessrepo.eu-north-1.amazonaws.com", "ap-northeast-2": "serverlessrepo.ap-northeast-2.amazonaws.com", "us-west-1": "serverlessrepo.us-west-1.amazonaws.com", "us-gov-east-1": "serverlessrepo.us-gov-east-1.amazonaws.com", "eu-west-3": "serverlessrepo.eu-west-3.amazonaws.com", "cn-north-1": "serverlessrepo.cn-north-1.amazonaws.com.cn", "sa-east-1": "serverlessrepo.sa-east-1.amazonaws.com", "eu-west-1": "serverlessrepo.eu-west-1.amazonaws.com", "us-gov-west-1": "serverlessrepo.us-gov-west-1.amazonaws.com", "ap-southeast-2": "serverlessrepo.ap-southeast-2.amazonaws.com", "ca-central-1": "serverlessrepo.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "serverlessrepo.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "serverlessrepo.ap-southeast-1.amazonaws.com",
      "us-west-2": "serverlessrepo.us-west-2.amazonaws.com",
      "eu-west-2": "serverlessrepo.eu-west-2.amazonaws.com",
      "ap-northeast-3": "serverlessrepo.ap-northeast-3.amazonaws.com",
      "eu-central-1": "serverlessrepo.eu-central-1.amazonaws.com",
      "us-east-2": "serverlessrepo.us-east-2.amazonaws.com",
      "us-east-1": "serverlessrepo.us-east-1.amazonaws.com",
      "cn-northwest-1": "serverlessrepo.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "serverlessrepo.ap-south-1.amazonaws.com",
      "eu-north-1": "serverlessrepo.eu-north-1.amazonaws.com",
      "ap-northeast-2": "serverlessrepo.ap-northeast-2.amazonaws.com",
      "us-west-1": "serverlessrepo.us-west-1.amazonaws.com",
      "us-gov-east-1": "serverlessrepo.us-gov-east-1.amazonaws.com",
      "eu-west-3": "serverlessrepo.eu-west-3.amazonaws.com",
      "cn-north-1": "serverlessrepo.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "serverlessrepo.sa-east-1.amazonaws.com",
      "eu-west-1": "serverlessrepo.eu-west-1.amazonaws.com",
      "us-gov-west-1": "serverlessrepo.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "serverlessrepo.ap-southeast-2.amazonaws.com",
      "ca-central-1": "serverlessrepo.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "serverlessrepo"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApplication_611255 = ref object of OpenApiRestCall_610658
proc url_CreateApplication_611257(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_611256(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_611258 = header.getOrDefault("X-Amz-Signature")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Signature", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Content-Sha256", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Date")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Date", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Credential")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Credential", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-Security-Token")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-Security-Token", valid_611262
  var valid_611263 = header.getOrDefault("X-Amz-Algorithm")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-Algorithm", valid_611263
  var valid_611264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611264 = validateParameter(valid_611264, JString, required = false,
                                 default = nil)
  if valid_611264 != nil:
    section.add "X-Amz-SignedHeaders", valid_611264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611266: Call_CreateApplication_611255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ## 
  let valid = call_611266.validator(path, query, header, formData, body)
  let scheme = call_611266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611266.url(scheme.get, call_611266.host, call_611266.base,
                         call_611266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611266, url, valid)

proc call*(call_611267: Call_CreateApplication_611255; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ##   body: JObject (required)
  var body_611268 = newJObject()
  if body != nil:
    body_611268 = body
  result = call_611267.call(nil, nil, nil, nil, body_611268)

var createApplication* = Call_CreateApplication_611255(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "serverlessrepo.amazonaws.com",
    route: "/applications", validator: validate_CreateApplication_611256, base: "/",
    url: url_CreateApplication_611257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_610996 = ref object of OpenApiRestCall_610658
proc url_ListApplications_610998(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplications_610997(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists applications owned by the requester.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token to specify where to start paginating.
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxItems: JInt
  ##           : The total number of items to return.
  section = newJObject()
  var valid_611110 = query.getOrDefault("nextToken")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "nextToken", valid_611110
  var valid_611111 = query.getOrDefault("MaxItems")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "MaxItems", valid_611111
  var valid_611112 = query.getOrDefault("NextToken")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "NextToken", valid_611112
  var valid_611113 = query.getOrDefault("maxItems")
  valid_611113 = validateParameter(valid_611113, JInt, required = false, default = nil)
  if valid_611113 != nil:
    section.add "maxItems", valid_611113
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
  var valid_611114 = header.getOrDefault("X-Amz-Signature")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Signature", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Content-Sha256", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Date")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Date", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Credential")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Credential", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-Security-Token")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-Security-Token", valid_611118
  var valid_611119 = header.getOrDefault("X-Amz-Algorithm")
  valid_611119 = validateParameter(valid_611119, JString, required = false,
                                 default = nil)
  if valid_611119 != nil:
    section.add "X-Amz-Algorithm", valid_611119
  var valid_611120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611120 = validateParameter(valid_611120, JString, required = false,
                                 default = nil)
  if valid_611120 != nil:
    section.add "X-Amz-SignedHeaders", valid_611120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611143: Call_ListApplications_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists applications owned by the requester.
  ## 
  let valid = call_611143.validator(path, query, header, formData, body)
  let scheme = call_611143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611143.url(scheme.get, call_611143.host, call_611143.base,
                         call_611143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611143, url, valid)

proc call*(call_611214: Call_ListApplications_610996; nextToken: string = "";
          MaxItems: string = ""; NextToken: string = ""; maxItems: int = 0): Recallable =
  ## listApplications
  ## Lists applications owned by the requester.
  ##   nextToken: string
  ##            : A token to specify where to start paginating.
  ##   MaxItems: string
  ##           : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxItems: int
  ##           : The total number of items to return.
  var query_611215 = newJObject()
  add(query_611215, "nextToken", newJString(nextToken))
  add(query_611215, "MaxItems", newJString(MaxItems))
  add(query_611215, "NextToken", newJString(NextToken))
  add(query_611215, "maxItems", newJInt(maxItems))
  result = call_611214.call(nil, query_611215, nil, nil, nil)

var listApplications* = Call_ListApplications_610996(name: "listApplications",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications", validator: validate_ListApplications_610997, base: "/",
    url: url_ListApplications_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplicationVersion_611269 = ref object of OpenApiRestCall_610658
proc url_CreateApplicationVersion_611271(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  assert "semanticVersion" in path, "`semanticVersion` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "semanticVersion")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApplicationVersion_611270(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an application version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   semanticVersion: JString (required)
  ##                  : The semantic version of the new version.
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `semanticVersion` field"
  var valid_611286 = path.getOrDefault("semanticVersion")
  valid_611286 = validateParameter(valid_611286, JString, required = true,
                                 default = nil)
  if valid_611286 != nil:
    section.add "semanticVersion", valid_611286
  var valid_611287 = path.getOrDefault("applicationId")
  valid_611287 = validateParameter(valid_611287, JString, required = true,
                                 default = nil)
  if valid_611287 != nil:
    section.add "applicationId", valid_611287
  result.add "path", section
  section = newJObject()
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
  var valid_611288 = header.getOrDefault("X-Amz-Signature")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Signature", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Content-Sha256", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Date")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Date", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Credential")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Credential", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Security-Token")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Security-Token", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Algorithm")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Algorithm", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-SignedHeaders", valid_611294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611296: Call_CreateApplicationVersion_611269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application version.
  ## 
  let valid = call_611296.validator(path, query, header, formData, body)
  let scheme = call_611296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611296.url(scheme.get, call_611296.host, call_611296.base,
                         call_611296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611296, url, valid)

proc call*(call_611297: Call_CreateApplicationVersion_611269; body: JsonNode;
          semanticVersion: string; applicationId: string): Recallable =
  ## createApplicationVersion
  ## Creates an application version.
  ##   body: JObject (required)
  ##   semanticVersion: string (required)
  ##                  : The semantic version of the new version.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611298 = newJObject()
  var body_611299 = newJObject()
  if body != nil:
    body_611299 = body
  add(path_611298, "semanticVersion", newJString(semanticVersion))
  add(path_611298, "applicationId", newJString(applicationId))
  result = call_611297.call(path_611298, nil, nil, nil, body_611299)

var createApplicationVersion* = Call_CreateApplicationVersion_611269(
    name: "createApplicationVersion", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions/{semanticVersion}",
    validator: validate_CreateApplicationVersion_611270, base: "/",
    url: url_CreateApplicationVersion_611271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationChangeSet_611300 = ref object of OpenApiRestCall_610658
proc url_CreateCloudFormationChangeSet_611302(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/changesets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateCloudFormationChangeSet_611301(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an AWS CloudFormation change set for the given application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `applicationId` field"
  var valid_611303 = path.getOrDefault("applicationId")
  valid_611303 = validateParameter(valid_611303, JString, required = true,
                                 default = nil)
  if valid_611303 != nil:
    section.add "applicationId", valid_611303
  result.add "path", section
  section = newJObject()
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
  var valid_611304 = header.getOrDefault("X-Amz-Signature")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Signature", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Content-Sha256", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Date")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Date", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Credential")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Credential", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Security-Token")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Security-Token", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Algorithm")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Algorithm", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-SignedHeaders", valid_611310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611312: Call_CreateCloudFormationChangeSet_611300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS CloudFormation change set for the given application.
  ## 
  let valid = call_611312.validator(path, query, header, formData, body)
  let scheme = call_611312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611312.url(scheme.get, call_611312.host, call_611312.base,
                         call_611312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611312, url, valid)

proc call*(call_611313: Call_CreateCloudFormationChangeSet_611300; body: JsonNode;
          applicationId: string): Recallable =
  ## createCloudFormationChangeSet
  ## Creates an AWS CloudFormation change set for the given application.
  ##   body: JObject (required)
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611314 = newJObject()
  var body_611315 = newJObject()
  if body != nil:
    body_611315 = body
  add(path_611314, "applicationId", newJString(applicationId))
  result = call_611313.call(path_611314, nil, nil, nil, body_611315)

var createCloudFormationChangeSet* = Call_CreateCloudFormationChangeSet_611300(
    name: "createCloudFormationChangeSet", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/changesets",
    validator: validate_CreateCloudFormationChangeSet_611301, base: "/",
    url: url_CreateCloudFormationChangeSet_611302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationTemplate_611316 = ref object of OpenApiRestCall_610658
proc url_CreateCloudFormationTemplate_611318(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/templates")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateCloudFormationTemplate_611317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an AWS CloudFormation template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `applicationId` field"
  var valid_611319 = path.getOrDefault("applicationId")
  valid_611319 = validateParameter(valid_611319, JString, required = true,
                                 default = nil)
  if valid_611319 != nil:
    section.add "applicationId", valid_611319
  result.add "path", section
  section = newJObject()
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
  var valid_611320 = header.getOrDefault("X-Amz-Signature")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Signature", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Content-Sha256", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Date")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Date", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Credential")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Credential", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Security-Token")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Security-Token", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Algorithm")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Algorithm", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-SignedHeaders", valid_611326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611328: Call_CreateCloudFormationTemplate_611316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS CloudFormation template.
  ## 
  let valid = call_611328.validator(path, query, header, formData, body)
  let scheme = call_611328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611328.url(scheme.get, call_611328.host, call_611328.base,
                         call_611328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611328, url, valid)

proc call*(call_611329: Call_CreateCloudFormationTemplate_611316; body: JsonNode;
          applicationId: string): Recallable =
  ## createCloudFormationTemplate
  ## Creates an AWS CloudFormation template.
  ##   body: JObject (required)
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611330 = newJObject()
  var body_611331 = newJObject()
  if body != nil:
    body_611331 = body
  add(path_611330, "applicationId", newJString(applicationId))
  result = call_611329.call(path_611330, nil, nil, nil, body_611331)

var createCloudFormationTemplate* = Call_CreateCloudFormationTemplate_611316(
    name: "createCloudFormationTemplate", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates",
    validator: validate_CreateCloudFormationTemplate_611317, base: "/",
    url: url_CreateCloudFormationTemplate_611318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_611332 = ref object of OpenApiRestCall_610658
proc url_GetApplication_611334(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApplication_611333(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets the specified application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `applicationId` field"
  var valid_611335 = path.getOrDefault("applicationId")
  valid_611335 = validateParameter(valid_611335, JString, required = true,
                                 default = nil)
  if valid_611335 != nil:
    section.add "applicationId", valid_611335
  result.add "path", section
  ## parameters in `query` object:
  ##   semanticVersion: JString
  ##                  : The semantic version of the application to get.
  section = newJObject()
  var valid_611336 = query.getOrDefault("semanticVersion")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "semanticVersion", valid_611336
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
  var valid_611337 = header.getOrDefault("X-Amz-Signature")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Signature", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Content-Sha256", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Date")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Date", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Credential")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Credential", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Security-Token")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Security-Token", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Algorithm")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Algorithm", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-SignedHeaders", valid_611343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611344: Call_GetApplication_611332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified application.
  ## 
  let valid = call_611344.validator(path, query, header, formData, body)
  let scheme = call_611344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611344.url(scheme.get, call_611344.host, call_611344.base,
                         call_611344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611344, url, valid)

proc call*(call_611345: Call_GetApplication_611332; applicationId: string;
          semanticVersion: string = ""): Recallable =
  ## getApplication
  ## Gets the specified application.
  ##   semanticVersion: string
  ##                  : The semantic version of the application to get.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611346 = newJObject()
  var query_611347 = newJObject()
  add(query_611347, "semanticVersion", newJString(semanticVersion))
  add(path_611346, "applicationId", newJString(applicationId))
  result = call_611345.call(path_611346, query_611347, nil, nil, nil)

var getApplication* = Call_GetApplication_611332(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_GetApplication_611333,
    base: "/", url: url_GetApplication_611334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_611362 = ref object of OpenApiRestCall_610658
proc url_UpdateApplication_611364(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApplication_611363(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates the specified application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `applicationId` field"
  var valid_611365 = path.getOrDefault("applicationId")
  valid_611365 = validateParameter(valid_611365, JString, required = true,
                                 default = nil)
  if valid_611365 != nil:
    section.add "applicationId", valid_611365
  result.add "path", section
  section = newJObject()
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
  var valid_611366 = header.getOrDefault("X-Amz-Signature")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Signature", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Content-Sha256", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Date")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Date", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Credential")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Credential", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Security-Token")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Security-Token", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Algorithm")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Algorithm", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-SignedHeaders", valid_611372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611374: Call_UpdateApplication_611362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified application.
  ## 
  let valid = call_611374.validator(path, query, header, formData, body)
  let scheme = call_611374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611374.url(scheme.get, call_611374.host, call_611374.base,
                         call_611374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611374, url, valid)

proc call*(call_611375: Call_UpdateApplication_611362; body: JsonNode;
          applicationId: string): Recallable =
  ## updateApplication
  ## Updates the specified application.
  ##   body: JObject (required)
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611376 = newJObject()
  var body_611377 = newJObject()
  if body != nil:
    body_611377 = body
  add(path_611376, "applicationId", newJString(applicationId))
  result = call_611375.call(path_611376, nil, nil, nil, body_611377)

var updateApplication* = Call_UpdateApplication_611362(name: "updateApplication",
    meth: HttpMethod.HttpPatch, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_UpdateApplication_611363,
    base: "/", url: url_UpdateApplication_611364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_611348 = ref object of OpenApiRestCall_610658
proc url_DeleteApplication_611350(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApplication_611349(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes the specified application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `applicationId` field"
  var valid_611351 = path.getOrDefault("applicationId")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "applicationId", valid_611351
  result.add "path", section
  section = newJObject()
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
  var valid_611352 = header.getOrDefault("X-Amz-Signature")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Signature", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Content-Sha256", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Date")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Date", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Credential")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Credential", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Security-Token")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Security-Token", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Algorithm")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Algorithm", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-SignedHeaders", valid_611358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611359: Call_DeleteApplication_611348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified application.
  ## 
  let valid = call_611359.validator(path, query, header, formData, body)
  let scheme = call_611359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611359.url(scheme.get, call_611359.host, call_611359.base,
                         call_611359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611359, url, valid)

proc call*(call_611360: Call_DeleteApplication_611348; applicationId: string): Recallable =
  ## deleteApplication
  ## Deletes the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611361 = newJObject()
  add(path_611361, "applicationId", newJString(applicationId))
  result = call_611360.call(path_611361, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_611348(name: "deleteApplication",
    meth: HttpMethod.HttpDelete, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_DeleteApplication_611349,
    base: "/", url: url_DeleteApplication_611350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApplicationPolicy_611392 = ref object of OpenApiRestCall_610658
proc url_PutApplicationPolicy_611394(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutApplicationPolicy_611393(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `applicationId` field"
  var valid_611395 = path.getOrDefault("applicationId")
  valid_611395 = validateParameter(valid_611395, JString, required = true,
                                 default = nil)
  if valid_611395 != nil:
    section.add "applicationId", valid_611395
  result.add "path", section
  section = newJObject()
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
  var valid_611396 = header.getOrDefault("X-Amz-Signature")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Signature", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Content-Sha256", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Date")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Date", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Credential")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Credential", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Security-Token")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Security-Token", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Algorithm")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Algorithm", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-SignedHeaders", valid_611402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611404: Call_PutApplicationPolicy_611392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ## 
  let valid = call_611404.validator(path, query, header, formData, body)
  let scheme = call_611404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611404.url(scheme.get, call_611404.host, call_611404.base,
                         call_611404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611404, url, valid)

proc call*(call_611405: Call_PutApplicationPolicy_611392; body: JsonNode;
          applicationId: string): Recallable =
  ## putApplicationPolicy
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ##   body: JObject (required)
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611406 = newJObject()
  var body_611407 = newJObject()
  if body != nil:
    body_611407 = body
  add(path_611406, "applicationId", newJString(applicationId))
  result = call_611405.call(path_611406, nil, nil, nil, body_611407)

var putApplicationPolicy* = Call_PutApplicationPolicy_611392(
    name: "putApplicationPolicy", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_PutApplicationPolicy_611393, base: "/",
    url: url_PutApplicationPolicy_611394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationPolicy_611378 = ref object of OpenApiRestCall_610658
proc url_GetApplicationPolicy_611380(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApplicationPolicy_611379(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the policy for the application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `applicationId` field"
  var valid_611381 = path.getOrDefault("applicationId")
  valid_611381 = validateParameter(valid_611381, JString, required = true,
                                 default = nil)
  if valid_611381 != nil:
    section.add "applicationId", valid_611381
  result.add "path", section
  section = newJObject()
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
  var valid_611382 = header.getOrDefault("X-Amz-Signature")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Signature", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Content-Sha256", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Date")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Date", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Credential")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Credential", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Security-Token")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Security-Token", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Algorithm")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Algorithm", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-SignedHeaders", valid_611388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611389: Call_GetApplicationPolicy_611378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy for the application.
  ## 
  let valid = call_611389.validator(path, query, header, formData, body)
  let scheme = call_611389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611389.url(scheme.get, call_611389.host, call_611389.base,
                         call_611389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611389, url, valid)

proc call*(call_611390: Call_GetApplicationPolicy_611378; applicationId: string): Recallable =
  ## getApplicationPolicy
  ## Retrieves the policy for the application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611391 = newJObject()
  add(path_611391, "applicationId", newJString(applicationId))
  result = call_611390.call(path_611391, nil, nil, nil, nil)

var getApplicationPolicy* = Call_GetApplicationPolicy_611378(
    name: "getApplicationPolicy", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_GetApplicationPolicy_611379, base: "/",
    url: url_GetApplicationPolicy_611380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationTemplate_611408 = ref object of OpenApiRestCall_610658
proc url_GetCloudFormationTemplate_611410(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  assert "templateId" in path, "`templateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "templateId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFormationTemplate_611409(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the specified AWS CloudFormation template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   templateId: JString (required)
  ##             : <p>The UUID returned by CreateCloudFormationTemplate.</p><p>Pattern: 
  ## [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}</p>
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `templateId` field"
  var valid_611411 = path.getOrDefault("templateId")
  valid_611411 = validateParameter(valid_611411, JString, required = true,
                                 default = nil)
  if valid_611411 != nil:
    section.add "templateId", valid_611411
  var valid_611412 = path.getOrDefault("applicationId")
  valid_611412 = validateParameter(valid_611412, JString, required = true,
                                 default = nil)
  if valid_611412 != nil:
    section.add "applicationId", valid_611412
  result.add "path", section
  section = newJObject()
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
  var valid_611413 = header.getOrDefault("X-Amz-Signature")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Signature", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Content-Sha256", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Date")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Date", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Credential")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Credential", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Security-Token")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Security-Token", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Algorithm")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Algorithm", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-SignedHeaders", valid_611419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611420: Call_GetCloudFormationTemplate_611408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified AWS CloudFormation template.
  ## 
  let valid = call_611420.validator(path, query, header, formData, body)
  let scheme = call_611420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611420.url(scheme.get, call_611420.host, call_611420.base,
                         call_611420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611420, url, valid)

proc call*(call_611421: Call_GetCloudFormationTemplate_611408; templateId: string;
          applicationId: string): Recallable =
  ## getCloudFormationTemplate
  ## Gets the specified AWS CloudFormation template.
  ##   templateId: string (required)
  ##             : <p>The UUID returned by CreateCloudFormationTemplate.</p><p>Pattern: 
  ## [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}</p>
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611422 = newJObject()
  add(path_611422, "templateId", newJString(templateId))
  add(path_611422, "applicationId", newJString(applicationId))
  result = call_611421.call(path_611422, nil, nil, nil, nil)

var getCloudFormationTemplate* = Call_GetCloudFormationTemplate_611408(
    name: "getCloudFormationTemplate", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates/{templateId}",
    validator: validate_GetCloudFormationTemplate_611409, base: "/",
    url: url_GetCloudFormationTemplate_611410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationDependencies_611423 = ref object of OpenApiRestCall_610658
proc url_ListApplicationDependencies_611425(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/dependencies")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListApplicationDependencies_611424(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the list of applications nested in the containing application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `applicationId` field"
  var valid_611426 = path.getOrDefault("applicationId")
  valid_611426 = validateParameter(valid_611426, JString, required = true,
                                 default = nil)
  if valid_611426 != nil:
    section.add "applicationId", valid_611426
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token to specify where to start paginating.
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxItems: JInt
  ##           : The total number of items to return.
  ##   semanticVersion: JString
  ##                  : The semantic version of the application to get.
  section = newJObject()
  var valid_611427 = query.getOrDefault("nextToken")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "nextToken", valid_611427
  var valid_611428 = query.getOrDefault("MaxItems")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "MaxItems", valid_611428
  var valid_611429 = query.getOrDefault("NextToken")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "NextToken", valid_611429
  var valid_611430 = query.getOrDefault("maxItems")
  valid_611430 = validateParameter(valid_611430, JInt, required = false, default = nil)
  if valid_611430 != nil:
    section.add "maxItems", valid_611430
  var valid_611431 = query.getOrDefault("semanticVersion")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "semanticVersion", valid_611431
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
  var valid_611432 = header.getOrDefault("X-Amz-Signature")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Signature", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Content-Sha256", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Date")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Date", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Credential")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Credential", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Security-Token")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Security-Token", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Algorithm")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Algorithm", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-SignedHeaders", valid_611438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611439: Call_ListApplicationDependencies_611423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the list of applications nested in the containing application.
  ## 
  let valid = call_611439.validator(path, query, header, formData, body)
  let scheme = call_611439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611439.url(scheme.get, call_611439.host, call_611439.base,
                         call_611439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611439, url, valid)

proc call*(call_611440: Call_ListApplicationDependencies_611423;
          applicationId: string; nextToken: string = ""; MaxItems: string = "";
          NextToken: string = ""; maxItems: int = 0; semanticVersion: string = ""): Recallable =
  ## listApplicationDependencies
  ## Retrieves the list of applications nested in the containing application.
  ##   nextToken: string
  ##            : A token to specify where to start paginating.
  ##   MaxItems: string
  ##           : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxItems: int
  ##           : The total number of items to return.
  ##   semanticVersion: string
  ##                  : The semantic version of the application to get.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611441 = newJObject()
  var query_611442 = newJObject()
  add(query_611442, "nextToken", newJString(nextToken))
  add(query_611442, "MaxItems", newJString(MaxItems))
  add(query_611442, "NextToken", newJString(NextToken))
  add(query_611442, "maxItems", newJInt(maxItems))
  add(query_611442, "semanticVersion", newJString(semanticVersion))
  add(path_611441, "applicationId", newJString(applicationId))
  result = call_611440.call(path_611441, query_611442, nil, nil, nil)

var listApplicationDependencies* = Call_ListApplicationDependencies_611423(
    name: "listApplicationDependencies", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/dependencies",
    validator: validate_ListApplicationDependencies_611424, base: "/",
    url: url_ListApplicationDependencies_611425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationVersions_611443 = ref object of OpenApiRestCall_610658
proc url_ListApplicationVersions_611445(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListApplicationVersions_611444(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists versions for the specified application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `applicationId` field"
  var valid_611446 = path.getOrDefault("applicationId")
  valid_611446 = validateParameter(valid_611446, JString, required = true,
                                 default = nil)
  if valid_611446 != nil:
    section.add "applicationId", valid_611446
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token to specify where to start paginating.
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxItems: JInt
  ##           : The total number of items to return.
  section = newJObject()
  var valid_611447 = query.getOrDefault("nextToken")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "nextToken", valid_611447
  var valid_611448 = query.getOrDefault("MaxItems")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "MaxItems", valid_611448
  var valid_611449 = query.getOrDefault("NextToken")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "NextToken", valid_611449
  var valid_611450 = query.getOrDefault("maxItems")
  valid_611450 = validateParameter(valid_611450, JInt, required = false, default = nil)
  if valid_611450 != nil:
    section.add "maxItems", valid_611450
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
  var valid_611451 = header.getOrDefault("X-Amz-Signature")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Signature", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Content-Sha256", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Date")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Date", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Credential")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Credential", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Security-Token")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Security-Token", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Algorithm")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Algorithm", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-SignedHeaders", valid_611457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611458: Call_ListApplicationVersions_611443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists versions for the specified application.
  ## 
  let valid = call_611458.validator(path, query, header, formData, body)
  let scheme = call_611458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611458.url(scheme.get, call_611458.host, call_611458.base,
                         call_611458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611458, url, valid)

proc call*(call_611459: Call_ListApplicationVersions_611443; applicationId: string;
          nextToken: string = ""; MaxItems: string = ""; NextToken: string = "";
          maxItems: int = 0): Recallable =
  ## listApplicationVersions
  ## Lists versions for the specified application.
  ##   nextToken: string
  ##            : A token to specify where to start paginating.
  ##   MaxItems: string
  ##           : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxItems: int
  ##           : The total number of items to return.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_611460 = newJObject()
  var query_611461 = newJObject()
  add(query_611461, "nextToken", newJString(nextToken))
  add(query_611461, "MaxItems", newJString(MaxItems))
  add(query_611461, "NextToken", newJString(NextToken))
  add(query_611461, "maxItems", newJInt(maxItems))
  add(path_611460, "applicationId", newJString(applicationId))
  result = call_611459.call(path_611460, query_611461, nil, nil, nil)

var listApplicationVersions* = Call_ListApplicationVersions_611443(
    name: "listApplicationVersions", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions",
    validator: validate_ListApplicationVersions_611444, base: "/",
    url: url_ListApplicationVersions_611445, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
