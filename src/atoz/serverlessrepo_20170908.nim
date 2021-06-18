
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
    if required:
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "serverlessrepo.ap-northeast-1.amazonaws.com", "ap-southeast-1": "serverlessrepo.ap-southeast-1.amazonaws.com", "us-west-2": "serverlessrepo.us-west-2.amazonaws.com", "eu-west-2": "serverlessrepo.eu-west-2.amazonaws.com", "ap-northeast-3": "serverlessrepo.ap-northeast-3.amazonaws.com", "eu-central-1": "serverlessrepo.eu-central-1.amazonaws.com", "us-east-2": "serverlessrepo.us-east-2.amazonaws.com", "us-east-1": "serverlessrepo.us-east-1.amazonaws.com", "cn-northwest-1": "serverlessrepo.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "serverlessrepo.ap-south-1.amazonaws.com", "eu-north-1": "serverlessrepo.eu-north-1.amazonaws.com", "ap-northeast-2": "serverlessrepo.ap-northeast-2.amazonaws.com", "us-west-1": "serverlessrepo.us-west-1.amazonaws.com", "us-gov-east-1": "serverlessrepo.us-gov-east-1.amazonaws.com", "eu-west-3": "serverlessrepo.eu-west-3.amazonaws.com", "cn-north-1": "serverlessrepo.cn-north-1.amazonaws.com.cn", "sa-east-1": "serverlessrepo.sa-east-1.amazonaws.com", "eu-west-1": "serverlessrepo.eu-west-1.amazonaws.com", "us-gov-west-1": "serverlessrepo.us-gov-west-1.amazonaws.com", "ap-southeast-2": "serverlessrepo.ap-southeast-2.amazonaws.com", "ca-central-1": "serverlessrepo.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateApplication_402656473 = ref object of OpenApiRestCall_402656038
proc url_CreateApplication_402656475(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_402656474(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656476 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "X-Amz-Security-Token", valid_402656476
  var valid_402656477 = header.getOrDefault("X-Amz-Signature")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Signature", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Algorithm", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-Date")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Date", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Credential")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Credential", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656484: Call_CreateApplication_402656473;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
                                                                                         ## 
  let valid = call_402656484.validator(path, query, header, formData, body, _)
  let scheme = call_402656484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656484.makeUrl(scheme.get, call_402656484.host, call_402656484.base,
                                   call_402656484.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656484, uri, valid, _)

proc call*(call_402656485: Call_CreateApplication_402656473; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
  ##   
                                                                                                                           ## body: JObject (required)
  var body_402656486 = newJObject()
  if body != nil:
    body_402656486 = body
  result = call_402656485.call(nil, nil, nil, nil, body_402656486)

var createApplication* = Call_CreateApplication_402656473(
    name: "createApplication", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com", route: "/applications",
    validator: validate_CreateApplication_402656474, base: "/",
    makeUrl: url_CreateApplication_402656475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_402656288 = ref object of OpenApiRestCall_402656038
proc url_ListApplications_402656290(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplications_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists applications owned by the requester.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
                                  ##            : A token to specify where to start paginating.
  ##   
                                                                                               ## maxItems: JInt
                                                                                               ##           
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## total 
                                                                                               ## number 
                                                                                               ## of 
                                                                                               ## items 
                                                                                               ## to 
                                                                                               ## return.
  ##   
                                                                                                         ## NextToken: JString
                                                                                                         ##            
                                                                                                         ## : 
                                                                                                         ## Pagination 
                                                                                                         ## token
  ##   
                                                                                                                 ## MaxItems: JString
                                                                                                                 ##           
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## limit
  section = newJObject()
  var valid_402656372 = query.getOrDefault("nextToken")
  valid_402656372 = validateParameter(valid_402656372, JString,
                                      required = false, default = nil)
  if valid_402656372 != nil:
    section.add "nextToken", valid_402656372
  var valid_402656373 = query.getOrDefault("maxItems")
  valid_402656373 = validateParameter(valid_402656373, JInt, required = false,
                                      default = nil)
  if valid_402656373 != nil:
    section.add "maxItems", valid_402656373
  var valid_402656374 = query.getOrDefault("NextToken")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "NextToken", valid_402656374
  var valid_402656375 = query.getOrDefault("MaxItems")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "MaxItems", valid_402656375
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656376 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Security-Token", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-Signature")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Signature", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Algorithm", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Date")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Date", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Credential")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Credential", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656396: Call_ListApplications_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists applications owned by the requester.
                                                                                         ## 
  let valid = call_402656396.validator(path, query, header, formData, body, _)
  let scheme = call_402656396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656396.makeUrl(scheme.get, call_402656396.host, call_402656396.base,
                                   call_402656396.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656396, uri, valid, _)

proc call*(call_402656445: Call_ListApplications_402656288;
           nextToken: string = ""; maxItems: int = 0; NextToken: string = "";
           MaxItems: string = ""): Recallable =
  ## listApplications
  ## Lists applications owned by the requester.
  ##   nextToken: string
                                               ##            : A token to specify where to start paginating.
  ##   
                                                                                                            ## maxItems: int
                                                                                                            ##           
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## total 
                                                                                                            ## number 
                                                                                                            ## of 
                                                                                                            ## items 
                                                                                                            ## to 
                                                                                                            ## return.
  ##   
                                                                                                                      ## NextToken: string
                                                                                                                      ##            
                                                                                                                      ## : 
                                                                                                                      ## Pagination 
                                                                                                                      ## token
  ##   
                                                                                                                              ## MaxItems: string
                                                                                                                              ##           
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## limit
  var query_402656446 = newJObject()
  add(query_402656446, "nextToken", newJString(nextToken))
  add(query_402656446, "maxItems", newJInt(maxItems))
  add(query_402656446, "NextToken", newJString(NextToken))
  add(query_402656446, "MaxItems", newJString(MaxItems))
  result = call_402656445.call(nil, query_402656446, nil, nil, nil)

var listApplications* = Call_ListApplications_402656288(
    name: "listApplications", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com", route: "/applications",
    validator: validate_ListApplications_402656289, base: "/",
    makeUrl: url_ListApplications_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplicationVersion_402656487 = ref object of OpenApiRestCall_402656038
proc url_CreateApplicationVersion_402656489(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "applicationId" in path, "`applicationId` is a required path parameter"
  assert "semanticVersion" in path,
         "`semanticVersion` is a required path parameter"
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

proc validate_CreateApplicationVersion_402656488(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates an application version.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
                                 ##                : The Amazon Resource Name (ARN) of the application.
  ##   
                                                                                                       ## semanticVersion: JString (required)
                                                                                                       ##                  
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## semantic 
                                                                                                       ## version 
                                                                                                       ## of 
                                                                                                       ## the 
                                                                                                       ## new 
                                                                                                       ## version.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `applicationId` field"
  var valid_402656501 = path.getOrDefault("applicationId")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true,
                                      default = nil)
  if valid_402656501 != nil:
    section.add "applicationId", valid_402656501
  var valid_402656502 = path.getOrDefault("semanticVersion")
  valid_402656502 = validateParameter(valid_402656502, JString, required = true,
                                      default = nil)
  if valid_402656502 != nil:
    section.add "semanticVersion", valid_402656502
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656503 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Security-Token", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Signature")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Signature", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Algorithm", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Date")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Date", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Credential")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Credential", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656511: Call_CreateApplicationVersion_402656487;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an application version.
                                                                                         ## 
  let valid = call_402656511.validator(path, query, header, formData, body, _)
  let scheme = call_402656511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656511.makeUrl(scheme.get, call_402656511.host, call_402656511.base,
                                   call_402656511.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656511, uri, valid, _)

proc call*(call_402656512: Call_CreateApplicationVersion_402656487;
           applicationId: string; body: JsonNode; semanticVersion: string): Recallable =
  ## createApplicationVersion
  ## Creates an application version.
  ##   applicationId: string (required)
                                    ##                : The Amazon Resource Name (ARN) of the application.
  ##   
                                                                                                          ## body: JObject (required)
  ##   
                                                                                                                                     ## semanticVersion: string (required)
                                                                                                                                     ##                  
                                                                                                                                     ## : 
                                                                                                                                     ## The 
                                                                                                                                     ## semantic 
                                                                                                                                     ## version 
                                                                                                                                     ## of 
                                                                                                                                     ## the 
                                                                                                                                     ## new 
                                                                                                                                     ## version.
  var path_402656513 = newJObject()
  var body_402656514 = newJObject()
  add(path_402656513, "applicationId", newJString(applicationId))
  if body != nil:
    body_402656514 = body
  add(path_402656513, "semanticVersion", newJString(semanticVersion))
  result = call_402656512.call(path_402656513, nil, nil, nil, body_402656514)

var createApplicationVersion* = Call_CreateApplicationVersion_402656487(
    name: "createApplicationVersion", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions/{semanticVersion}",
    validator: validate_CreateApplicationVersion_402656488, base: "/",
    makeUrl: url_CreateApplicationVersion_402656489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationChangeSet_402656515 = ref object of OpenApiRestCall_402656038
proc url_CreateCloudFormationChangeSet_402656517(protocol: Scheme; host: string;
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

proc validate_CreateCloudFormationChangeSet_402656516(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656518 = path.getOrDefault("applicationId")
  valid_402656518 = validateParameter(valid_402656518, JString, required = true,
                                      default = nil)
  if valid_402656518 != nil:
    section.add "applicationId", valid_402656518
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656519 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Security-Token", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Signature")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Signature", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Algorithm", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Date")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Date", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Credential")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Credential", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656527: Call_CreateCloudFormationChangeSet_402656515;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an AWS CloudFormation change set for the given application.
                                                                                         ## 
  let valid = call_402656527.validator(path, query, header, formData, body, _)
  let scheme = call_402656527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656527.makeUrl(scheme.get, call_402656527.host, call_402656527.base,
                                   call_402656527.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656527, uri, valid, _)

proc call*(call_402656528: Call_CreateCloudFormationChangeSet_402656515;
           applicationId: string; body: JsonNode): Recallable =
  ## createCloudFormationChangeSet
  ## Creates an AWS CloudFormation change set for the given application.
  ##   
                                                                        ## applicationId: string (required)
                                                                        ##                
                                                                        ## : 
                                                                        ## The 
                                                                        ## Amazon 
                                                                        ## Resource 
                                                                        ## Name 
                                                                        ## (ARN) 
                                                                        ## of 
                                                                        ## the 
                                                                        ## application.
  ##   
                                                                                       ## body: JObject (required)
  var path_402656529 = newJObject()
  var body_402656530 = newJObject()
  add(path_402656529, "applicationId", newJString(applicationId))
  if body != nil:
    body_402656530 = body
  result = call_402656528.call(path_402656529, nil, nil, nil, body_402656530)

var createCloudFormationChangeSet* = Call_CreateCloudFormationChangeSet_402656515(
    name: "createCloudFormationChangeSet", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/changesets",
    validator: validate_CreateCloudFormationChangeSet_402656516, base: "/",
    makeUrl: url_CreateCloudFormationChangeSet_402656517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationTemplate_402656531 = ref object of OpenApiRestCall_402656038
proc url_CreateCloudFormationTemplate_402656533(protocol: Scheme; host: string;
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

proc validate_CreateCloudFormationTemplate_402656532(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656534 = path.getOrDefault("applicationId")
  valid_402656534 = validateParameter(valid_402656534, JString, required = true,
                                      default = nil)
  if valid_402656534 != nil:
    section.add "applicationId", valid_402656534
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656535 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Security-Token", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Signature")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Signature", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Algorithm", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Date")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Date", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Credential")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Credential", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656543: Call_CreateCloudFormationTemplate_402656531;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an AWS CloudFormation template.
                                                                                         ## 
  let valid = call_402656543.validator(path, query, header, formData, body, _)
  let scheme = call_402656543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656543.makeUrl(scheme.get, call_402656543.host, call_402656543.base,
                                   call_402656543.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656543, uri, valid, _)

proc call*(call_402656544: Call_CreateCloudFormationTemplate_402656531;
           applicationId: string; body: JsonNode): Recallable =
  ## createCloudFormationTemplate
  ## Creates an AWS CloudFormation template.
  ##   applicationId: string (required)
                                            ##                : The Amazon Resource Name (ARN) of the application.
  ##   
                                                                                                                  ## body: JObject (required)
  var path_402656545 = newJObject()
  var body_402656546 = newJObject()
  add(path_402656545, "applicationId", newJString(applicationId))
  if body != nil:
    body_402656546 = body
  result = call_402656544.call(path_402656545, nil, nil, nil, body_402656546)

var createCloudFormationTemplate* = Call_CreateCloudFormationTemplate_402656531(
    name: "createCloudFormationTemplate", meth: HttpMethod.HttpPost,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates",
    validator: validate_CreateCloudFormationTemplate_402656532, base: "/",
    makeUrl: url_CreateCloudFormationTemplate_402656533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_402656547 = ref object of OpenApiRestCall_402656038
proc url_GetApplication_402656549(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplication_402656548(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656550 = path.getOrDefault("applicationId")
  valid_402656550 = validateParameter(valid_402656550, JString, required = true,
                                      default = nil)
  if valid_402656550 != nil:
    section.add "applicationId", valid_402656550
  result.add "path", section
  ## parameters in `query` object:
  ##   semanticVersion: JString
                                  ##                  : The semantic version of the application to get.
  section = newJObject()
  var valid_402656551 = query.getOrDefault("semanticVersion")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "semanticVersion", valid_402656551
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Security-Token", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Signature")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Signature", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Algorithm", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Date")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Date", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Credential")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Credential", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656559: Call_GetApplication_402656547; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the specified application.
                                                                                         ## 
  let valid = call_402656559.validator(path, query, header, formData, body, _)
  let scheme = call_402656559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656559.makeUrl(scheme.get, call_402656559.host, call_402656559.base,
                                   call_402656559.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656559, uri, valid, _)

proc call*(call_402656560: Call_GetApplication_402656547; applicationId: string;
           semanticVersion: string = ""): Recallable =
  ## getApplication
  ## Gets the specified application.
  ##   applicationId: string (required)
                                    ##                : The Amazon Resource Name (ARN) of the application.
  ##   
                                                                                                          ## semanticVersion: string
                                                                                                          ##                  
                                                                                                          ## : 
                                                                                                          ## The 
                                                                                                          ## semantic 
                                                                                                          ## version 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## application 
                                                                                                          ## to 
                                                                                                          ## get.
  var path_402656561 = newJObject()
  var query_402656562 = newJObject()
  add(path_402656561, "applicationId", newJString(applicationId))
  add(query_402656562, "semanticVersion", newJString(semanticVersion))
  result = call_402656560.call(path_402656561, query_402656562, nil, nil, nil)

var getApplication* = Call_GetApplication_402656547(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}", validator: validate_GetApplication_402656548,
    base: "/", makeUrl: url_GetApplication_402656549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_402656577 = ref object of OpenApiRestCall_402656038
proc url_UpdateApplication_402656579(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateApplication_402656578(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656580 = path.getOrDefault("applicationId")
  valid_402656580 = validateParameter(valid_402656580, JString, required = true,
                                      default = nil)
  if valid_402656580 != nil:
    section.add "applicationId", valid_402656580
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656581 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Security-Token", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Signature")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Signature", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Algorithm", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Date")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Date", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Credential")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Credential", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656589: Call_UpdateApplication_402656577;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified application.
                                                                                         ## 
  let valid = call_402656589.validator(path, query, header, formData, body, _)
  let scheme = call_402656589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656589.makeUrl(scheme.get, call_402656589.host, call_402656589.base,
                                   call_402656589.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656589, uri, valid, _)

proc call*(call_402656590: Call_UpdateApplication_402656577;
           applicationId: string; body: JsonNode): Recallable =
  ## updateApplication
  ## Updates the specified application.
  ##   applicationId: string (required)
                                       ##                : The Amazon Resource Name (ARN) of the application.
  ##   
                                                                                                             ## body: JObject (required)
  var path_402656591 = newJObject()
  var body_402656592 = newJObject()
  add(path_402656591, "applicationId", newJString(applicationId))
  if body != nil:
    body_402656592 = body
  result = call_402656590.call(path_402656591, nil, nil, nil, body_402656592)

var updateApplication* = Call_UpdateApplication_402656577(
    name: "updateApplication", meth: HttpMethod.HttpPatch,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}",
    validator: validate_UpdateApplication_402656578, base: "/",
    makeUrl: url_UpdateApplication_402656579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_402656563 = ref object of OpenApiRestCall_402656038
proc url_DeleteApplication_402656565(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteApplication_402656564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656566 = path.getOrDefault("applicationId")
  valid_402656566 = validateParameter(valid_402656566, JString, required = true,
                                      default = nil)
  if valid_402656566 != nil:
    section.add "applicationId", valid_402656566
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Security-Token", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Signature")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Signature", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Algorithm", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Date")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Date", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Credential")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Credential", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656574: Call_DeleteApplication_402656563;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified application.
                                                                                         ## 
  let valid = call_402656574.validator(path, query, header, formData, body, _)
  let scheme = call_402656574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656574.makeUrl(scheme.get, call_402656574.host, call_402656574.base,
                                   call_402656574.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656574, uri, valid, _)

proc call*(call_402656575: Call_DeleteApplication_402656563;
           applicationId: string): Recallable =
  ## deleteApplication
  ## Deletes the specified application.
  ##   applicationId: string (required)
                                       ##                : The Amazon Resource Name (ARN) of the application.
  var path_402656576 = newJObject()
  add(path_402656576, "applicationId", newJString(applicationId))
  result = call_402656575.call(path_402656576, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_402656563(
    name: "deleteApplication", meth: HttpMethod.HttpDelete,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}",
    validator: validate_DeleteApplication_402656564, base: "/",
    makeUrl: url_DeleteApplication_402656565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApplicationPolicy_402656607 = ref object of OpenApiRestCall_402656038
proc url_PutApplicationPolicy_402656609(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_PutApplicationPolicy_402656608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656610 = path.getOrDefault("applicationId")
  valid_402656610 = validateParameter(valid_402656610, JString, required = true,
                                      default = nil)
  if valid_402656610 != nil:
    section.add "applicationId", valid_402656610
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656611 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Security-Token", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Signature")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Signature", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Algorithm", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Date")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Date", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Credential")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Credential", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656619: Call_PutApplicationPolicy_402656607;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
                                                                                         ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
                                                                                         ##  Permissions</a>
                                                                                         ##  .
                                                                                         ## 
  let valid = call_402656619.validator(path, query, header, formData, body, _)
  let scheme = call_402656619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656619.makeUrl(scheme.get, call_402656619.host, call_402656619.base,
                                   call_402656619.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656619, uri, valid, _)

proc call*(call_402656620: Call_PutApplicationPolicy_402656607;
           applicationId: string; body: JsonNode): Recallable =
  ## putApplicationPolicy
  ## Sets the permission policy for an application. For the list of actions supported for this operation, see
                         ##  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application 
                         ##  Permissions</a>
                         ##  .
  ##   applicationId: string (required)
                              ##                : The Amazon Resource Name (ARN) of the application.
  ##   
                                                                                                    ## body: JObject (required)
  var path_402656621 = newJObject()
  var body_402656622 = newJObject()
  add(path_402656621, "applicationId", newJString(applicationId))
  if body != nil:
    body_402656622 = body
  result = call_402656620.call(path_402656621, nil, nil, nil, body_402656622)

var putApplicationPolicy* = Call_PutApplicationPolicy_402656607(
    name: "putApplicationPolicy", meth: HttpMethod.HttpPut,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_PutApplicationPolicy_402656608, base: "/",
    makeUrl: url_PutApplicationPolicy_402656609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationPolicy_402656593 = ref object of OpenApiRestCall_402656038
proc url_GetApplicationPolicy_402656595(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetApplicationPolicy_402656594(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656596 = path.getOrDefault("applicationId")
  valid_402656596 = validateParameter(valid_402656596, JString, required = true,
                                      default = nil)
  if valid_402656596 != nil:
    section.add "applicationId", valid_402656596
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Security-Token", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Signature")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Signature", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Algorithm", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Date")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Date", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Credential")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Credential", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656604: Call_GetApplicationPolicy_402656593;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the policy for the application.
                                                                                         ## 
  let valid = call_402656604.validator(path, query, header, formData, body, _)
  let scheme = call_402656604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656604.makeUrl(scheme.get, call_402656604.host, call_402656604.base,
                                   call_402656604.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656604, uri, valid, _)

proc call*(call_402656605: Call_GetApplicationPolicy_402656593;
           applicationId: string): Recallable =
  ## getApplicationPolicy
  ## Retrieves the policy for the application.
  ##   applicationId: string (required)
                                              ##                : The Amazon Resource Name (ARN) of the application.
  var path_402656606 = newJObject()
  add(path_402656606, "applicationId", newJString(applicationId))
  result = call_402656605.call(path_402656606, nil, nil, nil, nil)

var getApplicationPolicy* = Call_GetApplicationPolicy_402656593(
    name: "getApplicationPolicy", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/policy",
    validator: validate_GetApplicationPolicy_402656594, base: "/",
    makeUrl: url_GetApplicationPolicy_402656595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationTemplate_402656623 = ref object of OpenApiRestCall_402656038
proc url_GetCloudFormationTemplate_402656625(protocol: Scheme; host: string;
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

proc validate_GetCloudFormationTemplate_402656624(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets the specified AWS CloudFormation template.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   applicationId: JString (required)
                                 ##                : The Amazon Resource Name (ARN) of the application.
  ##   
                                                                                                       ## templateId: JString (required)
                                                                                                       ##             
                                                                                                       ## : 
                                                                                                       ## <p>The 
                                                                                                       ## UUID 
                                                                                                       ## returned 
                                                                                                       ## by 
                                                                                                       ## CreateCloudFormationTemplate.</p><p>Pattern: 
                                                                                                       ## [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}</p>
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `applicationId` field"
  var valid_402656626 = path.getOrDefault("applicationId")
  valid_402656626 = validateParameter(valid_402656626, JString, required = true,
                                      default = nil)
  if valid_402656626 != nil:
    section.add "applicationId", valid_402656626
  var valid_402656627 = path.getOrDefault("templateId")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true,
                                      default = nil)
  if valid_402656627 != nil:
    section.add "templateId", valid_402656627
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656635: Call_GetCloudFormationTemplate_402656623;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the specified AWS CloudFormation template.
                                                                                         ## 
  let valid = call_402656635.validator(path, query, header, formData, body, _)
  let scheme = call_402656635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656635.makeUrl(scheme.get, call_402656635.host, call_402656635.base,
                                   call_402656635.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656635, uri, valid, _)

proc call*(call_402656636: Call_GetCloudFormationTemplate_402656623;
           applicationId: string; templateId: string): Recallable =
  ## getCloudFormationTemplate
  ## Gets the specified AWS CloudFormation template.
  ##   applicationId: string (required)
                                                    ##                : The Amazon Resource Name (ARN) of the application.
  ##   
                                                                                                                          ## templateId: string (required)
                                                                                                                          ##             
                                                                                                                          ## : 
                                                                                                                          ## <p>The 
                                                                                                                          ## UUID 
                                                                                                                          ## returned 
                                                                                                                          ## by 
                                                                                                                          ## CreateCloudFormationTemplate.</p><p>Pattern: 
                                                                                                                          ## [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}</p>
  var path_402656637 = newJObject()
  add(path_402656637, "applicationId", newJString(applicationId))
  add(path_402656637, "templateId", newJString(templateId))
  result = call_402656636.call(path_402656637, nil, nil, nil, nil)

var getCloudFormationTemplate* = Call_GetCloudFormationTemplate_402656623(
    name: "getCloudFormationTemplate", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/templates/{templateId}",
    validator: validate_GetCloudFormationTemplate_402656624, base: "/",
    makeUrl: url_GetCloudFormationTemplate_402656625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationDependencies_402656638 = ref object of OpenApiRestCall_402656038
proc url_ListApplicationDependencies_402656640(protocol: Scheme; host: string;
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

proc validate_ListApplicationDependencies_402656639(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656641 = path.getOrDefault("applicationId")
  valid_402656641 = validateParameter(valid_402656641, JString, required = true,
                                      default = nil)
  if valid_402656641 != nil:
    section.add "applicationId", valid_402656641
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
                                  ##            : A token to specify where to start paginating.
  ##   
                                                                                               ## semanticVersion: JString
                                                                                               ##                  
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## semantic 
                                                                                               ## version 
                                                                                               ## of 
                                                                                               ## the 
                                                                                               ## application 
                                                                                               ## to 
                                                                                               ## get.
  ##   
                                                                                                      ## maxItems: JInt
                                                                                                      ##           
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## total 
                                                                                                      ## number 
                                                                                                      ## of 
                                                                                                      ## items 
                                                                                                      ## to 
                                                                                                      ## return.
  ##   
                                                                                                                ## NextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## Pagination 
                                                                                                                ## token
  ##   
                                                                                                                        ## MaxItems: JString
                                                                                                                        ##           
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## limit
  section = newJObject()
  var valid_402656642 = query.getOrDefault("nextToken")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "nextToken", valid_402656642
  var valid_402656643 = query.getOrDefault("semanticVersion")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "semanticVersion", valid_402656643
  var valid_402656644 = query.getOrDefault("maxItems")
  valid_402656644 = validateParameter(valid_402656644, JInt, required = false,
                                      default = nil)
  if valid_402656644 != nil:
    section.add "maxItems", valid_402656644
  var valid_402656645 = query.getOrDefault("NextToken")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "NextToken", valid_402656645
  var valid_402656646 = query.getOrDefault("MaxItems")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "MaxItems", valid_402656646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656647 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Security-Token", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Signature")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Signature", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Algorithm", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Date")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Date", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Credential")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Credential", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656654: Call_ListApplicationDependencies_402656638;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the list of applications nested in the containing application.
                                                                                         ## 
  let valid = call_402656654.validator(path, query, header, formData, body, _)
  let scheme = call_402656654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656654.makeUrl(scheme.get, call_402656654.host, call_402656654.base,
                                   call_402656654.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656654, uri, valid, _)

proc call*(call_402656655: Call_ListApplicationDependencies_402656638;
           applicationId: string; nextToken: string = "";
           semanticVersion: string = ""; maxItems: int = 0;
           NextToken: string = ""; MaxItems: string = ""): Recallable =
  ## listApplicationDependencies
  ## Retrieves the list of applications nested in the containing application.
  ##   
                                                                             ## applicationId: string (required)
                                                                             ##                
                                                                             ## : 
                                                                             ## The 
                                                                             ## Amazon 
                                                                             ## Resource 
                                                                             ## Name 
                                                                             ## (ARN) 
                                                                             ## of 
                                                                             ## the 
                                                                             ## application.
  ##   
                                                                                            ## nextToken: string
                                                                                            ##            
                                                                                            ## : 
                                                                                            ## A 
                                                                                            ## token 
                                                                                            ## to 
                                                                                            ## specify 
                                                                                            ## where 
                                                                                            ## to 
                                                                                            ## start 
                                                                                            ## paginating.
  ##   
                                                                                                          ## semanticVersion: string
                                                                                                          ##                  
                                                                                                          ## : 
                                                                                                          ## The 
                                                                                                          ## semantic 
                                                                                                          ## version 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## application 
                                                                                                          ## to 
                                                                                                          ## get.
  ##   
                                                                                                                 ## maxItems: int
                                                                                                                 ##           
                                                                                                                 ## : 
                                                                                                                 ## The 
                                                                                                                 ## total 
                                                                                                                 ## number 
                                                                                                                 ## of 
                                                                                                                 ## items 
                                                                                                                 ## to 
                                                                                                                 ## return.
  ##   
                                                                                                                           ## NextToken: string
                                                                                                                           ##            
                                                                                                                           ## : 
                                                                                                                           ## Pagination 
                                                                                                                           ## token
  ##   
                                                                                                                                   ## MaxItems: string
                                                                                                                                   ##           
                                                                                                                                   ## : 
                                                                                                                                   ## Pagination 
                                                                                                                                   ## limit
  var path_402656656 = newJObject()
  var query_402656657 = newJObject()
  add(path_402656656, "applicationId", newJString(applicationId))
  add(query_402656657, "nextToken", newJString(nextToken))
  add(query_402656657, "semanticVersion", newJString(semanticVersion))
  add(query_402656657, "maxItems", newJInt(maxItems))
  add(query_402656657, "NextToken", newJString(NextToken))
  add(query_402656657, "MaxItems", newJString(MaxItems))
  result = call_402656655.call(path_402656656, query_402656657, nil, nil, nil)

var listApplicationDependencies* = Call_ListApplicationDependencies_402656638(
    name: "listApplicationDependencies", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/dependencies",
    validator: validate_ListApplicationDependencies_402656639, base: "/",
    makeUrl: url_ListApplicationDependencies_402656640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationVersions_402656658 = ref object of OpenApiRestCall_402656038
proc url_ListApplicationVersions_402656660(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListApplicationVersions_402656659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656661 = path.getOrDefault("applicationId")
  valid_402656661 = validateParameter(valid_402656661, JString, required = true,
                                      default = nil)
  if valid_402656661 != nil:
    section.add "applicationId", valid_402656661
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
                                  ##            : A token to specify where to start paginating.
  ##   
                                                                                               ## maxItems: JInt
                                                                                               ##           
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## total 
                                                                                               ## number 
                                                                                               ## of 
                                                                                               ## items 
                                                                                               ## to 
                                                                                               ## return.
  ##   
                                                                                                         ## NextToken: JString
                                                                                                         ##            
                                                                                                         ## : 
                                                                                                         ## Pagination 
                                                                                                         ## token
  ##   
                                                                                                                 ## MaxItems: JString
                                                                                                                 ##           
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## limit
  section = newJObject()
  var valid_402656662 = query.getOrDefault("nextToken")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "nextToken", valid_402656662
  var valid_402656663 = query.getOrDefault("maxItems")
  valid_402656663 = validateParameter(valid_402656663, JInt, required = false,
                                      default = nil)
  if valid_402656663 != nil:
    section.add "maxItems", valid_402656663
  var valid_402656664 = query.getOrDefault("NextToken")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "NextToken", valid_402656664
  var valid_402656665 = query.getOrDefault("MaxItems")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "MaxItems", valid_402656665
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656666 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Security-Token", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Signature")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Signature", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Algorithm", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Date")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Date", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Credential")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Credential", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656673: Call_ListApplicationVersions_402656658;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists versions for the specified application.
                                                                                         ## 
  let valid = call_402656673.validator(path, query, header, formData, body, _)
  let scheme = call_402656673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656673.makeUrl(scheme.get, call_402656673.host, call_402656673.base,
                                   call_402656673.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656673, uri, valid, _)

proc call*(call_402656674: Call_ListApplicationVersions_402656658;
           applicationId: string; nextToken: string = ""; maxItems: int = 0;
           NextToken: string = ""; MaxItems: string = ""): Recallable =
  ## listApplicationVersions
  ## Lists versions for the specified application.
  ##   applicationId: string (required)
                                                  ##                : The Amazon Resource Name (ARN) of the application.
  ##   
                                                                                                                        ## nextToken: string
                                                                                                                        ##            
                                                                                                                        ## : 
                                                                                                                        ## A 
                                                                                                                        ## token 
                                                                                                                        ## to 
                                                                                                                        ## specify 
                                                                                                                        ## where 
                                                                                                                        ## to 
                                                                                                                        ## start 
                                                                                                                        ## paginating.
  ##   
                                                                                                                                      ## maxItems: int
                                                                                                                                      ##           
                                                                                                                                      ## : 
                                                                                                                                      ## The 
                                                                                                                                      ## total 
                                                                                                                                      ## number 
                                                                                                                                      ## of 
                                                                                                                                      ## items 
                                                                                                                                      ## to 
                                                                                                                                      ## return.
  ##   
                                                                                                                                                ## NextToken: string
                                                                                                                                                ##            
                                                                                                                                                ## : 
                                                                                                                                                ## Pagination 
                                                                                                                                                ## token
  ##   
                                                                                                                                                        ## MaxItems: string
                                                                                                                                                        ##           
                                                                                                                                                        ## : 
                                                                                                                                                        ## Pagination 
                                                                                                                                                        ## limit
  var path_402656675 = newJObject()
  var query_402656676 = newJObject()
  add(path_402656675, "applicationId", newJString(applicationId))
  add(query_402656676, "nextToken", newJString(nextToken))
  add(query_402656676, "maxItems", newJInt(maxItems))
  add(query_402656676, "NextToken", newJString(NextToken))
  add(query_402656676, "MaxItems", newJString(MaxItems))
  result = call_402656674.call(path_402656675, query_402656676, nil, nil, nil)

var listApplicationVersions* = Call_ListApplicationVersions_402656658(
    name: "listApplicationVersions", meth: HttpMethod.HttpGet,
    host: "serverlessrepo.amazonaws.com",
    route: "/applications/{applicationId}/versions",
    validator: validate_ListApplicationVersions_402656659, base: "/",
    makeUrl: url_ListApplicationVersions_402656660,
    schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}