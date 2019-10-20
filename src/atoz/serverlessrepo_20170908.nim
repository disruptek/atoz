
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
  Call_CreateApplication_592962 = ref object of OpenApiRestCall_592364
proc url_CreateApplication_592964(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApplication_592963(path: JsonNode; query: JsonNode;
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
  var valid_592965 = header.getOrDefault("X-Amz-Signature")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Signature", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Content-Sha256", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Date")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Date", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Credential")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Credential", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Security-Token")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Security-Token", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-Algorithm")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-Algorithm", valid_592970
  var valid_592971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592971 = validateParameter(valid_592971, JString, required = false,
                                 default = nil)
  if valid_592971 != nil:
    section.add "X-Amz-SignedHeaders", valid_592971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592973: Call_CreateApplication_592962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ## 
  let valid = call_592973.validator(path, query, header, formData, body)
  let scheme = call_592973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592973.url(scheme.get, call_592973.host, call_592973.base,
                         call_592973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592973, url, valid)

proc call*(call_592974: Call_CreateApplication_592962; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ##   body: JObject (required)
  var body_592975 = newJObject()
  if body != nil:
    body_592975 = body
  result = call_592974.call(nil, nil, nil, nil, body_592975)

var createApplication* = Call_CreateApplication_592962(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "serverlessrepo.amazonaws.com",
    route: "/applications", validator: validate_CreateApplication_592963, base: "/",
    url: url_CreateApplication_592964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_592703 = ref object of OpenApiRestCall_592364
proc url_ListApplications_592705(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListApplications_592704(path: JsonNode; query: JsonNode;
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
  var valid_592817 = query.getOrDefault("nextToken")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "nextToken", valid_592817
  var valid_592818 = query.getOrDefault("MaxItems")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "MaxItems", valid_592818
  var valid_592819 = query.getOrDefault("NextToken")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "NextToken", valid_592819
  var valid_592820 = query.getOrDefault("maxItems")
  valid_592820 = validateParameter(valid_592820, JInt, required = false, default = nil)
  if valid_592820 != nil:
    section.add "maxItems", valid_592820
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
  var valid_592821 = header.getOrDefault("X-Amz-Signature")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Signature", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Content-Sha256", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Date")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Date", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Credential")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Credential", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-Security-Token")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-Security-Token", valid_592825
  var valid_592826 = header.getOrDefault("X-Amz-Algorithm")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "X-Amz-Algorithm", valid_592826
  var valid_592827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592827 = validateParameter(valid_592827, JString, required = false,
                                 default = nil)
  if valid_592827 != nil:
    section.add "X-Amz-SignedHeaders", valid_592827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592850: Call_ListApplications_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists applications owned by the requester.
  ## 
  let valid = call_592850.validator(path, query, header, formData, body)
  let scheme = call_592850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592850.url(scheme.get, call_592850.host, call_592850.base,
                         call_592850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592850, url, valid)

proc call*(call_592921: Call_ListApplications_592703; nextToken: string = "";
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
  var query_592922 = newJObject()
  add(query_592922, "nextToken", newJString(nextToken))
  add(query_592922, "MaxItems", newJString(MaxItems))
  add(query_592922, "NextToken", newJString(NextToken))
  add(query_592922, "maxItems", newJInt(maxItems))
  result = call_592921.call(nil, query_592922, nil, nil, nil)

var listApplications* = Call_ListApplications_592703(name: "listApplications",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications", validator: validate_ListApplications_592704, base: "/",
    url: url_ListApplications_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplicationVersion_592976 = ref object of OpenApiRestCall_592364
proc url_CreateApplicationVersion_592978(protocol: Scheme; host: string;
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

proc validate_CreateApplicationVersion_592977(path: JsonNode; query: JsonNode;
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
  var valid_592993 = path.getOrDefault("semanticVersion")
  valid_592993 = validateParameter(valid_592993, JString, required = true,
                                 default = nil)
  if valid_592993 != nil:
    section.add "semanticVersion", valid_592993
  var valid_592994 = path.getOrDefault("applicationId")
  valid_592994 = validateParameter(valid_592994, JString, required = true,
                                 default = nil)
  if valid_592994 != nil:
    section.add "applicationId", valid_592994
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
  var valid_592995 = header.getOrDefault("X-Amz-Signature")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Signature", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Content-Sha256", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Date")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Date", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Credential")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Credential", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Security-Token")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Security-Token", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Algorithm")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Algorithm", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-SignedHeaders", valid_593001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593003: Call_CreateApplicationVersion_592976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application version.
  ## 
  let valid = call_593003.validator(path, query, header, formData, body)
  let scheme = call_593003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593003.url(scheme.get, call_593003.host, call_593003.base,
                         call_593003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593003, url, valid)

proc call*(call_593004: Call_CreateApplicationVersion_592976; body: JsonNode;
          semanticVersion: string; applicationId: string): Recallable =
  ## createApplicationVersion
  ## Creates an application version.
  ##   body: JObject (required)
  ##   semanticVersion: string (required)
  ##                  : The semantic version of the new version.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_593005 = newJObject()
  var body_593006 = newJObject()
  if body != nil:
    body_593006 = body
  add(path_593005, "semanticVersion", newJString(semanticVersion))
  add(path_593005, "applicationId", newJString(applicationId))
  result = call_593004.call(path_593005, nil, nil, nil, body_593006)

var createApplicationVersion* = Call_CreateApplicationVersion_592976(
    name: "createApplicationVersion", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions/{semanticVersion}",
    validator: validate_CreateApplicationVersion_592977, base: "/",
    url: url_CreateApplicationVersion_592978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationChangeSet_593007 = ref object of OpenApiRestCall_592364
proc url_CreateCloudFormationChangeSet_593009(protocol: Scheme; host: string;
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

proc validate_CreateCloudFormationChangeSet_593008(path: JsonNode; query: JsonNode;
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
  var valid_593010 = path.getOrDefault("applicationId")
  valid_593010 = validateParameter(valid_593010, JString, required = true,
                                 default = nil)
  if valid_593010 != nil:
    section.add "applicationId", valid_593010
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
  var valid_593011 = header.getOrDefault("X-Amz-Signature")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Signature", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Content-Sha256", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Date")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Date", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Credential")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Credential", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Security-Token")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Security-Token", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Algorithm")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Algorithm", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-SignedHeaders", valid_593017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593019: Call_CreateCloudFormationChangeSet_593007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS CloudFormation change set for the given application.
  ## 
  let valid = call_593019.validator(path, query, header, formData, body)
  let scheme = call_593019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593019.url(scheme.get, call_593019.host, call_593019.base,
                         call_593019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593019, url, valid)

proc call*(call_593020: Call_CreateCloudFormationChangeSet_593007; body: JsonNode;
          applicationId: string): Recallable =
  ## createCloudFormationChangeSet
  ## Creates an AWS CloudFormation change set for the given application.
  ##   body: JObject (required)
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_593021 = newJObject()
  var body_593022 = newJObject()
  if body != nil:
    body_593022 = body
  add(path_593021, "applicationId", newJString(applicationId))
  result = call_593020.call(path_593021, nil, nil, nil, body_593022)

var createCloudFormationChangeSet* = Call_CreateCloudFormationChangeSet_593007(
    name: "createCloudFormationChangeSet", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/changesets",
    validator: validate_CreateCloudFormationChangeSet_593008, base: "/",
    url: url_CreateCloudFormationChangeSet_593009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationTemplate_593023 = ref object of OpenApiRestCall_592364
proc url_CreateCloudFormationTemplate_593025(protocol: Scheme; host: string;
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

proc validate_CreateCloudFormationTemplate_593024(path: JsonNode; query: JsonNode;
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
  var valid_593026 = path.getOrDefault("applicationId")
  valid_593026 = validateParameter(valid_593026, JString, required = true,
                                 default = nil)
  if valid_593026 != nil:
    section.add "applicationId", valid_593026
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
  var valid_593027 = header.getOrDefault("X-Amz-Signature")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Signature", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Content-Sha256", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Date")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Date", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Credential")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Credential", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Security-Token")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Security-Token", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Algorithm")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Algorithm", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-SignedHeaders", valid_593033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593035: Call_CreateCloudFormationTemplate_593023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS CloudFormation template.
  ## 
  let valid = call_593035.validator(path, query, header, formData, body)
  let scheme = call_593035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593035.url(scheme.get, call_593035.host, call_593035.base,
                         call_593035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593035, url, valid)

proc call*(call_593036: Call_CreateCloudFormationTemplate_593023; body: JsonNode;
          applicationId: string): Recallable =
  ## createCloudFormationTemplate
  ## Creates an AWS CloudFormation template.
  ##   body: JObject (required)
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_593037 = newJObject()
  var body_593038 = newJObject()
  if body != nil:
    body_593038 = body
  add(path_593037, "applicationId", newJString(applicationId))
  result = call_593036.call(path_593037, nil, nil, nil, body_593038)

var createCloudFormationTemplate* = Call_CreateCloudFormationTemplate_593023(
    name: "createCloudFormationTemplate", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates",
    validator: validate_CreateCloudFormationTemplate_593024, base: "/",
    url: url_CreateCloudFormationTemplate_593025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_593039 = ref object of OpenApiRestCall_592364
proc url_GetApplication_593041(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplication_593040(path: JsonNode; query: JsonNode;
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
  var valid_593042 = path.getOrDefault("applicationId")
  valid_593042 = validateParameter(valid_593042, JString, required = true,
                                 default = nil)
  if valid_593042 != nil:
    section.add "applicationId", valid_593042
  result.add "path", section
  ## parameters in `query` object:
  ##   semanticVersion: JString
  ##                  : The semantic version of the application to get.
  section = newJObject()
  var valid_593043 = query.getOrDefault("semanticVersion")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "semanticVersion", valid_593043
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
  var valid_593044 = header.getOrDefault("X-Amz-Signature")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Signature", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Content-Sha256", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Date")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Date", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Credential")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Credential", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Security-Token")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Security-Token", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Algorithm")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Algorithm", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-SignedHeaders", valid_593050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593051: Call_GetApplication_593039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified application.
  ## 
  let valid = call_593051.validator(path, query, header, formData, body)
  let scheme = call_593051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593051.url(scheme.get, call_593051.host, call_593051.base,
                         call_593051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593051, url, valid)

proc call*(call_593052: Call_GetApplication_593039; applicationId: string;
          semanticVersion: string = ""): Recallable =
  ## getApplication
  ## Gets the specified application.
  ##   semanticVersion: string
  ##                  : The semantic version of the application to get.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_593053 = newJObject()
  var query_593054 = newJObject()
  add(query_593054, "semanticVersion", newJString(semanticVersion))
  add(path_593053, "applicationId", newJString(applicationId))
  result = call_593052.call(path_593053, query_593054, nil, nil, nil)

var getApplication* = Call_GetApplication_593039(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_GetApplication_593040,
    base: "/", url: url_GetApplication_593041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_593069 = ref object of OpenApiRestCall_592364
proc url_UpdateApplication_593071(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApplication_593070(path: JsonNode; query: JsonNode;
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
  var valid_593072 = path.getOrDefault("applicationId")
  valid_593072 = validateParameter(valid_593072, JString, required = true,
                                 default = nil)
  if valid_593072 != nil:
    section.add "applicationId", valid_593072
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
  var valid_593073 = header.getOrDefault("X-Amz-Signature")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Signature", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Content-Sha256", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Date")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Date", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Credential")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Credential", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Security-Token")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Security-Token", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Algorithm")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Algorithm", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-SignedHeaders", valid_593079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593081: Call_UpdateApplication_593069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified application.
  ## 
  let valid = call_593081.validator(path, query, header, formData, body)
  let scheme = call_593081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593081.url(scheme.get, call_593081.host, call_593081.base,
                         call_593081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593081, url, valid)

proc call*(call_593082: Call_UpdateApplication_593069; body: JsonNode;
          applicationId: string): Recallable =
  ## updateApplication
  ## Updates the specified application.
  ##   body: JObject (required)
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_593083 = newJObject()
  var body_593084 = newJObject()
  if body != nil:
    body_593084 = body
  add(path_593083, "applicationId", newJString(applicationId))
  result = call_593082.call(path_593083, nil, nil, nil, body_593084)

var updateApplication* = Call_UpdateApplication_593069(name: "updateApplication",
    meth: HttpMethod.HttpPatch, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_UpdateApplication_593070,
    base: "/", url: url_UpdateApplication_593071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_593055 = ref object of OpenApiRestCall_592364
proc url_DeleteApplication_593057(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApplication_593056(path: JsonNode; query: JsonNode;
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
  var valid_593058 = path.getOrDefault("applicationId")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "applicationId", valid_593058
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
  var valid_593059 = header.getOrDefault("X-Amz-Signature")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Signature", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Content-Sha256", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Date")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Date", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Credential")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Credential", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Security-Token")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Security-Token", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Algorithm")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Algorithm", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-SignedHeaders", valid_593065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593066: Call_DeleteApplication_593055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified application.
  ## 
  let valid = call_593066.validator(path, query, header, formData, body)
  let scheme = call_593066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593066.url(scheme.get, call_593066.host, call_593066.base,
                         call_593066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593066, url, valid)

proc call*(call_593067: Call_DeleteApplication_593055; applicationId: string): Recallable =
  ## deleteApplication
  ## Deletes the specified application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_593068 = newJObject()
  add(path_593068, "applicationId", newJString(applicationId))
  result = call_593067.call(path_593068, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_593055(name: "deleteApplication",
    meth: HttpMethod.HttpDelete, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_DeleteApplication_593056,
    base: "/", url: url_DeleteApplication_593057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApplicationPolicy_593099 = ref object of OpenApiRestCall_592364
proc url_PutApplicationPolicy_593101(protocol: Scheme; host: string; base: string;
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

proc validate_PutApplicationPolicy_593100(path: JsonNode; query: JsonNode;
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
  var valid_593102 = path.getOrDefault("applicationId")
  valid_593102 = validateParameter(valid_593102, JString, required = true,
                                 default = nil)
  if valid_593102 != nil:
    section.add "applicationId", valid_593102
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
  var valid_593103 = header.getOrDefault("X-Amz-Signature")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Signature", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Content-Sha256", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Date")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Date", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Credential")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Credential", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Security-Token")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Security-Token", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Algorithm")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Algorithm", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-SignedHeaders", valid_593109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593111: Call_PutApplicationPolicy_593099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ## 
  let valid = call_593111.validator(path, query, header, formData, body)
  let scheme = call_593111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593111.url(scheme.get, call_593111.host, call_593111.base,
                         call_593111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593111, url, valid)

proc call*(call_593112: Call_PutApplicationPolicy_593099; body: JsonNode;
          applicationId: string): Recallable =
  ## putApplicationPolicy
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
  ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
  ##  Permissions</a>
  ##  .
  ##   body: JObject (required)
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_593113 = newJObject()
  var body_593114 = newJObject()
  if body != nil:
    body_593114 = body
  add(path_593113, "applicationId", newJString(applicationId))
  result = call_593112.call(path_593113, nil, nil, nil, body_593114)

var putApplicationPolicy* = Call_PutApplicationPolicy_593099(
    name: "putApplicationPolicy", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_PutApplicationPolicy_593100, base: "/",
    url: url_PutApplicationPolicy_593101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationPolicy_593085 = ref object of OpenApiRestCall_592364
proc url_GetApplicationPolicy_593087(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplicationPolicy_593086(path: JsonNode; query: JsonNode;
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
  var valid_593088 = path.getOrDefault("applicationId")
  valid_593088 = validateParameter(valid_593088, JString, required = true,
                                 default = nil)
  if valid_593088 != nil:
    section.add "applicationId", valid_593088
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
  var valid_593089 = header.getOrDefault("X-Amz-Signature")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Signature", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Content-Sha256", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Date")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Date", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Credential")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Credential", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Security-Token")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Security-Token", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Algorithm")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Algorithm", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-SignedHeaders", valid_593095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593096: Call_GetApplicationPolicy_593085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy for the application.
  ## 
  let valid = call_593096.validator(path, query, header, formData, body)
  let scheme = call_593096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593096.url(scheme.get, call_593096.host, call_593096.base,
                         call_593096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593096, url, valid)

proc call*(call_593097: Call_GetApplicationPolicy_593085; applicationId: string): Recallable =
  ## getApplicationPolicy
  ## Retrieves the policy for the application.
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_593098 = newJObject()
  add(path_593098, "applicationId", newJString(applicationId))
  result = call_593097.call(path_593098, nil, nil, nil, nil)

var getApplicationPolicy* = Call_GetApplicationPolicy_593085(
    name: "getApplicationPolicy", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_GetApplicationPolicy_593086, base: "/",
    url: url_GetApplicationPolicy_593087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationTemplate_593115 = ref object of OpenApiRestCall_592364
proc url_GetCloudFormationTemplate_593117(protocol: Scheme; host: string;
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

proc validate_GetCloudFormationTemplate_593116(path: JsonNode; query: JsonNode;
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
  var valid_593118 = path.getOrDefault("templateId")
  valid_593118 = validateParameter(valid_593118, JString, required = true,
                                 default = nil)
  if valid_593118 != nil:
    section.add "templateId", valid_593118
  var valid_593119 = path.getOrDefault("applicationId")
  valid_593119 = validateParameter(valid_593119, JString, required = true,
                                 default = nil)
  if valid_593119 != nil:
    section.add "applicationId", valid_593119
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
  var valid_593120 = header.getOrDefault("X-Amz-Signature")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Signature", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Content-Sha256", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Date")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Date", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Credential")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Credential", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Security-Token")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Security-Token", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Algorithm")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Algorithm", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-SignedHeaders", valid_593126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593127: Call_GetCloudFormationTemplate_593115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified AWS CloudFormation template.
  ## 
  let valid = call_593127.validator(path, query, header, formData, body)
  let scheme = call_593127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593127.url(scheme.get, call_593127.host, call_593127.base,
                         call_593127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593127, url, valid)

proc call*(call_593128: Call_GetCloudFormationTemplate_593115; templateId: string;
          applicationId: string): Recallable =
  ## getCloudFormationTemplate
  ## Gets the specified AWS CloudFormation template.
  ##   templateId: string (required)
  ##             : <p>The UUID returned by CreateCloudFormationTemplate.</p><p>Pattern: 
  ## [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}</p>
  ##   applicationId: string (required)
  ##                : The Amazon Resource Name (ARN) of the application.
  var path_593129 = newJObject()
  add(path_593129, "templateId", newJString(templateId))
  add(path_593129, "applicationId", newJString(applicationId))
  result = call_593128.call(path_593129, nil, nil, nil, nil)

var getCloudFormationTemplate* = Call_GetCloudFormationTemplate_593115(
    name: "getCloudFormationTemplate", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates/{templateId}",
    validator: validate_GetCloudFormationTemplate_593116, base: "/",
    url: url_GetCloudFormationTemplate_593117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationDependencies_593130 = ref object of OpenApiRestCall_592364
proc url_ListApplicationDependencies_593132(protocol: Scheme; host: string;
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

proc validate_ListApplicationDependencies_593131(path: JsonNode; query: JsonNode;
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
  var valid_593133 = path.getOrDefault("applicationId")
  valid_593133 = validateParameter(valid_593133, JString, required = true,
                                 default = nil)
  if valid_593133 != nil:
    section.add "applicationId", valid_593133
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
  var valid_593134 = query.getOrDefault("nextToken")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "nextToken", valid_593134
  var valid_593135 = query.getOrDefault("MaxItems")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "MaxItems", valid_593135
  var valid_593136 = query.getOrDefault("NextToken")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "NextToken", valid_593136
  var valid_593137 = query.getOrDefault("maxItems")
  valid_593137 = validateParameter(valid_593137, JInt, required = false, default = nil)
  if valid_593137 != nil:
    section.add "maxItems", valid_593137
  var valid_593138 = query.getOrDefault("semanticVersion")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "semanticVersion", valid_593138
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
  var valid_593139 = header.getOrDefault("X-Amz-Signature")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Signature", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Content-Sha256", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Date")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Date", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Credential")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Credential", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Security-Token")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Security-Token", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Algorithm")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Algorithm", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-SignedHeaders", valid_593145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593146: Call_ListApplicationDependencies_593130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the list of applications nested in the containing application.
  ## 
  let valid = call_593146.validator(path, query, header, formData, body)
  let scheme = call_593146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593146.url(scheme.get, call_593146.host, call_593146.base,
                         call_593146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593146, url, valid)

proc call*(call_593147: Call_ListApplicationDependencies_593130;
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
  var path_593148 = newJObject()
  var query_593149 = newJObject()
  add(query_593149, "nextToken", newJString(nextToken))
  add(query_593149, "MaxItems", newJString(MaxItems))
  add(query_593149, "NextToken", newJString(NextToken))
  add(query_593149, "maxItems", newJInt(maxItems))
  add(query_593149, "semanticVersion", newJString(semanticVersion))
  add(path_593148, "applicationId", newJString(applicationId))
  result = call_593147.call(path_593148, query_593149, nil, nil, nil)

var listApplicationDependencies* = Call_ListApplicationDependencies_593130(
    name: "listApplicationDependencies", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/dependencies",
    validator: validate_ListApplicationDependencies_593131, base: "/",
    url: url_ListApplicationDependencies_593132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationVersions_593150 = ref object of OpenApiRestCall_592364
proc url_ListApplicationVersions_593152(protocol: Scheme; host: string; base: string;
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

proc validate_ListApplicationVersions_593151(path: JsonNode; query: JsonNode;
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
  var valid_593153 = path.getOrDefault("applicationId")
  valid_593153 = validateParameter(valid_593153, JString, required = true,
                                 default = nil)
  if valid_593153 != nil:
    section.add "applicationId", valid_593153
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
  var valid_593154 = query.getOrDefault("nextToken")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "nextToken", valid_593154
  var valid_593155 = query.getOrDefault("MaxItems")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "MaxItems", valid_593155
  var valid_593156 = query.getOrDefault("NextToken")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "NextToken", valid_593156
  var valid_593157 = query.getOrDefault("maxItems")
  valid_593157 = validateParameter(valid_593157, JInt, required = false, default = nil)
  if valid_593157 != nil:
    section.add "maxItems", valid_593157
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
  var valid_593158 = header.getOrDefault("X-Amz-Signature")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Signature", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Content-Sha256", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Date")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Date", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Credential")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Credential", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Security-Token")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Security-Token", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Algorithm")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Algorithm", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-SignedHeaders", valid_593164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593165: Call_ListApplicationVersions_593150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists versions for the specified application.
  ## 
  let valid = call_593165.validator(path, query, header, formData, body)
  let scheme = call_593165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593165.url(scheme.get, call_593165.host, call_593165.base,
                         call_593165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593165, url, valid)

proc call*(call_593166: Call_ListApplicationVersions_593150; applicationId: string;
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
  var path_593167 = newJObject()
  var query_593168 = newJObject()
  add(query_593168, "nextToken", newJString(nextToken))
  add(query_593168, "MaxItems", newJString(MaxItems))
  add(query_593168, "NextToken", newJString(NextToken))
  add(query_593168, "maxItems", newJInt(maxItems))
  add(path_593167, "applicationId", newJString(applicationId))
  result = call_593166.call(path_593167, query_593168, nil, nil, nil)

var listApplicationVersions* = Call_ListApplicationVersions_593150(
    name: "listApplicationVersions", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions",
    validator: validate_ListApplicationVersions_593151, base: "/",
    url: url_ListApplicationVersions_593152, schemes: {Scheme.Https, Scheme.Http})
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
