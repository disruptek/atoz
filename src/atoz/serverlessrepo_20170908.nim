
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
  Call_CreateApplication_603029 = ref object of OpenApiRestCall_602433
proc url_CreateApplication_603031(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApplication_603030(path: JsonNode; query: JsonNode;
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
  var valid_603032 = header.getOrDefault("X-Amz-Date")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Date", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Security-Token")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Security-Token", valid_603033
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

proc call*(call_603040: Call_CreateApplication_603029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ## 
  let valid = call_603040.validator(path, query, header, formData, body)
  let scheme = call_603040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603040.url(scheme.get, call_603040.host, call_603040.base,
                         call_603040.route, valid.getOrDefault("path"))
  result = hook(call_603040, url, valid)

proc call*(call_603041: Call_CreateApplication_603029; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ##   body: JObject (required)
  var body_603042 = newJObject()
  if body != nil:
    body_603042 = body
  result = call_603041.call(nil, nil, nil, nil, body_603042)

var createApplication* = Call_CreateApplication_603029(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "serverlessrepo.amazonaws.com",
    route: "/applications", validator: validate_CreateApplication_603030, base: "/",
    url: url_CreateApplication_603031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_602770 = ref object of OpenApiRestCall_602433
proc url_ListApplications_602772(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListApplications_602771(path: JsonNode; query: JsonNode;
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
  var valid_602884 = query.getOrDefault("NextToken")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "NextToken", valid_602884
  var valid_602885 = query.getOrDefault("nextToken")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "nextToken", valid_602885
  var valid_602886 = query.getOrDefault("maxItems")
  valid_602886 = validateParameter(valid_602886, JInt, required = false, default = nil)
  if valid_602886 != nil:
    section.add "maxItems", valid_602886
  var valid_602887 = query.getOrDefault("MaxItems")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "MaxItems", valid_602887
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
  var valid_602888 = header.getOrDefault("X-Amz-Date")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Date", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Security-Token")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Security-Token", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Content-Sha256", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Algorithm")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Algorithm", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-Signature")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Signature", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-SignedHeaders", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Credential")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Credential", valid_602894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602917: Call_ListApplications_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists applications owned by the requester.
  ## 
  let valid = call_602917.validator(path, query, header, formData, body)
  let scheme = call_602917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602917.url(scheme.get, call_602917.host, call_602917.base,
                         call_602917.route, valid.getOrDefault("path"))
  result = hook(call_602917, url, valid)

proc call*(call_602988: Call_ListApplications_602770; NextToken: string = "";
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
  var query_602989 = newJObject()
  add(query_602989, "NextToken", newJString(NextToken))
  add(query_602989, "nextToken", newJString(nextToken))
  add(query_602989, "maxItems", newJInt(maxItems))
  add(query_602989, "MaxItems", newJString(MaxItems))
  result = call_602988.call(nil, query_602989, nil, nil, nil)

var listApplications* = Call_ListApplications_602770(name: "listApplications",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications", validator: validate_ListApplications_602771, base: "/",
    url: url_ListApplications_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplicationVersion_603043 = ref object of OpenApiRestCall_602433
proc url_CreateApplicationVersion_603045(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateApplicationVersion_603044(path: JsonNode; query: JsonNode;
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
  var valid_603060 = path.getOrDefault("semanticVersion")
  valid_603060 = validateParameter(valid_603060, JString, required = true,
                                 default = nil)
  if valid_603060 != nil:
    section.add "semanticVersion", valid_603060
  var valid_603061 = path.getOrDefault("applicationId")
  valid_603061 = validateParameter(valid_603061, JString, required = true,
                                 default = nil)
  if valid_603061 != nil:
    section.add "applicationId", valid_603061
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
  var valid_603062 = header.getOrDefault("X-Amz-Date")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Date", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Security-Token")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Security-Token", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Content-Sha256", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Algorithm")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Algorithm", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Signature")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Signature", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-SignedHeaders", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Credential")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Credential", valid_603068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603070: Call_CreateApplicationVersion_603043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application version.
  ## 
  let valid = call_603070.validator(path, query, header, formData, body)
  let scheme = call_603070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603070.url(scheme.get, call_603070.host, call_603070.base,
                         call_603070.route, valid.getOrDefault("path"))
  result = hook(call_603070, url, valid)

proc call*(call_603071: Call_CreateApplicationVersion_603043;
          semanticVersion: string; applicationId: string; body: JsonNode): Recallable =
  ## createApplicationVersion
  ## Creates an application version.
  ##   semanticVersion: string (required)
  ##                  : The semantic version of the new version.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_603072 = newJObject()
  var body_603073 = newJObject()
  add(path_603072, "semanticVersion", newJString(semanticVersion))
  add(path_603072, "applicationId", newJString(applicationId))
  if body != nil:
    body_603073 = body
  result = call_603071.call(path_603072, nil, nil, nil, body_603073)

var createApplicationVersion* = Call_CreateApplicationVersion_603043(
    name: "createApplicationVersion", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions/{semanticVersion}",
    validator: validate_CreateApplicationVersion_603044, base: "/",
    url: url_CreateApplicationVersion_603045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationChangeSet_603074 = ref object of OpenApiRestCall_602433
proc url_CreateCloudFormationChangeSet_603076(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateCloudFormationChangeSet_603075(path: JsonNode; query: JsonNode;
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
  var valid_603077 = path.getOrDefault("applicationId")
  valid_603077 = validateParameter(valid_603077, JString, required = true,
                                 default = nil)
  if valid_603077 != nil:
    section.add "applicationId", valid_603077
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
  var valid_603078 = header.getOrDefault("X-Amz-Date")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Date", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Security-Token")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Security-Token", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Content-Sha256", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Algorithm")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Algorithm", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Signature")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Signature", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-SignedHeaders", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Credential")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Credential", valid_603084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603086: Call_CreateCloudFormationChangeSet_603074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS CloudFormation change set for the given application.
  ## 
  let valid = call_603086.validator(path, query, header, formData, body)
  let scheme = call_603086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603086.url(scheme.get, call_603086.host, call_603086.base,
                         call_603086.route, valid.getOrDefault("path"))
  result = hook(call_603086, url, valid)

proc call*(call_603087: Call_CreateCloudFormationChangeSet_603074;
          applicationId: string; body: JsonNode): Recallable =
  ## createCloudFormationChangeSet
  ## Creates an AWS CloudFormation change set for the given application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_603088 = newJObject()
  var body_603089 = newJObject()
  add(path_603088, "applicationId", newJString(applicationId))
  if body != nil:
    body_603089 = body
  result = call_603087.call(path_603088, nil, nil, nil, body_603089)

var createCloudFormationChangeSet* = Call_CreateCloudFormationChangeSet_603074(
    name: "createCloudFormationChangeSet", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/changesets",
    validator: validate_CreateCloudFormationChangeSet_603075, base: "/",
    url: url_CreateCloudFormationChangeSet_603076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationTemplate_603090 = ref object of OpenApiRestCall_602433
proc url_CreateCloudFormationTemplate_603092(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateCloudFormationTemplate_603091(path: JsonNode; query: JsonNode;
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
  var valid_603093 = path.getOrDefault("applicationId")
  valid_603093 = validateParameter(valid_603093, JString, required = true,
                                 default = nil)
  if valid_603093 != nil:
    section.add "applicationId", valid_603093
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
  var valid_603094 = header.getOrDefault("X-Amz-Date")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Date", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Security-Token")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Security-Token", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Content-Sha256", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Algorithm")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Algorithm", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Signature")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Signature", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-SignedHeaders", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Credential")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Credential", valid_603100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603102: Call_CreateCloudFormationTemplate_603090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS CloudFormation template.
  ## 
  let valid = call_603102.validator(path, query, header, formData, body)
  let scheme = call_603102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603102.url(scheme.get, call_603102.host, call_603102.base,
                         call_603102.route, valid.getOrDefault("path"))
  result = hook(call_603102, url, valid)

proc call*(call_603103: Call_CreateCloudFormationTemplate_603090;
          applicationId: string; body: JsonNode): Recallable =
  ## createCloudFormationTemplate
  ## Creates an AWS CloudFormation template.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_603104 = newJObject()
  var body_603105 = newJObject()
  add(path_603104, "applicationId", newJString(applicationId))
  if body != nil:
    body_603105 = body
  result = call_603103.call(path_603104, nil, nil, nil, body_603105)

var createCloudFormationTemplate* = Call_CreateCloudFormationTemplate_603090(
    name: "createCloudFormationTemplate", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates",
    validator: validate_CreateCloudFormationTemplate_603091, base: "/",
    url: url_CreateCloudFormationTemplate_603092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_603106 = ref object of OpenApiRestCall_602433
proc url_GetApplication_603108(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetApplication_603107(path: JsonNode; query: JsonNode;
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
  var valid_603109 = path.getOrDefault("applicationId")
  valid_603109 = validateParameter(valid_603109, JString, required = true,
                                 default = nil)
  if valid_603109 != nil:
    section.add "applicationId", valid_603109
  result.add "path", section
  ## parameters in `query` object:
  ##   semanticVersion: JString
  ##                  : The semantic version of the application to get.
  section = newJObject()
  var valid_603110 = query.getOrDefault("semanticVersion")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "semanticVersion", valid_603110
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
  var valid_603111 = header.getOrDefault("X-Amz-Date")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Date", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Security-Token")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Security-Token", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Content-Sha256", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Algorithm")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Algorithm", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Signature")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Signature", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-SignedHeaders", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Credential")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Credential", valid_603117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603118: Call_GetApplication_603106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified application.
  ## 
  let valid = call_603118.validator(path, query, header, formData, body)
  let scheme = call_603118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603118.url(scheme.get, call_603118.host, call_603118.base,
                         call_603118.route, valid.getOrDefault("path"))
  result = hook(call_603118, url, valid)

proc call*(call_603119: Call_GetApplication_603106; applicationId: string;
          semanticVersion: string = ""): Recallable =
  ## getApplication
  ## Gets the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   semanticVersion: string
  ##                  : The semantic version of the application to get.
  var path_603120 = newJObject()
  var query_603121 = newJObject()
  add(path_603120, "applicationId", newJString(applicationId))
  add(query_603121, "semanticVersion", newJString(semanticVersion))
  result = call_603119.call(path_603120, query_603121, nil, nil, nil)

var getApplication* = Call_GetApplication_603106(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_GetApplication_603107,
    base: "/", url: url_GetApplication_603108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_603136 = ref object of OpenApiRestCall_602433
proc url_UpdateApplication_603138(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateApplication_603137(path: JsonNode; query: JsonNode;
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
  var valid_603139 = path.getOrDefault("applicationId")
  valid_603139 = validateParameter(valid_603139, JString, required = true,
                                 default = nil)
  if valid_603139 != nil:
    section.add "applicationId", valid_603139
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
  var valid_603140 = header.getOrDefault("X-Amz-Date")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Date", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Security-Token")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Security-Token", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Content-Sha256", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Algorithm")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Algorithm", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Signature")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Signature", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-SignedHeaders", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Credential")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Credential", valid_603146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603148: Call_UpdateApplication_603136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified application.
  ## 
  let valid = call_603148.validator(path, query, header, formData, body)
  let scheme = call_603148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603148.url(scheme.get, call_603148.host, call_603148.base,
                         call_603148.route, valid.getOrDefault("path"))
  result = hook(call_603148, url, valid)

proc call*(call_603149: Call_UpdateApplication_603136; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApplication
  ## Updates the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_603150 = newJObject()
  var body_603151 = newJObject()
  add(path_603150, "applicationId", newJString(applicationId))
  if body != nil:
    body_603151 = body
  result = call_603149.call(path_603150, nil, nil, nil, body_603151)

var updateApplication* = Call_UpdateApplication_603136(name: "updateApplication",
    meth: HttpMethod.HttpPatch, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_UpdateApplication_603137,
    base: "/", url: url_UpdateApplication_603138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_603122 = ref object of OpenApiRestCall_602433
proc url_DeleteApplication_603124(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
               (kind: VariableSegment, value: "applicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteApplication_603123(path: JsonNode; query: JsonNode;
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
  var valid_603125 = path.getOrDefault("applicationId")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "applicationId", valid_603125
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
  var valid_603126 = header.getOrDefault("X-Amz-Date")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Date", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Security-Token")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Security-Token", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Content-Sha256", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Algorithm")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Algorithm", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Signature")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Signature", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-SignedHeaders", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Credential")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Credential", valid_603132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603133: Call_DeleteApplication_603122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified application.
  ## 
  let valid = call_603133.validator(path, query, header, formData, body)
  let scheme = call_603133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603133.url(scheme.get, call_603133.host, call_603133.base,
                         call_603133.route, valid.getOrDefault("path"))
  result = hook(call_603133, url, valid)

proc call*(call_603134: Call_DeleteApplication_603122; applicationId: string): Recallable =
  ## deleteApplication
  ## Deletes the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_603135 = newJObject()
  add(path_603135, "applicationId", newJString(applicationId))
  result = call_603134.call(path_603135, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_603122(name: "deleteApplication",
    meth: HttpMethod.HttpDelete, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_DeleteApplication_603123,
    base: "/", url: url_DeleteApplication_603124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApplicationPolicy_603166 = ref object of OpenApiRestCall_602433
proc url_PutApplicationPolicy_603168(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutApplicationPolicy_603167(path: JsonNode; query: JsonNode;
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
  var valid_603169 = path.getOrDefault("applicationId")
  valid_603169 = validateParameter(valid_603169, JString, required = true,
                                 default = nil)
  if valid_603169 != nil:
    section.add "applicationId", valid_603169
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
  var valid_603170 = header.getOrDefault("X-Amz-Date")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Date", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Security-Token")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Security-Token", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Content-Sha256", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Signature")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Signature", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-SignedHeaders", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Credential")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Credential", valid_603176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_PutApplicationPolicy_603166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"))
  result = hook(call_603178, url, valid)

proc call*(call_603179: Call_PutApplicationPolicy_603166; applicationId: string;
          body: JsonNode): Recallable =
  ## putApplicationPolicy
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_603180 = newJObject()
  var body_603181 = newJObject()
  add(path_603180, "applicationId", newJString(applicationId))
  if body != nil:
    body_603181 = body
  result = call_603179.call(path_603180, nil, nil, nil, body_603181)

var putApplicationPolicy* = Call_PutApplicationPolicy_603166(
    name: "putApplicationPolicy", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_PutApplicationPolicy_603167, base: "/",
    url: url_PutApplicationPolicy_603168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationPolicy_603152 = ref object of OpenApiRestCall_602433
proc url_GetApplicationPolicy_603154(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetApplicationPolicy_603153(path: JsonNode; query: JsonNode;
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
  var valid_603155 = path.getOrDefault("applicationId")
  valid_603155 = validateParameter(valid_603155, JString, required = true,
                                 default = nil)
  if valid_603155 != nil:
    section.add "applicationId", valid_603155
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
  var valid_603156 = header.getOrDefault("X-Amz-Date")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Date", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Security-Token")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Security-Token", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Content-Sha256", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Algorithm")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Algorithm", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Signature")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Signature", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-SignedHeaders", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Credential")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Credential", valid_603162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603163: Call_GetApplicationPolicy_603152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy for the application.
  ## 
  let valid = call_603163.validator(path, query, header, formData, body)
  let scheme = call_603163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603163.url(scheme.get, call_603163.host, call_603163.base,
                         call_603163.route, valid.getOrDefault("path"))
  result = hook(call_603163, url, valid)

proc call*(call_603164: Call_GetApplicationPolicy_603152; applicationId: string): Recallable =
  ## getApplicationPolicy
  ## Retrieves the policy for the application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_603165 = newJObject()
  add(path_603165, "applicationId", newJString(applicationId))
  result = call_603164.call(path_603165, nil, nil, nil, nil)

var getApplicationPolicy* = Call_GetApplicationPolicy_603152(
    name: "getApplicationPolicy", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_GetApplicationPolicy_603153, base: "/",
    url: url_GetApplicationPolicy_603154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationTemplate_603182 = ref object of OpenApiRestCall_602433
proc url_GetCloudFormationTemplate_603184(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetCloudFormationTemplate_603183(path: JsonNode; query: JsonNode;
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
  var valid_603185 = path.getOrDefault("templateId")
  valid_603185 = validateParameter(valid_603185, JString, required = true,
                                 default = nil)
  if valid_603185 != nil:
    section.add "templateId", valid_603185
  var valid_603186 = path.getOrDefault("applicationId")
  valid_603186 = validateParameter(valid_603186, JString, required = true,
                                 default = nil)
  if valid_603186 != nil:
    section.add "applicationId", valid_603186
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
  var valid_603187 = header.getOrDefault("X-Amz-Date")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Date", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Security-Token")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Security-Token", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Content-Sha256", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Algorithm")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Algorithm", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Signature")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Signature", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-SignedHeaders", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Credential")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Credential", valid_603193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603194: Call_GetCloudFormationTemplate_603182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified AWS CloudFormation template.
  ## 
  let valid = call_603194.validator(path, query, header, formData, body)
  let scheme = call_603194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603194.url(scheme.get, call_603194.host, call_603194.base,
                         call_603194.route, valid.getOrDefault("path"))
  result = hook(call_603194, url, valid)

proc call*(call_603195: Call_GetCloudFormationTemplate_603182; templateId: string;
          applicationId: string): Recallable =
  ## getCloudFormationTemplate
  ## Gets the specified AWS CloudFormation template.
  ##   templateId: string (required)
  ##             : <p>The UUID returned by CreateCloudFormationTemplate.</p><p>Pattern: 
  ## [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}</p>
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_603196 = newJObject()
  add(path_603196, "templateId", newJString(templateId))
  add(path_603196, "applicationId", newJString(applicationId))
  result = call_603195.call(path_603196, nil, nil, nil, nil)

var getCloudFormationTemplate* = Call_GetCloudFormationTemplate_603182(
    name: "getCloudFormationTemplate", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates/{templateId}",
    validator: validate_GetCloudFormationTemplate_603183, base: "/",
    url: url_GetCloudFormationTemplate_603184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationDependencies_603197 = ref object of OpenApiRestCall_602433
proc url_ListApplicationDependencies_603199(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListApplicationDependencies_603198(path: JsonNode; query: JsonNode;
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
  var valid_603200 = path.getOrDefault("applicationId")
  valid_603200 = validateParameter(valid_603200, JString, required = true,
                                 default = nil)
  if valid_603200 != nil:
    section.add "applicationId", valid_603200
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
  var valid_603201 = query.getOrDefault("NextToken")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "NextToken", valid_603201
  var valid_603202 = query.getOrDefault("nextToken")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "nextToken", valid_603202
  var valid_603203 = query.getOrDefault("semanticVersion")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "semanticVersion", valid_603203
  var valid_603204 = query.getOrDefault("maxItems")
  valid_603204 = validateParameter(valid_603204, JInt, required = false, default = nil)
  if valid_603204 != nil:
    section.add "maxItems", valid_603204
  var valid_603205 = query.getOrDefault("MaxItems")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "MaxItems", valid_603205
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
  var valid_603206 = header.getOrDefault("X-Amz-Date")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Date", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Security-Token")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Security-Token", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Content-Sha256", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Algorithm")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Algorithm", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Signature")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Signature", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-SignedHeaders", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Credential")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Credential", valid_603212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603213: Call_ListApplicationDependencies_603197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the list of applications nested in the containing application.
  ## 
  let valid = call_603213.validator(path, query, header, formData, body)
  let scheme = call_603213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603213.url(scheme.get, call_603213.host, call_603213.base,
                         call_603213.route, valid.getOrDefault("path"))
  result = hook(call_603213, url, valid)

proc call*(call_603214: Call_ListApplicationDependencies_603197;
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
  var path_603215 = newJObject()
  var query_603216 = newJObject()
  add(path_603215, "applicationId", newJString(applicationId))
  add(query_603216, "NextToken", newJString(NextToken))
  add(query_603216, "nextToken", newJString(nextToken))
  add(query_603216, "semanticVersion", newJString(semanticVersion))
  add(query_603216, "maxItems", newJInt(maxItems))
  add(query_603216, "MaxItems", newJString(MaxItems))
  result = call_603214.call(path_603215, query_603216, nil, nil, nil)

var listApplicationDependencies* = Call_ListApplicationDependencies_603197(
    name: "listApplicationDependencies", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/dependencies",
    validator: validate_ListApplicationDependencies_603198, base: "/",
    url: url_ListApplicationDependencies_603199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationVersions_603217 = ref object of OpenApiRestCall_602433
proc url_ListApplicationVersions_603219(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListApplicationVersions_603218(path: JsonNode; query: JsonNode;
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
  var valid_603220 = path.getOrDefault("applicationId")
  valid_603220 = validateParameter(valid_603220, JString, required = true,
                                 default = nil)
  if valid_603220 != nil:
    section.add "applicationId", valid_603220
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
  var valid_603221 = query.getOrDefault("NextToken")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "NextToken", valid_603221
  var valid_603222 = query.getOrDefault("nextToken")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "nextToken", valid_603222
  var valid_603223 = query.getOrDefault("maxItems")
  valid_603223 = validateParameter(valid_603223, JInt, required = false, default = nil)
  if valid_603223 != nil:
    section.add "maxItems", valid_603223
  var valid_603224 = query.getOrDefault("MaxItems")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "MaxItems", valid_603224
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Content-Sha256", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Algorithm")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Algorithm", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Signature")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Signature", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-SignedHeaders", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Credential")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Credential", valid_603231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603232: Call_ListApplicationVersions_603217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists versions for the specified application.
  ## 
  let valid = call_603232.validator(path, query, header, formData, body)
  let scheme = call_603232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603232.url(scheme.get, call_603232.host, call_603232.base,
                         call_603232.route, valid.getOrDefault("path"))
  result = hook(call_603232, url, valid)

proc call*(call_603233: Call_ListApplicationVersions_603217; applicationId: string;
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
  var path_603234 = newJObject()
  var query_603235 = newJObject()
  add(path_603234, "applicationId", newJString(applicationId))
  add(query_603235, "NextToken", newJString(NextToken))
  add(query_603235, "nextToken", newJString(nextToken))
  add(query_603235, "maxItems", newJInt(maxItems))
  add(query_603235, "MaxItems", newJString(MaxItems))
  result = call_603233.call(path_603234, query_603235, nil, nil, nil)

var listApplicationVersions* = Call_ListApplicationVersions_603217(
    name: "listApplicationVersions", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions",
    validator: validate_ListApplicationVersions_603218, base: "/",
    url: url_ListApplicationVersions_603219, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
