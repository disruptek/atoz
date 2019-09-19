
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateApplication_773192 = ref object of OpenApiRestCall_772597
proc url_CreateApplication_773194(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApplication_773193(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773195 = header.getOrDefault("X-Amz-Date")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Date", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-Security-Token")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Security-Token", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Content-Sha256", valid_773197
  var valid_773198 = header.getOrDefault("X-Amz-Algorithm")
  valid_773198 = validateParameter(valid_773198, JString, required = false,
                                 default = nil)
  if valid_773198 != nil:
    section.add "X-Amz-Algorithm", valid_773198
  var valid_773199 = header.getOrDefault("X-Amz-Signature")
  valid_773199 = validateParameter(valid_773199, JString, required = false,
                                 default = nil)
  if valid_773199 != nil:
    section.add "X-Amz-Signature", valid_773199
  var valid_773200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773200 = validateParameter(valid_773200, JString, required = false,
                                 default = nil)
  if valid_773200 != nil:
    section.add "X-Amz-SignedHeaders", valid_773200
  var valid_773201 = header.getOrDefault("X-Amz-Credential")
  valid_773201 = validateParameter(valid_773201, JString, required = false,
                                 default = nil)
  if valid_773201 != nil:
    section.add "X-Amz-Credential", valid_773201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773203: Call_CreateApplication_773192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ## 
  let valid = call_773203.validator(path, query, header, formData, body)
  let scheme = call_773203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773203.url(scheme.get, call_773203.host, call_773203.base,
                         call_773203.route, valid.getOrDefault("path"))
  result = hook(call_773203, url, valid)

proc call*(call_773204: Call_CreateApplication_773192; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ##   body: JObject (required)
  var body_773205 = newJObject()
  if body != nil:
    body_773205 = body
  result = call_773204.call(nil, nil, nil, nil, body_773205)

var createApplication* = Call_CreateApplication_773192(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "serverlessrepo.amazonaws.com",
    route: "/applications", validator: validate_CreateApplication_773193, base: "/",
    url: url_CreateApplication_773194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_772933 = ref object of OpenApiRestCall_772597
proc url_ListApplications_772935(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListApplications_772934(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists applications owned by the requester.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   nextToken: JString
  ##            : A token to specify where to start paginating.
  ##   maxItems: JInt
  ##           : The total number of items to return.
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_773047 = query.getOrDefault("NextToken")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "NextToken", valid_773047
  var valid_773048 = query.getOrDefault("nextToken")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "nextToken", valid_773048
  var valid_773049 = query.getOrDefault("maxItems")
  valid_773049 = validateParameter(valid_773049, JInt, required = false, default = nil)
  if valid_773049 != nil:
    section.add "maxItems", valid_773049
  var valid_773050 = query.getOrDefault("MaxItems")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "MaxItems", valid_773050
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
  var valid_773051 = header.getOrDefault("X-Amz-Date")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Date", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-Security-Token")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-Security-Token", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Content-Sha256", valid_773053
  var valid_773054 = header.getOrDefault("X-Amz-Algorithm")
  valid_773054 = validateParameter(valid_773054, JString, required = false,
                                 default = nil)
  if valid_773054 != nil:
    section.add "X-Amz-Algorithm", valid_773054
  var valid_773055 = header.getOrDefault("X-Amz-Signature")
  valid_773055 = validateParameter(valid_773055, JString, required = false,
                                 default = nil)
  if valid_773055 != nil:
    section.add "X-Amz-Signature", valid_773055
  var valid_773056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773056 = validateParameter(valid_773056, JString, required = false,
                                 default = nil)
  if valid_773056 != nil:
    section.add "X-Amz-SignedHeaders", valid_773056
  var valid_773057 = header.getOrDefault("X-Amz-Credential")
  valid_773057 = validateParameter(valid_773057, JString, required = false,
                                 default = nil)
  if valid_773057 != nil:
    section.add "X-Amz-Credential", valid_773057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773080: Call_ListApplications_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists applications owned by the requester.
  ## 
  let valid = call_773080.validator(path, query, header, formData, body)
  let scheme = call_773080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773080.url(scheme.get, call_773080.host, call_773080.base,
                         call_773080.route, valid.getOrDefault("path"))
  result = hook(call_773080, url, valid)

proc call*(call_773151: Call_ListApplications_772933; NextToken: string = "";
          nextToken: string = ""; maxItems: int = 0; MaxItems: string = ""): Recallable =
  ## listApplications
  ## Lists applications owned by the requester.
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to specify where to start paginating.
  ##   maxItems: int
  ##           : The total number of items to return.
  ##   MaxItems: string
  ##           : Pagination limit
  var query_773152 = newJObject()
  add(query_773152, "NextToken", newJString(NextToken))
  add(query_773152, "nextToken", newJString(nextToken))
  add(query_773152, "maxItems", newJInt(maxItems))
  add(query_773152, "MaxItems", newJString(MaxItems))
  result = call_773151.call(nil, query_773152, nil, nil, nil)

var listApplications* = Call_ListApplications_772933(name: "listApplications",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications", validator: validate_ListApplications_772934, base: "/",
    url: url_ListApplications_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplicationVersion_773206 = ref object of OpenApiRestCall_772597
proc url_CreateApplicationVersion_773208(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateApplicationVersion_773207(path: JsonNode; query: JsonNode;
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
  var valid_773223 = path.getOrDefault("semanticVersion")
  valid_773223 = validateParameter(valid_773223, JString, required = true,
                                 default = nil)
  if valid_773223 != nil:
    section.add "semanticVersion", valid_773223
  var valid_773224 = path.getOrDefault("applicationId")
  valid_773224 = validateParameter(valid_773224, JString, required = true,
                                 default = nil)
  if valid_773224 != nil:
    section.add "applicationId", valid_773224
  result.add "path", section
  section = newJObject()
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
  var valid_773225 = header.getOrDefault("X-Amz-Date")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Date", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Security-Token")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Security-Token", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Content-Sha256", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Algorithm")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Algorithm", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Signature")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Signature", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-SignedHeaders", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Credential")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Credential", valid_773231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773233: Call_CreateApplicationVersion_773206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application version.
  ## 
  let valid = call_773233.validator(path, query, header, formData, body)
  let scheme = call_773233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773233.url(scheme.get, call_773233.host, call_773233.base,
                         call_773233.route, valid.getOrDefault("path"))
  result = hook(call_773233, url, valid)

proc call*(call_773234: Call_CreateApplicationVersion_773206;
          semanticVersion: string; applicationId: string; body: JsonNode): Recallable =
  ## createApplicationVersion
  ## Creates an application version.
  ##   semanticVersion: string (required)
  ##                  : The semantic version of the new version.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_773235 = newJObject()
  var body_773236 = newJObject()
  add(path_773235, "semanticVersion", newJString(semanticVersion))
  add(path_773235, "applicationId", newJString(applicationId))
  if body != nil:
    body_773236 = body
  result = call_773234.call(path_773235, nil, nil, nil, body_773236)

var createApplicationVersion* = Call_CreateApplicationVersion_773206(
    name: "createApplicationVersion", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions/{semanticVersion}",
    validator: validate_CreateApplicationVersion_773207, base: "/",
    url: url_CreateApplicationVersion_773208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationChangeSet_773237 = ref object of OpenApiRestCall_772597
proc url_CreateCloudFormationChangeSet_773239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/changesets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateCloudFormationChangeSet_773238(path: JsonNode; query: JsonNode;
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
  var valid_773240 = path.getOrDefault("applicationId")
  valid_773240 = validateParameter(valid_773240, JString, required = true,
                                 default = nil)
  if valid_773240 != nil:
    section.add "applicationId", valid_773240
  result.add "path", section
  section = newJObject()
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
  var valid_773241 = header.getOrDefault("X-Amz-Date")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Date", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Security-Token")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Security-Token", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Content-Sha256", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-Algorithm")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-Algorithm", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-Signature")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Signature", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-SignedHeaders", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Credential")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Credential", valid_773247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773249: Call_CreateCloudFormationChangeSet_773237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS CloudFormation change set for the given application.
  ## 
  let valid = call_773249.validator(path, query, header, formData, body)
  let scheme = call_773249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773249.url(scheme.get, call_773249.host, call_773249.base,
                         call_773249.route, valid.getOrDefault("path"))
  result = hook(call_773249, url, valid)

proc call*(call_773250: Call_CreateCloudFormationChangeSet_773237;
          applicationId: string; body: JsonNode): Recallable =
  ## createCloudFormationChangeSet
  ## Creates an AWS CloudFormation change set for the given application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_773251 = newJObject()
  var body_773252 = newJObject()
  add(path_773251, "applicationId", newJString(applicationId))
  if body != nil:
    body_773252 = body
  result = call_773250.call(path_773251, nil, nil, nil, body_773252)

var createCloudFormationChangeSet* = Call_CreateCloudFormationChangeSet_773237(
    name: "createCloudFormationChangeSet", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/changesets",
    validator: validate_CreateCloudFormationChangeSet_773238, base: "/",
    url: url_CreateCloudFormationChangeSet_773239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationTemplate_773253 = ref object of OpenApiRestCall_772597
proc url_CreateCloudFormationTemplate_773255(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/templates")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateCloudFormationTemplate_773254(path: JsonNode; query: JsonNode;
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
  var valid_773256 = path.getOrDefault("applicationId")
  valid_773256 = validateParameter(valid_773256, JString, required = true,
                                 default = nil)
  if valid_773256 != nil:
    section.add "applicationId", valid_773256
  result.add "path", section
  section = newJObject()
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
  var valid_773257 = header.getOrDefault("X-Amz-Date")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Date", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Security-Token")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Security-Token", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Content-Sha256", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Algorithm")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Algorithm", valid_773260
  var valid_773261 = header.getOrDefault("X-Amz-Signature")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Signature", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-SignedHeaders", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Credential")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Credential", valid_773263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773265: Call_CreateCloudFormationTemplate_773253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS CloudFormation template.
  ## 
  let valid = call_773265.validator(path, query, header, formData, body)
  let scheme = call_773265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773265.url(scheme.get, call_773265.host, call_773265.base,
                         call_773265.route, valid.getOrDefault("path"))
  result = hook(call_773265, url, valid)

proc call*(call_773266: Call_CreateCloudFormationTemplate_773253;
          applicationId: string; body: JsonNode): Recallable =
  ## createCloudFormationTemplate
  ## Creates an AWS CloudFormation template.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_773267 = newJObject()
  var body_773268 = newJObject()
  add(path_773267, "applicationId", newJString(applicationId))
  if body != nil:
    body_773268 = body
  result = call_773266.call(path_773267, nil, nil, nil, body_773268)

var createCloudFormationTemplate* = Call_CreateCloudFormationTemplate_773253(
    name: "createCloudFormationTemplate", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates",
    validator: validate_CreateCloudFormationTemplate_773254, base: "/",
    url: url_CreateCloudFormationTemplate_773255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_773269 = ref object of OpenApiRestCall_772597
proc url_GetApplication_773271(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApplication_773270(path: JsonNode; query: JsonNode;
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
  var valid_773272 = path.getOrDefault("applicationId")
  valid_773272 = validateParameter(valid_773272, JString, required = true,
                                 default = nil)
  if valid_773272 != nil:
    section.add "applicationId", valid_773272
  result.add "path", section
  ## parameters in `query` object:
  ##   semanticVersion: JString
  ##                  : The semantic version of the application to get.
  section = newJObject()
  var valid_773273 = query.getOrDefault("semanticVersion")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "semanticVersion", valid_773273
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
  var valid_773274 = header.getOrDefault("X-Amz-Date")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Date", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-Security-Token")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Security-Token", valid_773275
  var valid_773276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Content-Sha256", valid_773276
  var valid_773277 = header.getOrDefault("X-Amz-Algorithm")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-Algorithm", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Signature")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Signature", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-SignedHeaders", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Credential")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Credential", valid_773280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773281: Call_GetApplication_773269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified application.
  ## 
  let valid = call_773281.validator(path, query, header, formData, body)
  let scheme = call_773281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773281.url(scheme.get, call_773281.host, call_773281.base,
                         call_773281.route, valid.getOrDefault("path"))
  result = hook(call_773281, url, valid)

proc call*(call_773282: Call_GetApplication_773269; applicationId: string;
          semanticVersion: string = ""): Recallable =
  ## getApplication
  ## Gets the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   semanticVersion: string
  ##                  : The semantic version of the application to get.
  var path_773283 = newJObject()
  var query_773284 = newJObject()
  add(path_773283, "applicationId", newJString(applicationId))
  add(query_773284, "semanticVersion", newJString(semanticVersion))
  result = call_773282.call(path_773283, query_773284, nil, nil, nil)

var getApplication* = Call_GetApplication_773269(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_GetApplication_773270,
    base: "/", url: url_GetApplication_773271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_773299 = ref object of OpenApiRestCall_772597
proc url_UpdateApplication_773301(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateApplication_773300(path: JsonNode; query: JsonNode;
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
  var valid_773302 = path.getOrDefault("applicationId")
  valid_773302 = validateParameter(valid_773302, JString, required = true,
                                 default = nil)
  if valid_773302 != nil:
    section.add "applicationId", valid_773302
  result.add "path", section
  section = newJObject()
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
  var valid_773303 = header.getOrDefault("X-Amz-Date")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Date", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-Security-Token")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Security-Token", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Content-Sha256", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Algorithm")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Algorithm", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Signature")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Signature", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-SignedHeaders", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Credential")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Credential", valid_773309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773311: Call_UpdateApplication_773299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified application.
  ## 
  let valid = call_773311.validator(path, query, header, formData, body)
  let scheme = call_773311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773311.url(scheme.get, call_773311.host, call_773311.base,
                         call_773311.route, valid.getOrDefault("path"))
  result = hook(call_773311, url, valid)

proc call*(call_773312: Call_UpdateApplication_773299; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApplication
  ## Updates the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_773313 = newJObject()
  var body_773314 = newJObject()
  add(path_773313, "applicationId", newJString(applicationId))
  if body != nil:
    body_773314 = body
  result = call_773312.call(path_773313, nil, nil, nil, body_773314)

var updateApplication* = Call_UpdateApplication_773299(name: "updateApplication",
    meth: HttpMethod.HttpPatch, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_UpdateApplication_773300,
    base: "/", url: url_UpdateApplication_773301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_773285 = ref object of OpenApiRestCall_772597
proc url_DeleteApplication_773287(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteApplication_773286(path: JsonNode; query: JsonNode;
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
  var valid_773288 = path.getOrDefault("applicationId")
  valid_773288 = validateParameter(valid_773288, JString, required = true,
                                 default = nil)
  if valid_773288 != nil:
    section.add "applicationId", valid_773288
  result.add "path", section
  section = newJObject()
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
  var valid_773289 = header.getOrDefault("X-Amz-Date")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Date", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Security-Token")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Security-Token", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Content-Sha256", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Algorithm")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Algorithm", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Signature")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Signature", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-SignedHeaders", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Credential")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Credential", valid_773295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773296: Call_DeleteApplication_773285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified application.
  ## 
  let valid = call_773296.validator(path, query, header, formData, body)
  let scheme = call_773296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773296.url(scheme.get, call_773296.host, call_773296.base,
                         call_773296.route, valid.getOrDefault("path"))
  result = hook(call_773296, url, valid)

proc call*(call_773297: Call_DeleteApplication_773285; applicationId: string): Recallable =
  ## deleteApplication
  ## Deletes the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_773298 = newJObject()
  add(path_773298, "applicationId", newJString(applicationId))
  result = call_773297.call(path_773298, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_773285(name: "deleteApplication",
    meth: HttpMethod.HttpDelete, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_DeleteApplication_773286,
    base: "/", url: url_DeleteApplication_773287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApplicationPolicy_773329 = ref object of OpenApiRestCall_772597
proc url_PutApplicationPolicy_773331(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutApplicationPolicy_773330(path: JsonNode; query: JsonNode;
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
  var valid_773332 = path.getOrDefault("applicationId")
  valid_773332 = validateParameter(valid_773332, JString, required = true,
                                 default = nil)
  if valid_773332 != nil:
    section.add "applicationId", valid_773332
  result.add "path", section
  section = newJObject()
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
  var valid_773333 = header.getOrDefault("X-Amz-Date")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Date", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-Security-Token")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-Security-Token", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Content-Sha256", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Algorithm")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Algorithm", valid_773336
  var valid_773337 = header.getOrDefault("X-Amz-Signature")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Signature", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-SignedHeaders", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Credential")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Credential", valid_773339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773341: Call_PutApplicationPolicy_773329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ## 
  let valid = call_773341.validator(path, query, header, formData, body)
  let scheme = call_773341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773341.url(scheme.get, call_773341.host, call_773341.base,
                         call_773341.route, valid.getOrDefault("path"))
  result = hook(call_773341, url, valid)

proc call*(call_773342: Call_PutApplicationPolicy_773329; applicationId: string;
          body: JsonNode): Recallable =
  ## putApplicationPolicy
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_773343 = newJObject()
  var body_773344 = newJObject()
  add(path_773343, "applicationId", newJString(applicationId))
  if body != nil:
    body_773344 = body
  result = call_773342.call(path_773343, nil, nil, nil, body_773344)

var putApplicationPolicy* = Call_PutApplicationPolicy_773329(
    name: "putApplicationPolicy", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_PutApplicationPolicy_773330, base: "/",
    url: url_PutApplicationPolicy_773331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationPolicy_773315 = ref object of OpenApiRestCall_772597
proc url_GetApplicationPolicy_773317(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApplicationPolicy_773316(path: JsonNode; query: JsonNode;
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
  var valid_773318 = path.getOrDefault("applicationId")
  valid_773318 = validateParameter(valid_773318, JString, required = true,
                                 default = nil)
  if valid_773318 != nil:
    section.add "applicationId", valid_773318
  result.add "path", section
  section = newJObject()
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
  var valid_773319 = header.getOrDefault("X-Amz-Date")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-Date", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Security-Token")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Security-Token", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-Content-Sha256", valid_773321
  var valid_773322 = header.getOrDefault("X-Amz-Algorithm")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Algorithm", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-Signature")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Signature", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-SignedHeaders", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Credential")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Credential", valid_773325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773326: Call_GetApplicationPolicy_773315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy for the application.
  ## 
  let valid = call_773326.validator(path, query, header, formData, body)
  let scheme = call_773326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773326.url(scheme.get, call_773326.host, call_773326.base,
                         call_773326.route, valid.getOrDefault("path"))
  result = hook(call_773326, url, valid)

proc call*(call_773327: Call_GetApplicationPolicy_773315; applicationId: string): Recallable =
  ## getApplicationPolicy
  ## Retrieves the policy for the application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_773328 = newJObject()
  add(path_773328, "applicationId", newJString(applicationId))
  result = call_773327.call(path_773328, nil, nil, nil, nil)

var getApplicationPolicy* = Call_GetApplicationPolicy_773315(
    name: "getApplicationPolicy", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_GetApplicationPolicy_773316, base: "/",
    url: url_GetApplicationPolicy_773317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationTemplate_773345 = ref object of OpenApiRestCall_772597
proc url_GetCloudFormationTemplate_773347(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCloudFormationTemplate_773346(path: JsonNode; query: JsonNode;
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
  var valid_773348 = path.getOrDefault("templateId")
  valid_773348 = validateParameter(valid_773348, JString, required = true,
                                 default = nil)
  if valid_773348 != nil:
    section.add "templateId", valid_773348
  var valid_773349 = path.getOrDefault("applicationId")
  valid_773349 = validateParameter(valid_773349, JString, required = true,
                                 default = nil)
  if valid_773349 != nil:
    section.add "applicationId", valid_773349
  result.add "path", section
  section = newJObject()
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
  var valid_773350 = header.getOrDefault("X-Amz-Date")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Date", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Security-Token")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Security-Token", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Content-Sha256", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Algorithm")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Algorithm", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-Signature")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Signature", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-SignedHeaders", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Credential")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Credential", valid_773356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773357: Call_GetCloudFormationTemplate_773345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified AWS CloudFormation template.
  ## 
  let valid = call_773357.validator(path, query, header, formData, body)
  let scheme = call_773357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773357.url(scheme.get, call_773357.host, call_773357.base,
                         call_773357.route, valid.getOrDefault("path"))
  result = hook(call_773357, url, valid)

proc call*(call_773358: Call_GetCloudFormationTemplate_773345; templateId: string;
          applicationId: string): Recallable =
  ## getCloudFormationTemplate
  ## Gets the specified AWS CloudFormation template.
  ##   templateId: string (required)
  ##             : <p>The UUID returned by CreateCloudFormationTemplate.</p><p>Pattern: 
  ## [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}</p>
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_773359 = newJObject()
  add(path_773359, "templateId", newJString(templateId))
  add(path_773359, "applicationId", newJString(applicationId))
  result = call_773358.call(path_773359, nil, nil, nil, nil)

var getCloudFormationTemplate* = Call_GetCloudFormationTemplate_773345(
    name: "getCloudFormationTemplate", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates/{templateId}",
    validator: validate_GetCloudFormationTemplate_773346, base: "/",
    url: url_GetCloudFormationTemplate_773347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationDependencies_773360 = ref object of OpenApiRestCall_772597
proc url_ListApplicationDependencies_773362(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/dependencies")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListApplicationDependencies_773361(path: JsonNode; query: JsonNode;
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
  var valid_773363 = path.getOrDefault("applicationId")
  valid_773363 = validateParameter(valid_773363, JString, required = true,
                                 default = nil)
  if valid_773363 != nil:
    section.add "applicationId", valid_773363
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   nextToken: JString
  ##            : A token to specify where to start paginating.
  ##   semanticVersion: JString
  ##                  : The semantic version of the application to get.
  ##   maxItems: JInt
  ##           : The total number of items to return.
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_773364 = query.getOrDefault("NextToken")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "NextToken", valid_773364
  var valid_773365 = query.getOrDefault("nextToken")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "nextToken", valid_773365
  var valid_773366 = query.getOrDefault("semanticVersion")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "semanticVersion", valid_773366
  var valid_773367 = query.getOrDefault("maxItems")
  valid_773367 = validateParameter(valid_773367, JInt, required = false, default = nil)
  if valid_773367 != nil:
    section.add "maxItems", valid_773367
  var valid_773368 = query.getOrDefault("MaxItems")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "MaxItems", valid_773368
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
  var valid_773369 = header.getOrDefault("X-Amz-Date")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Date", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Security-Token")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Security-Token", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Content-Sha256", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Algorithm")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Algorithm", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Signature")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Signature", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-SignedHeaders", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Credential")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Credential", valid_773375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773376: Call_ListApplicationDependencies_773360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the list of applications nested in the containing application.
  ## 
  let valid = call_773376.validator(path, query, header, formData, body)
  let scheme = call_773376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773376.url(scheme.get, call_773376.host, call_773376.base,
                         call_773376.route, valid.getOrDefault("path"))
  result = hook(call_773376, url, valid)

proc call*(call_773377: Call_ListApplicationDependencies_773360;
          applicationId: string; NextToken: string = ""; nextToken: string = "";
          semanticVersion: string = ""; maxItems: int = 0; MaxItems: string = ""): Recallable =
  ## listApplicationDependencies
  ## Retrieves the list of applications nested in the containing application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to specify where to start paginating.
  ##   semanticVersion: string
  ##                  : The semantic version of the application to get.
  ##   maxItems: int
  ##           : The total number of items to return.
  ##   MaxItems: string
  ##           : Pagination limit
  var path_773378 = newJObject()
  var query_773379 = newJObject()
  add(path_773378, "applicationId", newJString(applicationId))
  add(query_773379, "NextToken", newJString(NextToken))
  add(query_773379, "nextToken", newJString(nextToken))
  add(query_773379, "semanticVersion", newJString(semanticVersion))
  add(query_773379, "maxItems", newJInt(maxItems))
  add(query_773379, "MaxItems", newJString(MaxItems))
  result = call_773377.call(path_773378, query_773379, nil, nil, nil)

var listApplicationDependencies* = Call_ListApplicationDependencies_773360(
    name: "listApplicationDependencies", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/dependencies",
    validator: validate_ListApplicationDependencies_773361, base: "/",
    url: url_ListApplicationDependencies_773362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationVersions_773380 = ref object of OpenApiRestCall_772597
proc url_ListApplicationVersions_773382(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListApplicationVersions_773381(path: JsonNode; query: JsonNode;
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
  var valid_773383 = path.getOrDefault("applicationId")
  valid_773383 = validateParameter(valid_773383, JString, required = true,
                                 default = nil)
  if valid_773383 != nil:
    section.add "applicationId", valid_773383
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   nextToken: JString
  ##            : A token to specify where to start paginating.
  ##   maxItems: JInt
  ##           : The total number of items to return.
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_773384 = query.getOrDefault("NextToken")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "NextToken", valid_773384
  var valid_773385 = query.getOrDefault("nextToken")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "nextToken", valid_773385
  var valid_773386 = query.getOrDefault("maxItems")
  valid_773386 = validateParameter(valid_773386, JInt, required = false, default = nil)
  if valid_773386 != nil:
    section.add "maxItems", valid_773386
  var valid_773387 = query.getOrDefault("MaxItems")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "MaxItems", valid_773387
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
  var valid_773388 = header.getOrDefault("X-Amz-Date")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Date", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Security-Token")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Security-Token", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Content-Sha256", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Algorithm")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Algorithm", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Signature")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Signature", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-SignedHeaders", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-Credential")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Credential", valid_773394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773395: Call_ListApplicationVersions_773380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists versions for the specified application.
  ## 
  let valid = call_773395.validator(path, query, header, formData, body)
  let scheme = call_773395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773395.url(scheme.get, call_773395.host, call_773395.base,
                         call_773395.route, valid.getOrDefault("path"))
  result = hook(call_773395, url, valid)

proc call*(call_773396: Call_ListApplicationVersions_773380; applicationId: string;
          NextToken: string = ""; nextToken: string = ""; maxItems: int = 0;
          MaxItems: string = ""): Recallable =
  ## listApplicationVersions
  ## Lists versions for the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to specify where to start paginating.
  ##   maxItems: int
  ##           : The total number of items to return.
  ##   MaxItems: string
  ##           : Pagination limit
  var path_773397 = newJObject()
  var query_773398 = newJObject()
  add(path_773397, "applicationId", newJString(applicationId))
  add(query_773398, "NextToken", newJString(NextToken))
  add(query_773398, "nextToken", newJString(nextToken))
  add(query_773398, "maxItems", newJInt(maxItems))
  add(query_773398, "MaxItems", newJString(MaxItems))
  result = call_773396.call(path_773397, query_773398, nil, nil, nil)

var listApplicationVersions* = Call_ListApplicationVersions_773380(
    name: "listApplicationVersions", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions",
    validator: validate_ListApplicationVersions_773381, base: "/",
    url: url_ListApplicationVersions_773382, schemes: {Scheme.Https, Scheme.Http})
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
