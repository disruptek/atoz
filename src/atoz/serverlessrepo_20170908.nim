
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApplication_603062 = ref object of OpenApiRestCall_602466
proc url_CreateApplication_603064(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApplication_603063(path: JsonNode; query: JsonNode;
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
  var valid_603065 = header.getOrDefault("X-Amz-Date")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Date", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Security-Token")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Security-Token", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Content-Sha256", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Algorithm")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Algorithm", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Signature")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Signature", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-SignedHeaders", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Credential")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Credential", valid_603071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603073: Call_CreateApplication_603062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ## 
  let valid = call_603073.validator(path, query, header, formData, body)
  let scheme = call_603073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603073.url(scheme.get, call_603073.host, call_603073.base,
                         call_603073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603073, url, valid)

proc call*(call_603074: Call_CreateApplication_603062; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ##   body: JObject (required)
  var body_603075 = newJObject()
  if body != nil:
    body_603075 = body
  result = call_603074.call(nil, nil, nil, nil, body_603075)

var createApplication* = Call_CreateApplication_603062(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "serverlessrepo.amazonaws.com",
    route: "/applications", validator: validate_CreateApplication_603063, base: "/",
    url: url_CreateApplication_603064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_602803 = ref object of OpenApiRestCall_602466
proc url_ListApplications_602805(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListApplications_602804(path: JsonNode; query: JsonNode;
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
  var valid_602917 = query.getOrDefault("NextToken")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "NextToken", valid_602917
  var valid_602918 = query.getOrDefault("nextToken")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "nextToken", valid_602918
  var valid_602919 = query.getOrDefault("maxItems")
  valid_602919 = validateParameter(valid_602919, JInt, required = false, default = nil)
  if valid_602919 != nil:
    section.add "maxItems", valid_602919
  var valid_602920 = query.getOrDefault("MaxItems")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "MaxItems", valid_602920
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
  var valid_602921 = header.getOrDefault("X-Amz-Date")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Date", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Security-Token")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Security-Token", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Content-Sha256", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Algorithm")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Algorithm", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Signature")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Signature", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-SignedHeaders", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Credential")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Credential", valid_602927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602950: Call_ListApplications_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists applications owned by the requester.
  ## 
  let valid = call_602950.validator(path, query, header, formData, body)
  let scheme = call_602950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602950.url(scheme.get, call_602950.host, call_602950.base,
                         call_602950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602950, url, valid)

proc call*(call_603021: Call_ListApplications_602803; NextToken: string = "";
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
  var query_603022 = newJObject()
  add(query_603022, "NextToken", newJString(NextToken))
  add(query_603022, "nextToken", newJString(nextToken))
  add(query_603022, "maxItems", newJInt(maxItems))
  add(query_603022, "MaxItems", newJString(MaxItems))
  result = call_603021.call(nil, query_603022, nil, nil, nil)

var listApplications* = Call_ListApplications_602803(name: "listApplications",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications", validator: validate_ListApplications_602804, base: "/",
    url: url_ListApplications_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplicationVersion_603076 = ref object of OpenApiRestCall_602466
proc url_CreateApplicationVersion_603078(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateApplicationVersion_603077(path: JsonNode; query: JsonNode;
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
  var valid_603093 = path.getOrDefault("semanticVersion")
  valid_603093 = validateParameter(valid_603093, JString, required = true,
                                 default = nil)
  if valid_603093 != nil:
    section.add "semanticVersion", valid_603093
  var valid_603094 = path.getOrDefault("applicationId")
  valid_603094 = validateParameter(valid_603094, JString, required = true,
                                 default = nil)
  if valid_603094 != nil:
    section.add "applicationId", valid_603094
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
  var valid_603095 = header.getOrDefault("X-Amz-Date")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Date", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Security-Token")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Security-Token", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Content-Sha256", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Algorithm")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Algorithm", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Signature")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Signature", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-SignedHeaders", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Credential")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Credential", valid_603101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603103: Call_CreateApplicationVersion_603076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application version.
  ## 
  let valid = call_603103.validator(path, query, header, formData, body)
  let scheme = call_603103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603103.url(scheme.get, call_603103.host, call_603103.base,
                         call_603103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603103, url, valid)

proc call*(call_603104: Call_CreateApplicationVersion_603076;
          semanticVersion: string; applicationId: string; body: JsonNode): Recallable =
  ## createApplicationVersion
  ## Creates an application version.
  ##   semanticVersion: string (required)
  ##                  : The semantic version of the new version.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_603105 = newJObject()
  var body_603106 = newJObject()
  add(path_603105, "semanticVersion", newJString(semanticVersion))
  add(path_603105, "applicationId", newJString(applicationId))
  if body != nil:
    body_603106 = body
  result = call_603104.call(path_603105, nil, nil, nil, body_603106)

var createApplicationVersion* = Call_CreateApplicationVersion_603076(
    name: "createApplicationVersion", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions/{semanticVersion}",
    validator: validate_CreateApplicationVersion_603077, base: "/",
    url: url_CreateApplicationVersion_603078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationChangeSet_603107 = ref object of OpenApiRestCall_602466
proc url_CreateCloudFormationChangeSet_603109(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateCloudFormationChangeSet_603108(path: JsonNode; query: JsonNode;
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
  var valid_603110 = path.getOrDefault("applicationId")
  valid_603110 = validateParameter(valid_603110, JString, required = true,
                                 default = nil)
  if valid_603110 != nil:
    section.add "applicationId", valid_603110
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603119: Call_CreateCloudFormationChangeSet_603107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS CloudFormation change set for the given application.
  ## 
  let valid = call_603119.validator(path, query, header, formData, body)
  let scheme = call_603119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603119.url(scheme.get, call_603119.host, call_603119.base,
                         call_603119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603119, url, valid)

proc call*(call_603120: Call_CreateCloudFormationChangeSet_603107;
          applicationId: string; body: JsonNode): Recallable =
  ## createCloudFormationChangeSet
  ## Creates an AWS CloudFormation change set for the given application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_603121 = newJObject()
  var body_603122 = newJObject()
  add(path_603121, "applicationId", newJString(applicationId))
  if body != nil:
    body_603122 = body
  result = call_603120.call(path_603121, nil, nil, nil, body_603122)

var createCloudFormationChangeSet* = Call_CreateCloudFormationChangeSet_603107(
    name: "createCloudFormationChangeSet", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/changesets",
    validator: validate_CreateCloudFormationChangeSet_603108, base: "/",
    url: url_CreateCloudFormationChangeSet_603109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationTemplate_603123 = ref object of OpenApiRestCall_602466
proc url_CreateCloudFormationTemplate_603125(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateCloudFormationTemplate_603124(path: JsonNode; query: JsonNode;
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
  var valid_603126 = path.getOrDefault("applicationId")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = nil)
  if valid_603126 != nil:
    section.add "applicationId", valid_603126
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
  var valid_603127 = header.getOrDefault("X-Amz-Date")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Date", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Security-Token")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Security-Token", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Content-Sha256", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Algorithm")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Algorithm", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Signature")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Signature", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-SignedHeaders", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Credential")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Credential", valid_603133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603135: Call_CreateCloudFormationTemplate_603123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS CloudFormation template.
  ## 
  let valid = call_603135.validator(path, query, header, formData, body)
  let scheme = call_603135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603135.url(scheme.get, call_603135.host, call_603135.base,
                         call_603135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603135, url, valid)

proc call*(call_603136: Call_CreateCloudFormationTemplate_603123;
          applicationId: string; body: JsonNode): Recallable =
  ## createCloudFormationTemplate
  ## Creates an AWS CloudFormation template.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_603137 = newJObject()
  var body_603138 = newJObject()
  add(path_603137, "applicationId", newJString(applicationId))
  if body != nil:
    body_603138 = body
  result = call_603136.call(path_603137, nil, nil, nil, body_603138)

var createCloudFormationTemplate* = Call_CreateCloudFormationTemplate_603123(
    name: "createCloudFormationTemplate", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates",
    validator: validate_CreateCloudFormationTemplate_603124, base: "/",
    url: url_CreateCloudFormationTemplate_603125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_603139 = ref object of OpenApiRestCall_602466
proc url_GetApplication_603141(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetApplication_603140(path: JsonNode; query: JsonNode;
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
  var valid_603142 = path.getOrDefault("applicationId")
  valid_603142 = validateParameter(valid_603142, JString, required = true,
                                 default = nil)
  if valid_603142 != nil:
    section.add "applicationId", valid_603142
  result.add "path", section
  ## parameters in `query` object:
  ##   semanticVersion: JString
  ##                  : The semantic version of the application to get.
  section = newJObject()
  var valid_603143 = query.getOrDefault("semanticVersion")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "semanticVersion", valid_603143
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
  var valid_603144 = header.getOrDefault("X-Amz-Date")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Date", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Security-Token")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Security-Token", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Content-Sha256", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Algorithm")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Algorithm", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Signature")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Signature", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-SignedHeaders", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Credential")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Credential", valid_603150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603151: Call_GetApplication_603139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified application.
  ## 
  let valid = call_603151.validator(path, query, header, formData, body)
  let scheme = call_603151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603151.url(scheme.get, call_603151.host, call_603151.base,
                         call_603151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603151, url, valid)

proc call*(call_603152: Call_GetApplication_603139; applicationId: string;
          semanticVersion: string = ""): Recallable =
  ## getApplication
  ## Gets the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   semanticVersion: string
  ##                  : The semantic version of the application to get.
  var path_603153 = newJObject()
  var query_603154 = newJObject()
  add(path_603153, "applicationId", newJString(applicationId))
  add(query_603154, "semanticVersion", newJString(semanticVersion))
  result = call_603152.call(path_603153, query_603154, nil, nil, nil)

var getApplication* = Call_GetApplication_603139(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_GetApplication_603140,
    base: "/", url: url_GetApplication_603141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_603169 = ref object of OpenApiRestCall_602466
proc url_UpdateApplication_603171(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateApplication_603170(path: JsonNode; query: JsonNode;
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
  var valid_603172 = path.getOrDefault("applicationId")
  valid_603172 = validateParameter(valid_603172, JString, required = true,
                                 default = nil)
  if valid_603172 != nil:
    section.add "applicationId", valid_603172
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
  var valid_603173 = header.getOrDefault("X-Amz-Date")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Date", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Security-Token")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Security-Token", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Content-Sha256", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Algorithm")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Algorithm", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Signature")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Signature", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-SignedHeaders", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Credential")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Credential", valid_603179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603181: Call_UpdateApplication_603169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified application.
  ## 
  let valid = call_603181.validator(path, query, header, formData, body)
  let scheme = call_603181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603181.url(scheme.get, call_603181.host, call_603181.base,
                         call_603181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603181, url, valid)

proc call*(call_603182: Call_UpdateApplication_603169; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApplication
  ## Updates the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_603183 = newJObject()
  var body_603184 = newJObject()
  add(path_603183, "applicationId", newJString(applicationId))
  if body != nil:
    body_603184 = body
  result = call_603182.call(path_603183, nil, nil, nil, body_603184)

var updateApplication* = Call_UpdateApplication_603169(name: "updateApplication",
    meth: HttpMethod.HttpPatch, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_UpdateApplication_603170,
    base: "/", url: url_UpdateApplication_603171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_603155 = ref object of OpenApiRestCall_602466
proc url_DeleteApplication_603157(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteApplication_603156(path: JsonNode; query: JsonNode;
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
  var valid_603158 = path.getOrDefault("applicationId")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "applicationId", valid_603158
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
  var valid_603159 = header.getOrDefault("X-Amz-Date")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Date", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Security-Token")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Security-Token", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Content-Sha256", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Algorithm")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Algorithm", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Signature")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Signature", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-SignedHeaders", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Credential")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Credential", valid_603165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603166: Call_DeleteApplication_603155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified application.
  ## 
  let valid = call_603166.validator(path, query, header, formData, body)
  let scheme = call_603166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603166.url(scheme.get, call_603166.host, call_603166.base,
                         call_603166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603166, url, valid)

proc call*(call_603167: Call_DeleteApplication_603155; applicationId: string): Recallable =
  ## deleteApplication
  ## Deletes the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_603168 = newJObject()
  add(path_603168, "applicationId", newJString(applicationId))
  result = call_603167.call(path_603168, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_603155(name: "deleteApplication",
    meth: HttpMethod.HttpDelete, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_DeleteApplication_603156,
    base: "/", url: url_DeleteApplication_603157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApplicationPolicy_603199 = ref object of OpenApiRestCall_602466
proc url_PutApplicationPolicy_603201(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PutApplicationPolicy_603200(path: JsonNode; query: JsonNode;
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
  var valid_603202 = path.getOrDefault("applicationId")
  valid_603202 = validateParameter(valid_603202, JString, required = true,
                                 default = nil)
  if valid_603202 != nil:
    section.add "applicationId", valid_603202
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
  var valid_603203 = header.getOrDefault("X-Amz-Date")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Date", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Security-Token")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Security-Token", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Content-Sha256", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Algorithm")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Algorithm", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Signature")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Signature", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-SignedHeaders", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Credential")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Credential", valid_603209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603211: Call_PutApplicationPolicy_603199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ## 
  let valid = call_603211.validator(path, query, header, formData, body)
  let scheme = call_603211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603211.url(scheme.get, call_603211.host, call_603211.base,
                         call_603211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603211, url, valid)

proc call*(call_603212: Call_PutApplicationPolicy_603199; applicationId: string;
          body: JsonNode): Recallable =
  ## putApplicationPolicy
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  ##   body: JObject (required)
  var path_603213 = newJObject()
  var body_603214 = newJObject()
  add(path_603213, "applicationId", newJString(applicationId))
  if body != nil:
    body_603214 = body
  result = call_603212.call(path_603213, nil, nil, nil, body_603214)

var putApplicationPolicy* = Call_PutApplicationPolicy_603199(
    name: "putApplicationPolicy", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_PutApplicationPolicy_603200, base: "/",
    url: url_PutApplicationPolicy_603201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationPolicy_603185 = ref object of OpenApiRestCall_602466
proc url_GetApplicationPolicy_603187(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetApplicationPolicy_603186(path: JsonNode; query: JsonNode;
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
  var valid_603188 = path.getOrDefault("applicationId")
  valid_603188 = validateParameter(valid_603188, JString, required = true,
                                 default = nil)
  if valid_603188 != nil:
    section.add "applicationId", valid_603188
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
  var valid_603189 = header.getOrDefault("X-Amz-Date")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Date", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Security-Token")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Security-Token", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Content-Sha256", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Algorithm")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Algorithm", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Signature")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Signature", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-SignedHeaders", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Credential")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Credential", valid_603195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603196: Call_GetApplicationPolicy_603185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy for the application.
  ## 
  let valid = call_603196.validator(path, query, header, formData, body)
  let scheme = call_603196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603196.url(scheme.get, call_603196.host, call_603196.base,
                         call_603196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603196, url, valid)

proc call*(call_603197: Call_GetApplicationPolicy_603185; applicationId: string): Recallable =
  ## getApplicationPolicy
  ## Retrieves the policy for the application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_603198 = newJObject()
  add(path_603198, "applicationId", newJString(applicationId))
  result = call_603197.call(path_603198, nil, nil, nil, nil)

var getApplicationPolicy* = Call_GetApplicationPolicy_603185(
    name: "getApplicationPolicy", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_GetApplicationPolicy_603186, base: "/",
    url: url_GetApplicationPolicy_603187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationTemplate_603215 = ref object of OpenApiRestCall_602466
proc url_GetCloudFormationTemplate_603217(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetCloudFormationTemplate_603216(path: JsonNode; query: JsonNode;
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
  var valid_603218 = path.getOrDefault("templateId")
  valid_603218 = validateParameter(valid_603218, JString, required = true,
                                 default = nil)
  if valid_603218 != nil:
    section.add "templateId", valid_603218
  var valid_603219 = path.getOrDefault("applicationId")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = nil)
  if valid_603219 != nil:
    section.add "applicationId", valid_603219
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
  var valid_603220 = header.getOrDefault("X-Amz-Date")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Date", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Security-Token")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Security-Token", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Content-Sha256", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Algorithm")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Algorithm", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Signature")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Signature", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-SignedHeaders", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Credential")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Credential", valid_603226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603227: Call_GetCloudFormationTemplate_603215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified AWS CloudFormation template.
  ## 
  let valid = call_603227.validator(path, query, header, formData, body)
  let scheme = call_603227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603227.url(scheme.get, call_603227.host, call_603227.base,
                         call_603227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603227, url, valid)

proc call*(call_603228: Call_GetCloudFormationTemplate_603215; templateId: string;
          applicationId: string): Recallable =
  ## getCloudFormationTemplate
  ## Gets the specified AWS CloudFormation template.
  ##   templateId: string (required)
  ##             : <p>The UUID returned by CreateCloudFormationTemplate.</p><p>Pattern: 
  ## [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}</p>
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_603229 = newJObject()
  add(path_603229, "templateId", newJString(templateId))
  add(path_603229, "applicationId", newJString(applicationId))
  result = call_603228.call(path_603229, nil, nil, nil, nil)

var getCloudFormationTemplate* = Call_GetCloudFormationTemplate_603215(
    name: "getCloudFormationTemplate", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates/{templateId}",
    validator: validate_GetCloudFormationTemplate_603216, base: "/",
    url: url_GetCloudFormationTemplate_603217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationDependencies_603230 = ref object of OpenApiRestCall_602466
proc url_ListApplicationDependencies_603232(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListApplicationDependencies_603231(path: JsonNode; query: JsonNode;
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
  var valid_603233 = path.getOrDefault("applicationId")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = nil)
  if valid_603233 != nil:
    section.add "applicationId", valid_603233
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
  var valid_603234 = query.getOrDefault("NextToken")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "NextToken", valid_603234
  var valid_603235 = query.getOrDefault("nextToken")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "nextToken", valid_603235
  var valid_603236 = query.getOrDefault("semanticVersion")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "semanticVersion", valid_603236
  var valid_603237 = query.getOrDefault("maxItems")
  valid_603237 = validateParameter(valid_603237, JInt, required = false, default = nil)
  if valid_603237 != nil:
    section.add "maxItems", valid_603237
  var valid_603238 = query.getOrDefault("MaxItems")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "MaxItems", valid_603238
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
  var valid_603239 = header.getOrDefault("X-Amz-Date")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Date", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Security-Token")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Security-Token", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Content-Sha256", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Algorithm")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Algorithm", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Signature")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Signature", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-SignedHeaders", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Credential")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Credential", valid_603245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603246: Call_ListApplicationDependencies_603230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the list of applications nested in the containing application.
  ## 
  let valid = call_603246.validator(path, query, header, formData, body)
  let scheme = call_603246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603246.url(scheme.get, call_603246.host, call_603246.base,
                         call_603246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603246, url, valid)

proc call*(call_603247: Call_ListApplicationDependencies_603230;
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
  var path_603248 = newJObject()
  var query_603249 = newJObject()
  add(path_603248, "applicationId", newJString(applicationId))
  add(query_603249, "NextToken", newJString(NextToken))
  add(query_603249, "nextToken", newJString(nextToken))
  add(query_603249, "semanticVersion", newJString(semanticVersion))
  add(query_603249, "maxItems", newJInt(maxItems))
  add(query_603249, "MaxItems", newJString(MaxItems))
  result = call_603247.call(path_603248, query_603249, nil, nil, nil)

var listApplicationDependencies* = Call_ListApplicationDependencies_603230(
    name: "listApplicationDependencies", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/dependencies",
    validator: validate_ListApplicationDependencies_603231, base: "/",
    url: url_ListApplicationDependencies_603232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationVersions_603250 = ref object of OpenApiRestCall_602466
proc url_ListApplicationVersions_603252(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListApplicationVersions_603251(path: JsonNode; query: JsonNode;
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
  var valid_603253 = path.getOrDefault("applicationId")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "applicationId", valid_603253
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
  var valid_603254 = query.getOrDefault("NextToken")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "NextToken", valid_603254
  var valid_603255 = query.getOrDefault("nextToken")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "nextToken", valid_603255
  var valid_603256 = query.getOrDefault("maxItems")
  valid_603256 = validateParameter(valid_603256, JInt, required = false, default = nil)
  if valid_603256 != nil:
    section.add "maxItems", valid_603256
  var valid_603257 = query.getOrDefault("MaxItems")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "MaxItems", valid_603257
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
  var valid_603258 = header.getOrDefault("X-Amz-Date")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Date", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Security-Token")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Security-Token", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Content-Sha256", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Algorithm")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Algorithm", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Signature")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Signature", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-SignedHeaders", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Credential")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Credential", valid_603264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603265: Call_ListApplicationVersions_603250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists versions for the specified application.
  ## 
  let valid = call_603265.validator(path, query, header, formData, body)
  let scheme = call_603265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603265.url(scheme.get, call_603265.host, call_603265.base,
                         call_603265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603265, url, valid)

proc call*(call_603266: Call_ListApplicationVersions_603250; applicationId: string;
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
  var path_603267 = newJObject()
  var query_603268 = newJObject()
  add(path_603267, "applicationId", newJString(applicationId))
  add(query_603268, "NextToken", newJString(NextToken))
  add(query_603268, "nextToken", newJString(nextToken))
  add(query_603268, "maxItems", newJInt(maxItems))
  add(query_603268, "MaxItems", newJString(MaxItems))
  result = call_603266.call(path_603267, query_603268, nil, nil, nil)

var listApplicationVersions* = Call_ListApplicationVersions_603250(
    name: "listApplicationVersions", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions",
    validator: validate_ListApplicationVersions_603251, base: "/",
    url: url_ListApplicationVersions_603252, schemes: {Scheme.Https, Scheme.Http})
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
