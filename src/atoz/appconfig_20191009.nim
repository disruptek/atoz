
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon AppConfig
## version: 2019-10-09
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS AppConfig</fullname> <p>Use AWS AppConfig, a capability of AWS Systems Manager, to create, manage, and quickly deploy application configurations. AppConfig supports controlled deployments to applications of any size and includes built-in validation checks and monitoring. You can use AppConfig with applications hosted on Amazon EC2 instances, AWS Lambda, containers, mobile applications, or IoT devices.</p> <p>To prevent errors when deploying application configurations, especially for production systems where a simple typo could cause an unexpected outage, AppConfig includes validators. A validator provides a syntactic or semantic check to ensure that the configuration you want to deploy works as intended. To validate your application configuration data, you provide a schema or a Lambda function that runs against the configuration. The configuration deployment or update can only proceed when the configuration data is valid.</p> <p>During a configuration deployment, AppConfig monitors the application to ensure that the deployment is successful. If the system encounters an error, AppConfig rolls back the change to minimize impact for your application users. You can configure a deployment strategy for each application or environment that includes deployment criteria, including velocity, bake time, and alarms to monitor. Similar to error monitoring, if a deployment triggers an alarm, AppConfig automatically rolls back to the previous version. </p> <p>AppConfig supports multiple use cases. Here are some examples.</p> <ul> <li> <p> <b>Application tuning</b>: Use AppConfig to carefully introduce changes to your application that can only be tested with production traffic.</p> </li> <li> <p> <b>Feature toggle</b>: Use AppConfig to turn on new features that require a timely deployment, such as a product launch or announcement. </p> </li> <li> <p> <b>User membership</b>: Use AppConfig to allow premium subscribers to access paid content. </p> </li> <li> <p> <b>Operational issues</b>: Use AppConfig to reduce stress on your application when a dependency or other external factor impacts the system.</p> </li> </ul> <p>This reference is intended to be used with the <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/appconfig.html">AWS AppConfig User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/appconfig/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "appconfig.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appconfig.ap-southeast-1.amazonaws.com", "us-west-2": "appconfig.us-west-2.amazonaws.com", "eu-west-2": "appconfig.eu-west-2.amazonaws.com", "ap-northeast-3": "appconfig.ap-northeast-3.amazonaws.com", "eu-central-1": "appconfig.eu-central-1.amazonaws.com", "us-east-2": "appconfig.us-east-2.amazonaws.com", "us-east-1": "appconfig.us-east-1.amazonaws.com", "cn-northwest-1": "appconfig.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "appconfig.ap-south-1.amazonaws.com", "eu-north-1": "appconfig.eu-north-1.amazonaws.com", "ap-northeast-2": "appconfig.ap-northeast-2.amazonaws.com", "us-west-1": "appconfig.us-west-1.amazonaws.com", "us-gov-east-1": "appconfig.us-gov-east-1.amazonaws.com", "eu-west-3": "appconfig.eu-west-3.amazonaws.com", "cn-north-1": "appconfig.cn-north-1.amazonaws.com.cn", "sa-east-1": "appconfig.sa-east-1.amazonaws.com", "eu-west-1": "appconfig.eu-west-1.amazonaws.com", "us-gov-west-1": "appconfig.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appconfig.ap-southeast-2.amazonaws.com", "ca-central-1": "appconfig.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "appconfig.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "appconfig.ap-southeast-1.amazonaws.com",
      "us-west-2": "appconfig.us-west-2.amazonaws.com",
      "eu-west-2": "appconfig.eu-west-2.amazonaws.com",
      "ap-northeast-3": "appconfig.ap-northeast-3.amazonaws.com",
      "eu-central-1": "appconfig.eu-central-1.amazonaws.com",
      "us-east-2": "appconfig.us-east-2.amazonaws.com",
      "us-east-1": "appconfig.us-east-1.amazonaws.com",
      "cn-northwest-1": "appconfig.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "appconfig.ap-south-1.amazonaws.com",
      "eu-north-1": "appconfig.eu-north-1.amazonaws.com",
      "ap-northeast-2": "appconfig.ap-northeast-2.amazonaws.com",
      "us-west-1": "appconfig.us-west-1.amazonaws.com",
      "us-gov-east-1": "appconfig.us-gov-east-1.amazonaws.com",
      "eu-west-3": "appconfig.eu-west-3.amazonaws.com",
      "cn-north-1": "appconfig.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "appconfig.sa-east-1.amazonaws.com",
      "eu-west-1": "appconfig.eu-west-1.amazonaws.com",
      "us-gov-west-1": "appconfig.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "appconfig.ap-southeast-2.amazonaws.com",
      "ca-central-1": "appconfig.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "appconfig"
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
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
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
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
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
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ##   
                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656486 = newJObject()
  if body != nil:
    body_402656486 = body
  result = call_402656485.call(nil, nil, nil, nil, body_402656486)

var createApplication* = Call_CreateApplication_402656473(
    name: "createApplication", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/applications",
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
  ## List all applications in your AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   max_results: JInt
                                  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   
                                                                                                                                                                                                                ## MaxResults: JString
                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                ## limit
  ##   
                                                                                                                                                                                                                        ## NextToken: JString
                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                        ## token
  ##   
                                                                                                                                                                                                                                ## next_token: JString
                                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                ## A 
                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                ## start 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## list. 
                                                                                                                                                                                                                                ## Use 
                                                                                                                                                                                                                                ## this 
                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                ## get 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## next 
                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                ## results.
  section = newJObject()
  var valid_402656372 = query.getOrDefault("max_results")
  valid_402656372 = validateParameter(valid_402656372, JInt, required = false,
                                      default = nil)
  if valid_402656372 != nil:
    section.add "max_results", valid_402656372
  var valid_402656373 = query.getOrDefault("MaxResults")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "MaxResults", valid_402656373
  var valid_402656374 = query.getOrDefault("NextToken")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "NextToken", valid_402656374
  var valid_402656375 = query.getOrDefault("next_token")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "next_token", valid_402656375
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
  ## List all applications in your AWS account.
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

proc call*(call_402656445: Call_ListApplications_402656288; maxResults: int = 0;
           MaxResults: string = ""; NextToken: string = "";
           nextToken: string = ""): Recallable =
  ## listApplications
  ## List all applications in your AWS account.
  ##   maxResults: int
                                               ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   
                                                                                                                                                                                                                            ## MaxResults: string
                                                                                                                                                                                                                            ##             
                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                            ## limit
  ##   
                                                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                                                    ## token
  ##   
                                                                                                                                                                                                                                            ## nextToken: string
                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## A 
                                                                                                                                                                                                                                            ## token 
                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                            ## start 
                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                            ## list. 
                                                                                                                                                                                                                                            ## Use 
                                                                                                                                                                                                                                            ## this 
                                                                                                                                                                                                                                            ## token 
                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                            ## get 
                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                            ## next 
                                                                                                                                                                                                                                            ## set 
                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                            ## results.
  var query_402656446 = newJObject()
  add(query_402656446, "max_results", newJInt(maxResults))
  add(query_402656446, "MaxResults", newJString(MaxResults))
  add(query_402656446, "NextToken", newJString(NextToken))
  add(query_402656446, "next_token", newJString(nextToken))
  result = call_402656445.call(nil, query_402656446, nil, nil, nil)

var listApplications* = Call_ListApplications_402656288(
    name: "listApplications", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/applications",
    validator: validate_ListApplications_402656289, base: "/",
    makeUrl: url_ListApplications_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationProfile_402656517 = ref object of OpenApiRestCall_402656038
proc url_CreateConfigurationProfile_402656519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/configurationprofiles")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConfigurationProfile_402656518(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656520 = path.getOrDefault("ApplicationId")
  valid_402656520 = validateParameter(valid_402656520, JString, required = true,
                                      default = nil)
  if valid_402656520 != nil:
    section.add "ApplicationId", valid_402656520
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
  var valid_402656521 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Security-Token", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Signature")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Signature", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Algorithm", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Date")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Date", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Credential")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Credential", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656527
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

proc call*(call_402656529: Call_CreateConfigurationProfile_402656517;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656529.validator(path, query, header, formData, body, _)
  let scheme = call_402656529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656529.makeUrl(scheme.get, call_402656529.host, call_402656529.base,
                                   call_402656529.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656529, uri, valid, _)

proc call*(call_402656530: Call_CreateConfigurationProfile_402656517;
           ApplicationId: string; body: JsonNode): Recallable =
  ## createConfigurationProfile
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## ApplicationId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## application 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## ID.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var path_402656531 = newJObject()
  var body_402656532 = newJObject()
  add(path_402656531, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_402656532 = body
  result = call_402656530.call(path_402656531, nil, nil, nil, body_402656532)

var createConfigurationProfile* = Call_CreateConfigurationProfile_402656517(
    name: "createConfigurationProfile", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_CreateConfigurationProfile_402656518, base: "/",
    makeUrl: url_CreateConfigurationProfile_402656519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationProfiles_402656487 = ref object of OpenApiRestCall_402656038
proc url_ListConfigurationProfiles_402656489(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/configurationprofiles")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListConfigurationProfiles_402656488(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the configuration profiles for an application.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656501 = path.getOrDefault("ApplicationId")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true,
                                      default = nil)
  if valid_402656501 != nil:
    section.add "ApplicationId", valid_402656501
  result.add "path", section
  ## parameters in `query` object:
  ##   max_results: JInt
                                  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   
                                                                                                                                                                                                                ## MaxResults: JString
                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                ## limit
  ##   
                                                                                                                                                                                                                        ## NextToken: JString
                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                        ## token
  ##   
                                                                                                                                                                                                                                ## next_token: JString
                                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                ## A 
                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                ## start 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## list. 
                                                                                                                                                                                                                                ## Use 
                                                                                                                                                                                                                                ## this 
                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                ## get 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## next 
                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                ## results.
  section = newJObject()
  var valid_402656502 = query.getOrDefault("max_results")
  valid_402656502 = validateParameter(valid_402656502, JInt, required = false,
                                      default = nil)
  if valid_402656502 != nil:
    section.add "max_results", valid_402656502
  var valid_402656503 = query.getOrDefault("MaxResults")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "MaxResults", valid_402656503
  var valid_402656504 = query.getOrDefault("NextToken")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "NextToken", valid_402656504
  var valid_402656505 = query.getOrDefault("next_token")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "next_token", valid_402656505
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
  var valid_402656506 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Security-Token", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Signature")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Signature", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Algorithm", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Date")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Date", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Credential")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Credential", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656513: Call_ListConfigurationProfiles_402656487;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the configuration profiles for an application.
                                                                                         ## 
  let valid = call_402656513.validator(path, query, header, formData, body, _)
  let scheme = call_402656513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656513.makeUrl(scheme.get, call_402656513.host, call_402656513.base,
                                   call_402656513.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656513, uri, valid, _)

proc call*(call_402656514: Call_ListConfigurationProfiles_402656487;
           ApplicationId: string; maxResults: int = 0; MaxResults: string = "";
           NextToken: string = ""; nextToken: string = ""): Recallable =
  ## listConfigurationProfiles
  ## Lists the configuration profiles for an application.
  ##   maxResults: int
                                                         ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   
                                                                                                                                                                                                                                      ## ApplicationId: string (required)
                                                                                                                                                                                                                                      ##                
                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                      ## application 
                                                                                                                                                                                                                                      ## ID.
  ##   
                                                                                                                                                                                                                                            ## MaxResults: string
                                                                                                                                                                                                                                            ##             
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                                            ## limit
  ##   
                                                                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                                                                    ## token
  ##   
                                                                                                                                                                                                                                                            ## nextToken: string
                                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                            ## A 
                                                                                                                                                                                                                                                            ## token 
                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                            ## start 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## list. 
                                                                                                                                                                                                                                                            ## Use 
                                                                                                                                                                                                                                                            ## this 
                                                                                                                                                                                                                                                            ## token 
                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                            ## get 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## next 
                                                                                                                                                                                                                                                            ## set 
                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                            ## results.
  var path_402656515 = newJObject()
  var query_402656516 = newJObject()
  add(query_402656516, "max_results", newJInt(maxResults))
  add(path_402656515, "ApplicationId", newJString(ApplicationId))
  add(query_402656516, "MaxResults", newJString(MaxResults))
  add(query_402656516, "NextToken", newJString(NextToken))
  add(query_402656516, "next_token", newJString(nextToken))
  result = call_402656514.call(path_402656515, query_402656516, nil, nil, nil)

var listConfigurationProfiles* = Call_ListConfigurationProfiles_402656487(
    name: "listConfigurationProfiles", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_ListConfigurationProfiles_402656488, base: "/",
    makeUrl: url_ListConfigurationProfiles_402656489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentStrategy_402656550 = ref object of OpenApiRestCall_402656038
proc url_CreateDeploymentStrategy_402656552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeploymentStrategy_402656551(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
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
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
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

proc call*(call_402656561: Call_CreateDeploymentStrategy_402656550;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_CreateDeploymentStrategy_402656550;
           body: JsonNode): Recallable =
  ## createDeploymentStrategy
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   
                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var createDeploymentStrategy* = Call_CreateDeploymentStrategy_402656550(
    name: "createDeploymentStrategy", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_CreateDeploymentStrategy_402656551, base: "/",
    makeUrl: url_CreateDeploymentStrategy_402656552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentStrategies_402656533 = ref object of OpenApiRestCall_402656038
proc url_ListDeploymentStrategies_402656535(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentStrategies_402656534(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List deployment strategies.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   max_results: JInt
                                  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   
                                                                                                                                                                                                                ## MaxResults: JString
                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                ## limit
  ##   
                                                                                                                                                                                                                        ## NextToken: JString
                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                        ## token
  ##   
                                                                                                                                                                                                                                ## next_token: JString
                                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                ## A 
                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                ## start 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## list. 
                                                                                                                                                                                                                                ## Use 
                                                                                                                                                                                                                                ## this 
                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                ## get 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## next 
                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                ## results.
  section = newJObject()
  var valid_402656536 = query.getOrDefault("max_results")
  valid_402656536 = validateParameter(valid_402656536, JInt, required = false,
                                      default = nil)
  if valid_402656536 != nil:
    section.add "max_results", valid_402656536
  var valid_402656537 = query.getOrDefault("MaxResults")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "MaxResults", valid_402656537
  var valid_402656538 = query.getOrDefault("NextToken")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "NextToken", valid_402656538
  var valid_402656539 = query.getOrDefault("next_token")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "next_token", valid_402656539
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
  var valid_402656540 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Security-Token", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Signature")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Signature", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Algorithm", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Date")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Date", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Credential")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Credential", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656547: Call_ListDeploymentStrategies_402656533;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List deployment strategies.
                                                                                         ## 
  let valid = call_402656547.validator(path, query, header, formData, body, _)
  let scheme = call_402656547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656547.makeUrl(scheme.get, call_402656547.host, call_402656547.base,
                                   call_402656547.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656547, uri, valid, _)

proc call*(call_402656548: Call_ListDeploymentStrategies_402656533;
           maxResults: int = 0; MaxResults: string = ""; NextToken: string = "";
           nextToken: string = ""): Recallable =
  ## listDeploymentStrategies
  ## List deployment strategies.
  ##   maxResults: int
                                ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   
                                                                                                                                                                                                             ## MaxResults: string
                                                                                                                                                                                                             ##             
                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                                                     ## NextToken: string
                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                                     ## token
  ##   
                                                                                                                                                                                                                             ## nextToken: string
                                                                                                                                                                                                                             ##            
                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                             ## A 
                                                                                                                                                                                                                             ## token 
                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                             ## start 
                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                             ## list. 
                                                                                                                                                                                                                             ## Use 
                                                                                                                                                                                                                             ## this 
                                                                                                                                                                                                                             ## token 
                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                             ## get 
                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                             ## next 
                                                                                                                                                                                                                             ## set 
                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                             ## results.
  var query_402656549 = newJObject()
  add(query_402656549, "max_results", newJInt(maxResults))
  add(query_402656549, "MaxResults", newJString(MaxResults))
  add(query_402656549, "NextToken", newJString(NextToken))
  add(query_402656549, "next_token", newJString(nextToken))
  result = call_402656548.call(nil, query_402656549, nil, nil, nil)

var listDeploymentStrategies* = Call_ListDeploymentStrategies_402656533(
    name: "listDeploymentStrategies", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_ListDeploymentStrategies_402656534, base: "/",
    makeUrl: url_ListDeploymentStrategies_402656535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironment_402656583 = ref object of OpenApiRestCall_402656038
proc url_CreateEnvironment_402656585(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/environments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateEnvironment_402656584(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656586 = path.getOrDefault("ApplicationId")
  valid_402656586 = validateParameter(valid_402656586, JString, required = true,
                                      default = nil)
  if valid_402656586 != nil:
    section.add "ApplicationId", valid_402656586
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
  var valid_402656587 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Security-Token", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Signature")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Signature", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Algorithm", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Date")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Date", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Credential")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Credential", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656593
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

proc call*(call_402656595: Call_CreateEnvironment_402656583;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
                                                                                         ## 
  let valid = call_402656595.validator(path, query, header, formData, body, _)
  let scheme = call_402656595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656595.makeUrl(scheme.get, call_402656595.host, call_402656595.base,
                                   call_402656595.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656595, uri, valid, _)

proc call*(call_402656596: Call_CreateEnvironment_402656583;
           ApplicationId: string; body: JsonNode): Recallable =
  ## createEnvironment
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## ApplicationId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## application 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## ID.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var path_402656597 = newJObject()
  var body_402656598 = newJObject()
  add(path_402656597, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_402656598 = body
  result = call_402656596.call(path_402656597, nil, nil, nil, body_402656598)

var createEnvironment* = Call_CreateEnvironment_402656583(
    name: "createEnvironment", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_CreateEnvironment_402656584, base: "/",
    makeUrl: url_CreateEnvironment_402656585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_402656564 = ref object of OpenApiRestCall_402656038
proc url_ListEnvironments_402656566(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/environments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListEnvironments_402656565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the environments for an application.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656567 = path.getOrDefault("ApplicationId")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true,
                                      default = nil)
  if valid_402656567 != nil:
    section.add "ApplicationId", valid_402656567
  result.add "path", section
  ## parameters in `query` object:
  ##   max_results: JInt
                                  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   
                                                                                                                                                                                                                ## MaxResults: JString
                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                ## limit
  ##   
                                                                                                                                                                                                                        ## NextToken: JString
                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                        ## token
  ##   
                                                                                                                                                                                                                                ## next_token: JString
                                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                ## A 
                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                ## start 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## list. 
                                                                                                                                                                                                                                ## Use 
                                                                                                                                                                                                                                ## this 
                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                ## get 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## next 
                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                ## results.
  section = newJObject()
  var valid_402656568 = query.getOrDefault("max_results")
  valid_402656568 = validateParameter(valid_402656568, JInt, required = false,
                                      default = nil)
  if valid_402656568 != nil:
    section.add "max_results", valid_402656568
  var valid_402656569 = query.getOrDefault("MaxResults")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "MaxResults", valid_402656569
  var valid_402656570 = query.getOrDefault("NextToken")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "NextToken", valid_402656570
  var valid_402656571 = query.getOrDefault("next_token")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "next_token", valid_402656571
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
  var valid_402656572 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Security-Token", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Signature")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Signature", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Algorithm", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Date")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Date", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Credential")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Credential", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656579: Call_ListEnvironments_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the environments for an application.
                                                                                         ## 
  let valid = call_402656579.validator(path, query, header, formData, body, _)
  let scheme = call_402656579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656579.makeUrl(scheme.get, call_402656579.host, call_402656579.base,
                                   call_402656579.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656579, uri, valid, _)

proc call*(call_402656580: Call_ListEnvironments_402656564;
           ApplicationId: string; maxResults: int = 0; MaxResults: string = "";
           NextToken: string = ""; nextToken: string = ""): Recallable =
  ## listEnvironments
  ## List the environments for an application.
  ##   maxResults: int
                                              ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   
                                                                                                                                                                                                                           ## ApplicationId: string (required)
                                                                                                                                                                                                                           ##                
                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                           ## application 
                                                                                                                                                                                                                           ## ID.
  ##   
                                                                                                                                                                                                                                 ## MaxResults: string
                                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                                 ## limit
  ##   
                                                                                                                                                                                                                                         ## NextToken: string
                                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                                         ## token
  ##   
                                                                                                                                                                                                                                                 ## nextToken: string
                                                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                 ## A 
                                                                                                                                                                                                                                                 ## token 
                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                 ## start 
                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                 ## list. 
                                                                                                                                                                                                                                                 ## Use 
                                                                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                                                                 ## token 
                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                 ## get 
                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                 ## next 
                                                                                                                                                                                                                                                 ## set 
                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                 ## results.
  var path_402656581 = newJObject()
  var query_402656582 = newJObject()
  add(query_402656582, "max_results", newJInt(maxResults))
  add(path_402656581, "ApplicationId", newJString(ApplicationId))
  add(query_402656582, "MaxResults", newJString(MaxResults))
  add(query_402656582, "NextToken", newJString(NextToken))
  add(query_402656582, "next_token", newJString(nextToken))
  result = call_402656580.call(path_402656581, query_402656582, nil, nil, nil)

var listEnvironments* = Call_ListEnvironments_402656564(
    name: "listEnvironments", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_ListEnvironments_402656565, base: "/",
    makeUrl: url_ListEnvironments_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_402656599 = ref object of OpenApiRestCall_402656038
proc url_GetApplication_402656601(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApplication_402656600(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve information about an application.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The ID of the application you want to get.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656602 = path.getOrDefault("ApplicationId")
  valid_402656602 = validateParameter(valid_402656602, JString, required = true,
                                      default = nil)
  if valid_402656602 != nil:
    section.add "ApplicationId", valid_402656602
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
  var valid_402656603 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Security-Token", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Signature")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Signature", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Algorithm", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Date")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Date", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Credential")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Credential", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656610: Call_GetApplication_402656599; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about an application.
                                                                                         ## 
  let valid = call_402656610.validator(path, query, header, formData, body, _)
  let scheme = call_402656610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656610.makeUrl(scheme.get, call_402656610.host, call_402656610.base,
                                   call_402656610.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656610, uri, valid, _)

proc call*(call_402656611: Call_GetApplication_402656599; ApplicationId: string): Recallable =
  ## getApplication
  ## Retrieve information about an application.
  ##   ApplicationId: string (required)
                                               ##                : The ID of the application you want to get.
  var path_402656612 = newJObject()
  add(path_402656612, "ApplicationId", newJString(ApplicationId))
  result = call_402656611.call(path_402656612, nil, nil, nil, nil)

var getApplication* = Call_GetApplication_402656599(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_GetApplication_402656600,
    base: "/", makeUrl: url_GetApplication_402656601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_402656627 = ref object of OpenApiRestCall_402656038
proc url_UpdateApplication_402656629(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApplication_402656628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an application.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656630 = path.getOrDefault("ApplicationId")
  valid_402656630 = validateParameter(valid_402656630, JString, required = true,
                                      default = nil)
  if valid_402656630 != nil:
    section.add "ApplicationId", valid_402656630
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
  var valid_402656631 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Security-Token", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Signature")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Signature", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Algorithm", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Date")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Date", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Credential")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Credential", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656637
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

proc call*(call_402656639: Call_UpdateApplication_402656627;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an application.
                                                                                         ## 
  let valid = call_402656639.validator(path, query, header, formData, body, _)
  let scheme = call_402656639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656639.makeUrl(scheme.get, call_402656639.host, call_402656639.base,
                                   call_402656639.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656639, uri, valid, _)

proc call*(call_402656640: Call_UpdateApplication_402656627;
           ApplicationId: string; body: JsonNode): Recallable =
  ## updateApplication
  ## Updates an application.
  ##   ApplicationId: string (required)
                            ##                : The application ID.
  ##   body: JObject (required)
  var path_402656641 = newJObject()
  var body_402656642 = newJObject()
  add(path_402656641, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_402656642 = body
  result = call_402656640.call(path_402656641, nil, nil, nil, body_402656642)

var updateApplication* = Call_UpdateApplication_402656627(
    name: "updateApplication", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}",
    validator: validate_UpdateApplication_402656628, base: "/",
    makeUrl: url_UpdateApplication_402656629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_402656613 = ref object of OpenApiRestCall_402656038
proc url_DeleteApplication_402656615(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApplication_402656614(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete an application. Deleting an application does not delete a configuration from a host.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The ID of the application to delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656616 = path.getOrDefault("ApplicationId")
  valid_402656616 = validateParameter(valid_402656616, JString, required = true,
                                      default = nil)
  if valid_402656616 != nil:
    section.add "ApplicationId", valid_402656616
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
  var valid_402656617 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Security-Token", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Signature")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Signature", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Algorithm", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Date")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Date", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Credential")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Credential", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656624: Call_DeleteApplication_402656613;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an application. Deleting an application does not delete a configuration from a host.
                                                                                         ## 
  let valid = call_402656624.validator(path, query, header, formData, body, _)
  let scheme = call_402656624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656624.makeUrl(scheme.get, call_402656624.host, call_402656624.base,
                                   call_402656624.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656624, uri, valid, _)

proc call*(call_402656625: Call_DeleteApplication_402656613;
           ApplicationId: string): Recallable =
  ## deleteApplication
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ##   
                                                                                                ## ApplicationId: string (required)
                                                                                                ##                
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## ID 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## application 
                                                                                                ## to 
                                                                                                ## delete.
  var path_402656626 = newJObject()
  add(path_402656626, "ApplicationId", newJString(ApplicationId))
  result = call_402656625.call(path_402656626, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_402656613(
    name: "deleteApplication", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}",
    validator: validate_DeleteApplication_402656614, base: "/",
    makeUrl: url_DeleteApplication_402656615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationProfile_402656643 = ref object of OpenApiRestCall_402656038
proc url_GetConfigurationProfile_402656645(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "ConfigurationProfileId" in path,
         "`ConfigurationProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/configurationprofiles/"),
                 (kind: VariableSegment, value: "ConfigurationProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationProfile_402656644(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve information about a configuration profile.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The ID of the application that includes the configuration profile you want to get.
  ##   
                                                                                                                                       ## ConfigurationProfileId: JString (required)
                                                                                                                                       ##                         
                                                                                                                                       ## : 
                                                                                                                                       ## The 
                                                                                                                                       ## ID 
                                                                                                                                       ## of 
                                                                                                                                       ## the 
                                                                                                                                       ## configuration 
                                                                                                                                       ## profile 
                                                                                                                                       ## you 
                                                                                                                                       ## want 
                                                                                                                                       ## to 
                                                                                                                                       ## get.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656646 = path.getOrDefault("ApplicationId")
  valid_402656646 = validateParameter(valid_402656646, JString, required = true,
                                      default = nil)
  if valid_402656646 != nil:
    section.add "ApplicationId", valid_402656646
  var valid_402656647 = path.getOrDefault("ConfigurationProfileId")
  valid_402656647 = validateParameter(valid_402656647, JString, required = true,
                                      default = nil)
  if valid_402656647 != nil:
    section.add "ConfigurationProfileId", valid_402656647
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
  var valid_402656648 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Security-Token", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Signature")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Signature", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Algorithm", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Date")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Date", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Credential")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Credential", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656655: Call_GetConfigurationProfile_402656643;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a configuration profile.
                                                                                         ## 
  let valid = call_402656655.validator(path, query, header, formData, body, _)
  let scheme = call_402656655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656655.makeUrl(scheme.get, call_402656655.host, call_402656655.base,
                                   call_402656655.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656655, uri, valid, _)

proc call*(call_402656656: Call_GetConfigurationProfile_402656643;
           ApplicationId: string; ConfigurationProfileId: string): Recallable =
  ## getConfigurationProfile
  ## Retrieve information about a configuration profile.
  ##   ApplicationId: string (required)
                                                        ##                : The ID of the application that includes the configuration profile you want to get.
  ##   
                                                                                                                                                              ## ConfigurationProfileId: string (required)
                                                                                                                                                              ##                         
                                                                                                                                                              ## : 
                                                                                                                                                              ## The 
                                                                                                                                                              ## ID 
                                                                                                                                                              ## of 
                                                                                                                                                              ## the 
                                                                                                                                                              ## configuration 
                                                                                                                                                              ## profile 
                                                                                                                                                              ## you 
                                                                                                                                                              ## want 
                                                                                                                                                              ## to 
                                                                                                                                                              ## get.
  var path_402656657 = newJObject()
  add(path_402656657, "ApplicationId", newJString(ApplicationId))
  add(path_402656657, "ConfigurationProfileId",
      newJString(ConfigurationProfileId))
  result = call_402656656.call(path_402656657, nil, nil, nil, nil)

var getConfigurationProfile* = Call_GetConfigurationProfile_402656643(
    name: "getConfigurationProfile", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_GetConfigurationProfile_402656644, base: "/",
    makeUrl: url_GetConfigurationProfile_402656645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationProfile_402656673 = ref object of OpenApiRestCall_402656038
proc url_UpdateConfigurationProfile_402656675(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "ConfigurationProfileId" in path,
         "`ConfigurationProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/configurationprofiles/"),
                 (kind: VariableSegment, value: "ConfigurationProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfigurationProfile_402656674(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates a configuration profile.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID.
  ##   
                                                                        ## ConfigurationProfileId: JString (required)
                                                                        ##                         
                                                                        ## : 
                                                                        ## The ID of the 
                                                                        ## configuration 
                                                                        ## profile.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656676 = path.getOrDefault("ApplicationId")
  valid_402656676 = validateParameter(valid_402656676, JString, required = true,
                                      default = nil)
  if valid_402656676 != nil:
    section.add "ApplicationId", valid_402656676
  var valid_402656677 = path.getOrDefault("ConfigurationProfileId")
  valid_402656677 = validateParameter(valid_402656677, JString, required = true,
                                      default = nil)
  if valid_402656677 != nil:
    section.add "ConfigurationProfileId", valid_402656677
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
  var valid_402656678 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Security-Token", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Signature")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Signature", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Algorithm", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Date")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Date", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Credential")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Credential", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656684
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

proc call*(call_402656686: Call_UpdateConfigurationProfile_402656673;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a configuration profile.
                                                                                         ## 
  let valid = call_402656686.validator(path, query, header, formData, body, _)
  let scheme = call_402656686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656686.makeUrl(scheme.get, call_402656686.host, call_402656686.base,
                                   call_402656686.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656686, uri, valid, _)

proc call*(call_402656687: Call_UpdateConfigurationProfile_402656673;
           ApplicationId: string; body: JsonNode; ConfigurationProfileId: string): Recallable =
  ## updateConfigurationProfile
  ## Updates a configuration profile.
  ##   ApplicationId: string (required)
                                     ##                : The application ID.
  ##   
                                                                            ## body: JObject (required)
  ##   
                                                                                                       ## ConfigurationProfileId: string (required)
                                                                                                       ##                         
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## ID 
                                                                                                       ## of 
                                                                                                       ## the 
                                                                                                       ## configuration 
                                                                                                       ## profile.
  var path_402656688 = newJObject()
  var body_402656689 = newJObject()
  add(path_402656688, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_402656689 = body
  add(path_402656688, "ConfigurationProfileId",
      newJString(ConfigurationProfileId))
  result = call_402656687.call(path_402656688, nil, nil, nil, body_402656689)

var updateConfigurationProfile* = Call_UpdateConfigurationProfile_402656673(
    name: "updateConfigurationProfile", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_UpdateConfigurationProfile_402656674, base: "/",
    makeUrl: url_UpdateConfigurationProfile_402656675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationProfile_402656658 = ref object of OpenApiRestCall_402656038
proc url_DeleteConfigurationProfile_402656660(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "ConfigurationProfileId" in path,
         "`ConfigurationProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/configurationprofiles/"),
                 (kind: VariableSegment, value: "ConfigurationProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationProfile_402656659(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID that includes the configuration profile you want to delete.
  ##   
                                                                                                                                   ## ConfigurationProfileId: JString (required)
                                                                                                                                   ##                         
                                                                                                                                   ## : 
                                                                                                                                   ## The 
                                                                                                                                   ## ID 
                                                                                                                                   ## of 
                                                                                                                                   ## the 
                                                                                                                                   ## configuration 
                                                                                                                                   ## profile 
                                                                                                                                   ## you 
                                                                                                                                   ## want 
                                                                                                                                   ## to 
                                                                                                                                   ## delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656661 = path.getOrDefault("ApplicationId")
  valid_402656661 = validateParameter(valid_402656661, JString, required = true,
                                      default = nil)
  if valid_402656661 != nil:
    section.add "ApplicationId", valid_402656661
  var valid_402656662 = path.getOrDefault("ConfigurationProfileId")
  valid_402656662 = validateParameter(valid_402656662, JString, required = true,
                                      default = nil)
  if valid_402656662 != nil:
    section.add "ConfigurationProfileId", valid_402656662
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
  var valid_402656663 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Security-Token", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Signature")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Signature", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Algorithm", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Date")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Date", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Credential")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Credential", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656670: Call_DeleteConfigurationProfile_402656658;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
                                                                                         ## 
  let valid = call_402656670.validator(path, query, header, formData, body, _)
  let scheme = call_402656670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656670.makeUrl(scheme.get, call_402656670.host, call_402656670.base,
                                   call_402656670.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656670, uri, valid, _)

proc call*(call_402656671: Call_DeleteConfigurationProfile_402656658;
           ApplicationId: string; ConfigurationProfileId: string): Recallable =
  ## deleteConfigurationProfile
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ##   
                                                                                                                  ## ApplicationId: string (required)
                                                                                                                  ##                
                                                                                                                  ## : 
                                                                                                                  ## The 
                                                                                                                  ## application 
                                                                                                                  ## ID 
                                                                                                                  ## that 
                                                                                                                  ## includes 
                                                                                                                  ## the 
                                                                                                                  ## configuration 
                                                                                                                  ## profile 
                                                                                                                  ## you 
                                                                                                                  ## want 
                                                                                                                  ## to 
                                                                                                                  ## delete.
  ##   
                                                                                                                            ## ConfigurationProfileId: string (required)
                                                                                                                            ##                         
                                                                                                                            ## : 
                                                                                                                            ## The 
                                                                                                                            ## ID 
                                                                                                                            ## of 
                                                                                                                            ## the 
                                                                                                                            ## configuration 
                                                                                                                            ## profile 
                                                                                                                            ## you 
                                                                                                                            ## want 
                                                                                                                            ## to 
                                                                                                                            ## delete.
  var path_402656672 = newJObject()
  add(path_402656672, "ApplicationId", newJString(ApplicationId))
  add(path_402656672, "ConfigurationProfileId",
      newJString(ConfigurationProfileId))
  result = call_402656671.call(path_402656672, nil, nil, nil, nil)

var deleteConfigurationProfile* = Call_DeleteConfigurationProfile_402656658(
    name: "deleteConfigurationProfile", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_DeleteConfigurationProfile_402656659, base: "/",
    makeUrl: url_DeleteConfigurationProfile_402656660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentStrategy_402656690 = ref object of OpenApiRestCall_402656038
proc url_DeleteDeploymentStrategy_402656692(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeploymentStrategyId" in path,
         "`DeploymentStrategyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/deployementstrategies/"),
                 (kind: VariableSegment, value: "DeploymentStrategyId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeploymentStrategy_402656691(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
                                 ##                       : The ID of the deployment strategy you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_402656693 = path.getOrDefault("DeploymentStrategyId")
  valid_402656693 = validateParameter(valid_402656693, JString, required = true,
                                      default = nil)
  if valid_402656693 != nil:
    section.add "DeploymentStrategyId", valid_402656693
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
  var valid_402656694 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Security-Token", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Signature")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Signature", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Algorithm", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Date")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Date", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Credential")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Credential", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656701: Call_DeleteDeploymentStrategy_402656690;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
                                                                                         ## 
  let valid = call_402656701.validator(path, query, header, formData, body, _)
  let scheme = call_402656701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656701.makeUrl(scheme.get, call_402656701.host, call_402656701.base,
                                   call_402656701.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656701, uri, valid, _)

proc call*(call_402656702: Call_DeleteDeploymentStrategy_402656690;
           DeploymentStrategyId: string): Recallable =
  ## deleteDeploymentStrategy
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ##   
                                                                                                              ## DeploymentStrategyId: string (required)
                                                                                                              ##                       
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## ID 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## deployment 
                                                                                                              ## strategy 
                                                                                                              ## you 
                                                                                                              ## want 
                                                                                                              ## to 
                                                                                                              ## delete.
  var path_402656703 = newJObject()
  add(path_402656703, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_402656702.call(path_402656703, nil, nil, nil, nil)

var deleteDeploymentStrategy* = Call_DeleteDeploymentStrategy_402656690(
    name: "deleteDeploymentStrategy", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com",
    route: "/deployementstrategies/{DeploymentStrategyId}",
    validator: validate_DeleteDeploymentStrategy_402656691, base: "/",
    makeUrl: url_DeleteDeploymentStrategy_402656692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnvironment_402656704 = ref object of OpenApiRestCall_402656038
proc url_GetEnvironment_402656706(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "EnvironmentId" in path, "`EnvironmentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/environments/"),
                 (kind: VariableSegment, value: "EnvironmentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEnvironment_402656705(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The ID of the application that includes the environment you want to get.
  ##   
                                                                                                                             ## EnvironmentId: JString (required)
                                                                                                                             ##                
                                                                                                                             ## : 
                                                                                                                             ## The 
                                                                                                                             ## ID 
                                                                                                                             ## of 
                                                                                                                             ## the 
                                                                                                                             ## environment 
                                                                                                                             ## you 
                                                                                                                             ## wnat 
                                                                                                                             ## to 
                                                                                                                             ## get.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656707 = path.getOrDefault("ApplicationId")
  valid_402656707 = validateParameter(valid_402656707, JString, required = true,
                                      default = nil)
  if valid_402656707 != nil:
    section.add "ApplicationId", valid_402656707
  var valid_402656708 = path.getOrDefault("EnvironmentId")
  valid_402656708 = validateParameter(valid_402656708, JString, required = true,
                                      default = nil)
  if valid_402656708 != nil:
    section.add "EnvironmentId", valid_402656708
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
  var valid_402656709 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Security-Token", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Signature")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Signature", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Algorithm", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Date")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Date", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Credential")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Credential", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656716: Call_GetEnvironment_402656704; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
                                                                                         ## 
  let valid = call_402656716.validator(path, query, header, formData, body, _)
  let scheme = call_402656716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656716.makeUrl(scheme.get, call_402656716.host, call_402656716.base,
                                   call_402656716.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656716, uri, valid, _)

proc call*(call_402656717: Call_GetEnvironment_402656704; ApplicationId: string;
           EnvironmentId: string): Recallable =
  ## getEnvironment
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## ApplicationId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## application 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## includes 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## environment 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## get.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## EnvironmentId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## environment 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## wnat 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## get.
  var path_402656718 = newJObject()
  add(path_402656718, "ApplicationId", newJString(ApplicationId))
  add(path_402656718, "EnvironmentId", newJString(EnvironmentId))
  result = call_402656717.call(path_402656718, nil, nil, nil, nil)

var getEnvironment* = Call_GetEnvironment_402656704(name: "getEnvironment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_GetEnvironment_402656705, base: "/",
    makeUrl: url_GetEnvironment_402656706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_402656734 = ref object of OpenApiRestCall_402656038
proc url_UpdateEnvironment_402656736(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "EnvironmentId" in path, "`EnvironmentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/environments/"),
                 (kind: VariableSegment, value: "EnvironmentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEnvironment_402656735(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an environment.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID.
  ##   
                                                                        ## EnvironmentId: JString (required)
                                                                        ##                
                                                                        ## : 
                                                                        ## The 
                                                                        ## environment 
                                                                        ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656737 = path.getOrDefault("ApplicationId")
  valid_402656737 = validateParameter(valid_402656737, JString, required = true,
                                      default = nil)
  if valid_402656737 != nil:
    section.add "ApplicationId", valid_402656737
  var valid_402656738 = path.getOrDefault("EnvironmentId")
  valid_402656738 = validateParameter(valid_402656738, JString, required = true,
                                      default = nil)
  if valid_402656738 != nil:
    section.add "EnvironmentId", valid_402656738
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
  var valid_402656739 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Security-Token", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Signature")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Signature", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Algorithm", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-Date")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-Date", valid_402656743
  var valid_402656744 = header.getOrDefault("X-Amz-Credential")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Credential", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656745
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

proc call*(call_402656747: Call_UpdateEnvironment_402656734;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an environment.
                                                                                         ## 
  let valid = call_402656747.validator(path, query, header, formData, body, _)
  let scheme = call_402656747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656747.makeUrl(scheme.get, call_402656747.host, call_402656747.base,
                                   call_402656747.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656747, uri, valid, _)

proc call*(call_402656748: Call_UpdateEnvironment_402656734;
           ApplicationId: string; EnvironmentId: string; body: JsonNode): Recallable =
  ## updateEnvironment
  ## Updates an environment.
  ##   ApplicationId: string (required)
                            ##                : The application ID.
  ##   
                                                                   ## EnvironmentId: string (required)
                                                                   ##                
                                                                   ## : 
                                                                   ## The 
                                                                   ## environment ID.
  ##   
                                                                                     ## body: JObject (required)
  var path_402656749 = newJObject()
  var body_402656750 = newJObject()
  add(path_402656749, "ApplicationId", newJString(ApplicationId))
  add(path_402656749, "EnvironmentId", newJString(EnvironmentId))
  if body != nil:
    body_402656750 = body
  result = call_402656748.call(path_402656749, nil, nil, nil, body_402656750)

var updateEnvironment* = Call_UpdateEnvironment_402656734(
    name: "updateEnvironment", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_UpdateEnvironment_402656735, base: "/",
    makeUrl: url_UpdateEnvironment_402656736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_402656719 = ref object of OpenApiRestCall_402656038
proc url_DeleteEnvironment_402656721(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "EnvironmentId" in path, "`EnvironmentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/environments/"),
                 (kind: VariableSegment, value: "EnvironmentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEnvironment_402656720(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID that includes the environment you want to delete.
  ##   
                                                                                                                         ## EnvironmentId: JString (required)
                                                                                                                         ##                
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## ID 
                                                                                                                         ## of 
                                                                                                                         ## the 
                                                                                                                         ## environment 
                                                                                                                         ## you 
                                                                                                                         ## want 
                                                                                                                         ## to 
                                                                                                                         ## delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656722 = path.getOrDefault("ApplicationId")
  valid_402656722 = validateParameter(valid_402656722, JString, required = true,
                                      default = nil)
  if valid_402656722 != nil:
    section.add "ApplicationId", valid_402656722
  var valid_402656723 = path.getOrDefault("EnvironmentId")
  valid_402656723 = validateParameter(valid_402656723, JString, required = true,
                                      default = nil)
  if valid_402656723 != nil:
    section.add "EnvironmentId", valid_402656723
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
  var valid_402656724 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Security-Token", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Signature")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Signature", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Algorithm", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Date")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Date", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Credential")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Credential", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656731: Call_DeleteEnvironment_402656719;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
                                                                                         ## 
  let valid = call_402656731.validator(path, query, header, formData, body, _)
  let scheme = call_402656731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656731.makeUrl(scheme.get, call_402656731.host, call_402656731.base,
                                   call_402656731.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656731, uri, valid, _)

proc call*(call_402656732: Call_DeleteEnvironment_402656719;
           ApplicationId: string; EnvironmentId: string): Recallable =
  ## deleteEnvironment
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ##   
                                                                                                ## ApplicationId: string (required)
                                                                                                ##                
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## application 
                                                                                                ## ID 
                                                                                                ## that 
                                                                                                ## includes 
                                                                                                ## the 
                                                                                                ## environment 
                                                                                                ## you 
                                                                                                ## want 
                                                                                                ## to 
                                                                                                ## delete.
  ##   
                                                                                                          ## EnvironmentId: string (required)
                                                                                                          ##                
                                                                                                          ## : 
                                                                                                          ## The 
                                                                                                          ## ID 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## environment 
                                                                                                          ## you 
                                                                                                          ## want 
                                                                                                          ## to 
                                                                                                          ## delete.
  var path_402656733 = newJObject()
  add(path_402656733, "ApplicationId", newJString(ApplicationId))
  add(path_402656733, "EnvironmentId", newJString(EnvironmentId))
  result = call_402656732.call(path_402656733, nil, nil, nil, nil)

var deleteEnvironment* = Call_DeleteEnvironment_402656719(
    name: "deleteEnvironment", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_DeleteEnvironment_402656720, base: "/",
    makeUrl: url_DeleteEnvironment_402656721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfiguration_402656751 = ref object of OpenApiRestCall_402656038
proc url_GetConfiguration_402656753(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Application" in path, "`Application` is a required path parameter"
  assert "Environment" in path, "`Environment` is a required path parameter"
  assert "Configuration" in path, "`Configuration` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "Application"),
                 (kind: ConstantSegment, value: "/environments/"),
                 (kind: VariableSegment, value: "Environment"),
                 (kind: ConstantSegment, value: "/configurations/"),
                 (kind: VariableSegment, value: "Configuration"),
                 (kind: ConstantSegment, value: "#client_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfiguration_402656752(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve information about a configuration.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Environment: JString (required)
                                 ##              : The environment to get.
  ##   
                                                                          ## Configuration: JString (required)
                                                                          ##                
                                                                          ## : 
                                                                          ## The 
                                                                          ## configuration 
                                                                          ## to 
                                                                          ## get.
  ##   
                                                                                 ## Application: JString (required)
                                                                                 ##              
                                                                                 ## : 
                                                                                 ## The 
                                                                                 ## application 
                                                                                 ## to 
                                                                                 ## get.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `Environment` field"
  var valid_402656754 = path.getOrDefault("Environment")
  valid_402656754 = validateParameter(valid_402656754, JString, required = true,
                                      default = nil)
  if valid_402656754 != nil:
    section.add "Environment", valid_402656754
  var valid_402656755 = path.getOrDefault("Configuration")
  valid_402656755 = validateParameter(valid_402656755, JString, required = true,
                                      default = nil)
  if valid_402656755 != nil:
    section.add "Configuration", valid_402656755
  var valid_402656756 = path.getOrDefault("Application")
  valid_402656756 = validateParameter(valid_402656756, JString, required = true,
                                      default = nil)
  if valid_402656756 != nil:
    section.add "Application", valid_402656756
  result.add "path", section
  ## parameters in `query` object:
  ##   client_configuration_version: JString
                                  ##                               : The configuration version returned in the most recent GetConfiguration response.
  ##   
                                                                                                                                                     ## client_id: JString (required)
                                                                                                                                                     ##            
                                                                                                                                                     ## : 
                                                                                                                                                     ## A 
                                                                                                                                                     ## unique 
                                                                                                                                                     ## ID 
                                                                                                                                                     ## to 
                                                                                                                                                     ## identify 
                                                                                                                                                     ## the 
                                                                                                                                                     ## client 
                                                                                                                                                     ## for 
                                                                                                                                                     ## the 
                                                                                                                                                     ## configuration. 
                                                                                                                                                     ## This 
                                                                                                                                                     ## ID 
                                                                                                                                                     ## enables 
                                                                                                                                                     ## AppConfig 
                                                                                                                                                     ## to 
                                                                                                                                                     ## deploy 
                                                                                                                                                     ## the 
                                                                                                                                                     ## configuration 
                                                                                                                                                     ## in 
                                                                                                                                                     ## intervals, 
                                                                                                                                                     ## as 
                                                                                                                                                     ## defined 
                                                                                                                                                     ## in 
                                                                                                                                                     ## the 
                                                                                                                                                     ## deployment 
                                                                                                                                                     ## strategy.
  section = newJObject()
  var valid_402656757 = query.getOrDefault("client_configuration_version")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "client_configuration_version", valid_402656757
  assert query != nil,
         "query argument is necessary due to required `client_id` field"
  var valid_402656758 = query.getOrDefault("client_id")
  valid_402656758 = validateParameter(valid_402656758, JString, required = true,
                                      default = nil)
  if valid_402656758 != nil:
    section.add "client_id", valid_402656758
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
  var valid_402656759 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Security-Token", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-Signature")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Signature", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Algorithm", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Date")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Date", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Credential")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Credential", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656766: Call_GetConfiguration_402656751;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a configuration.
                                                                                         ## 
  let valid = call_402656766.validator(path, query, header, formData, body, _)
  let scheme = call_402656766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656766.makeUrl(scheme.get, call_402656766.host, call_402656766.base,
                                   call_402656766.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656766, uri, valid, _)

proc call*(call_402656767: Call_GetConfiguration_402656751; Environment: string;
           Configuration: string; Application: string; clientId: string;
           clientConfigurationVersion: string = ""): Recallable =
  ## getConfiguration
  ## Retrieve information about a configuration.
  ##   Environment: string (required)
                                                ##              : The environment to get.
  ##   
                                                                                         ## clientConfigurationVersion: string
                                                                                         ##                             
                                                                                         ## : 
                                                                                         ## The 
                                                                                         ## configuration 
                                                                                         ## version 
                                                                                         ## returned 
                                                                                         ## in 
                                                                                         ## the 
                                                                                         ## most 
                                                                                         ## recent 
                                                                                         ## GetConfiguration 
                                                                                         ## response.
  ##   
                                                                                                     ## Configuration: string (required)
                                                                                                     ##                
                                                                                                     ## : 
                                                                                                     ## The 
                                                                                                     ## configuration 
                                                                                                     ## to 
                                                                                                     ## get.
  ##   
                                                                                                            ## Application: string (required)
                                                                                                            ##              
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## application 
                                                                                                            ## to 
                                                                                                            ## get.
  ##   
                                                                                                                   ## clientId: string (required)
                                                                                                                   ##           
                                                                                                                   ## : 
                                                                                                                   ## A 
                                                                                                                   ## unique 
                                                                                                                   ## ID 
                                                                                                                   ## to 
                                                                                                                   ## identify 
                                                                                                                   ## the 
                                                                                                                   ## client 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## configuration. 
                                                                                                                   ## This 
                                                                                                                   ## ID 
                                                                                                                   ## enables 
                                                                                                                   ## AppConfig 
                                                                                                                   ## to 
                                                                                                                   ## deploy 
                                                                                                                   ## the 
                                                                                                                   ## configuration 
                                                                                                                   ## in 
                                                                                                                   ## intervals, 
                                                                                                                   ## as 
                                                                                                                   ## defined 
                                                                                                                   ## in 
                                                                                                                   ## the 
                                                                                                                   ## deployment 
                                                                                                                   ## strategy.
  var path_402656768 = newJObject()
  var query_402656769 = newJObject()
  add(path_402656768, "Environment", newJString(Environment))
  add(query_402656769, "client_configuration_version",
      newJString(clientConfigurationVersion))
  add(path_402656768, "Configuration", newJString(Configuration))
  add(path_402656768, "Application", newJString(Application))
  add(query_402656769, "client_id", newJString(clientId))
  result = call_402656767.call(path_402656768, query_402656769, nil, nil, nil)

var getConfiguration* = Call_GetConfiguration_402656751(
    name: "getConfiguration", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/applications/{Application}/environments/{Environment}/configurations/{Configuration}#client_id",
    validator: validate_GetConfiguration_402656752, base: "/",
    makeUrl: url_GetConfiguration_402656753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_402656770 = ref object of OpenApiRestCall_402656038
proc url_GetDeployment_402656772(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "EnvironmentId" in path, "`EnvironmentId` is a required path parameter"
  assert "DeploymentNumber" in path,
         "`DeploymentNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/environments/"),
                 (kind: VariableSegment, value: "EnvironmentId"),
                 (kind: ConstantSegment, value: "/deployments/"),
                 (kind: VariableSegment, value: "DeploymentNumber")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployment_402656771(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve information about a configuration deployment.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentNumber: JInt (required)
                                 ##                   : The sequence number of the deployment.
  ##   
                                                                                              ## ApplicationId: JString (required)
                                                                                              ##                
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## ID 
                                                                                              ## of 
                                                                                              ## the 
                                                                                              ## application 
                                                                                              ## that 
                                                                                              ## includes 
                                                                                              ## the 
                                                                                              ## deployment 
                                                                                              ## you 
                                                                                              ## want 
                                                                                              ## to 
                                                                                              ## get. 
  ##   
                                                                                                      ## EnvironmentId: JString (required)
                                                                                                      ##                
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## ID 
                                                                                                      ## of 
                                                                                                      ## the 
                                                                                                      ## environment 
                                                                                                      ## that 
                                                                                                      ## includes 
                                                                                                      ## the 
                                                                                                      ## deployment 
                                                                                                      ## you 
                                                                                                      ## want 
                                                                                                      ## to 
                                                                                                      ## get. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DeploymentNumber` field"
  var valid_402656773 = path.getOrDefault("DeploymentNumber")
  valid_402656773 = validateParameter(valid_402656773, JInt, required = true,
                                      default = nil)
  if valid_402656773 != nil:
    section.add "DeploymentNumber", valid_402656773
  var valid_402656774 = path.getOrDefault("ApplicationId")
  valid_402656774 = validateParameter(valid_402656774, JString, required = true,
                                      default = nil)
  if valid_402656774 != nil:
    section.add "ApplicationId", valid_402656774
  var valid_402656775 = path.getOrDefault("EnvironmentId")
  valid_402656775 = validateParameter(valid_402656775, JString, required = true,
                                      default = nil)
  if valid_402656775 != nil:
    section.add "EnvironmentId", valid_402656775
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
  var valid_402656776 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Security-Token", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-Signature")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Signature", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Algorithm", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Date")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Date", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Credential")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Credential", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656783: Call_GetDeployment_402656770; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a configuration deployment.
                                                                                         ## 
  let valid = call_402656783.validator(path, query, header, formData, body, _)
  let scheme = call_402656783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656783.makeUrl(scheme.get, call_402656783.host, call_402656783.base,
                                   call_402656783.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656783, uri, valid, _)

proc call*(call_402656784: Call_GetDeployment_402656770; DeploymentNumber: int;
           ApplicationId: string; EnvironmentId: string): Recallable =
  ## getDeployment
  ## Retrieve information about a configuration deployment.
  ##   DeploymentNumber: int (required)
                                                           ##                   : The sequence number of the deployment.
  ##   
                                                                                                                        ## ApplicationId: string (required)
                                                                                                                        ##                
                                                                                                                        ## : 
                                                                                                                        ## The 
                                                                                                                        ## ID 
                                                                                                                        ## of 
                                                                                                                        ## the 
                                                                                                                        ## application 
                                                                                                                        ## that 
                                                                                                                        ## includes 
                                                                                                                        ## the 
                                                                                                                        ## deployment 
                                                                                                                        ## you 
                                                                                                                        ## want 
                                                                                                                        ## to 
                                                                                                                        ## get. 
  ##   
                                                                                                                                ## EnvironmentId: string (required)
                                                                                                                                ##                
                                                                                                                                ## : 
                                                                                                                                ## The 
                                                                                                                                ## ID 
                                                                                                                                ## of 
                                                                                                                                ## the 
                                                                                                                                ## environment 
                                                                                                                                ## that 
                                                                                                                                ## includes 
                                                                                                                                ## the 
                                                                                                                                ## deployment 
                                                                                                                                ## you 
                                                                                                                                ## want 
                                                                                                                                ## to 
                                                                                                                                ## get. 
  var path_402656785 = newJObject()
  add(path_402656785, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_402656785, "ApplicationId", newJString(ApplicationId))
  add(path_402656785, "EnvironmentId", newJString(EnvironmentId))
  result = call_402656784.call(path_402656785, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_402656770(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_GetDeployment_402656771, base: "/",
    makeUrl: url_GetDeployment_402656772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeployment_402656786 = ref object of OpenApiRestCall_402656038
proc url_StopDeployment_402656788(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "EnvironmentId" in path, "`EnvironmentId` is a required path parameter"
  assert "DeploymentNumber" in path,
         "`DeploymentNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/environments/"),
                 (kind: VariableSegment, value: "EnvironmentId"),
                 (kind: ConstantSegment, value: "/deployments/"),
                 (kind: VariableSegment, value: "DeploymentNumber")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopDeployment_402656787(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentNumber: JInt (required)
                                 ##                   : The sequence number of the deployment.
  ##   
                                                                                              ## ApplicationId: JString (required)
                                                                                              ##                
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## application 
                                                                                              ## ID.
  ##   
                                                                                                    ## EnvironmentId: JString (required)
                                                                                                    ##                
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## environment 
                                                                                                    ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DeploymentNumber` field"
  var valid_402656789 = path.getOrDefault("DeploymentNumber")
  valid_402656789 = validateParameter(valid_402656789, JInt, required = true,
                                      default = nil)
  if valid_402656789 != nil:
    section.add "DeploymentNumber", valid_402656789
  var valid_402656790 = path.getOrDefault("ApplicationId")
  valid_402656790 = validateParameter(valid_402656790, JString, required = true,
                                      default = nil)
  if valid_402656790 != nil:
    section.add "ApplicationId", valid_402656790
  var valid_402656791 = path.getOrDefault("EnvironmentId")
  valid_402656791 = validateParameter(valid_402656791, JString, required = true,
                                      default = nil)
  if valid_402656791 != nil:
    section.add "EnvironmentId", valid_402656791
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
  var valid_402656792 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Security-Token", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Signature")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Signature", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Algorithm", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Date")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Date", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Credential")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Credential", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656799: Call_StopDeployment_402656786; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
                                                                                         ## 
  let valid = call_402656799.validator(path, query, header, formData, body, _)
  let scheme = call_402656799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656799.makeUrl(scheme.get, call_402656799.host, call_402656799.base,
                                   call_402656799.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656799, uri, valid, _)

proc call*(call_402656800: Call_StopDeployment_402656786; DeploymentNumber: int;
           ApplicationId: string; EnvironmentId: string): Recallable =
  ## stopDeployment
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ##   
                                                                                                                                                                                          ## DeploymentNumber: int (required)
                                                                                                                                                                                          ##                   
                                                                                                                                                                                          ## : 
                                                                                                                                                                                          ## The 
                                                                                                                                                                                          ## sequence 
                                                                                                                                                                                          ## number 
                                                                                                                                                                                          ## of 
                                                                                                                                                                                          ## the 
                                                                                                                                                                                          ## deployment.
  ##   
                                                                                                                                                                                                        ## ApplicationId: string (required)
                                                                                                                                                                                                        ##                
                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                        ## application 
                                                                                                                                                                                                        ## ID.
  ##   
                                                                                                                                                                                                              ## EnvironmentId: string (required)
                                                                                                                                                                                                              ##                
                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                              ## environment 
                                                                                                                                                                                                              ## ID.
  var path_402656801 = newJObject()
  add(path_402656801, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_402656801, "ApplicationId", newJString(ApplicationId))
  add(path_402656801, "EnvironmentId", newJString(EnvironmentId))
  result = call_402656800.call(path_402656801, nil, nil, nil, nil)

var stopDeployment* = Call_StopDeployment_402656786(name: "stopDeployment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_StopDeployment_402656787, base: "/",
    makeUrl: url_StopDeployment_402656788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStrategy_402656802 = ref object of OpenApiRestCall_402656038
proc url_GetDeploymentStrategy_402656804(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeploymentStrategyId" in path,
         "`DeploymentStrategyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/deploymentstrategies/"),
                 (kind: VariableSegment, value: "DeploymentStrategyId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeploymentStrategy_402656803(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
                                 ##                       : The ID of the deployment strategy to get.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_402656805 = path.getOrDefault("DeploymentStrategyId")
  valid_402656805 = validateParameter(valid_402656805, JString, required = true,
                                      default = nil)
  if valid_402656805 != nil:
    section.add "DeploymentStrategyId", valid_402656805
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
  var valid_402656806 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Security-Token", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Signature")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Signature", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Algorithm", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Date")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Date", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Credential")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Credential", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656813: Call_GetDeploymentStrategy_402656802;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
                                                                                         ## 
  let valid = call_402656813.validator(path, query, header, formData, body, _)
  let scheme = call_402656813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656813.makeUrl(scheme.get, call_402656813.host, call_402656813.base,
                                   call_402656813.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656813, uri, valid, _)

proc call*(call_402656814: Call_GetDeploymentStrategy_402656802;
           DeploymentStrategyId: string): Recallable =
  ## getDeploymentStrategy
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   
                                                                                                                                                                                                                                                                                                                                                                           ## DeploymentStrategyId: string (required)
                                                                                                                                                                                                                                                                                                                                                                           ##                       
                                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                                                                                                                                                                           ## ID 
                                                                                                                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                           ## deployment 
                                                                                                                                                                                                                                                                                                                                                                           ## strategy 
                                                                                                                                                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                                                                                                                                                           ## get.
  var path_402656815 = newJObject()
  add(path_402656815, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_402656814.call(path_402656815, nil, nil, nil, nil)

var getDeploymentStrategy* = Call_GetDeploymentStrategy_402656802(
    name: "getDeploymentStrategy", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_GetDeploymentStrategy_402656803, base: "/",
    makeUrl: url_GetDeploymentStrategy_402656804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeploymentStrategy_402656816 = ref object of OpenApiRestCall_402656038
proc url_UpdateDeploymentStrategy_402656818(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeploymentStrategyId" in path,
         "`DeploymentStrategyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/deploymentstrategies/"),
                 (kind: VariableSegment, value: "DeploymentStrategyId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeploymentStrategy_402656817(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates a deployment strategy.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
                                 ##                       : The deployment strategy ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_402656819 = path.getOrDefault("DeploymentStrategyId")
  valid_402656819 = validateParameter(valid_402656819, JString, required = true,
                                      default = nil)
  if valid_402656819 != nil:
    section.add "DeploymentStrategyId", valid_402656819
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
  var valid_402656820 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Security-Token", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Signature")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Signature", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Algorithm", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Date")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Date", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Credential")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Credential", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656826
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

proc call*(call_402656828: Call_UpdateDeploymentStrategy_402656816;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a deployment strategy.
                                                                                         ## 
  let valid = call_402656828.validator(path, query, header, formData, body, _)
  let scheme = call_402656828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656828.makeUrl(scheme.get, call_402656828.host, call_402656828.base,
                                   call_402656828.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656828, uri, valid, _)

proc call*(call_402656829: Call_UpdateDeploymentStrategy_402656816;
           body: JsonNode; DeploymentStrategyId: string): Recallable =
  ## updateDeploymentStrategy
  ## Updates a deployment strategy.
  ##   body: JObject (required)
  ##   DeploymentStrategyId: string (required)
                               ##                       : The deployment strategy ID.
  var path_402656830 = newJObject()
  var body_402656831 = newJObject()
  if body != nil:
    body_402656831 = body
  add(path_402656830, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_402656829.call(path_402656830, nil, nil, nil, body_402656831)

var updateDeploymentStrategy* = Call_UpdateDeploymentStrategy_402656816(
    name: "updateDeploymentStrategy", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_UpdateDeploymentStrategy_402656817, base: "/",
    makeUrl: url_UpdateDeploymentStrategy_402656818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_402656852 = ref object of OpenApiRestCall_402656038
proc url_StartDeployment_402656854(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "EnvironmentId" in path, "`EnvironmentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/environments/"),
                 (kind: VariableSegment, value: "EnvironmentId"),
                 (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartDeployment_402656853(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a deployment.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID.
  ##   
                                                                        ## EnvironmentId: JString (required)
                                                                        ##                
                                                                        ## : 
                                                                        ## The 
                                                                        ## environment 
                                                                        ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656855 = path.getOrDefault("ApplicationId")
  valid_402656855 = validateParameter(valid_402656855, JString, required = true,
                                      default = nil)
  if valid_402656855 != nil:
    section.add "ApplicationId", valid_402656855
  var valid_402656856 = path.getOrDefault("EnvironmentId")
  valid_402656856 = validateParameter(valid_402656856, JString, required = true,
                                      default = nil)
  if valid_402656856 != nil:
    section.add "EnvironmentId", valid_402656856
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
  var valid_402656857 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Security-Token", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Signature")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Signature", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Algorithm", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Date")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Date", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Credential")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Credential", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656863
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

proc call*(call_402656865: Call_StartDeployment_402656852; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a deployment.
                                                                                         ## 
  let valid = call_402656865.validator(path, query, header, formData, body, _)
  let scheme = call_402656865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656865.makeUrl(scheme.get, call_402656865.host, call_402656865.base,
                                   call_402656865.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656865, uri, valid, _)

proc call*(call_402656866: Call_StartDeployment_402656852;
           ApplicationId: string; EnvironmentId: string; body: JsonNode): Recallable =
  ## startDeployment
  ## Starts a deployment.
  ##   ApplicationId: string (required)
                         ##                : The application ID.
  ##   EnvironmentId: string (required)
                                                                ##                : The environment ID.
  ##   
                                                                                                       ## body: JObject (required)
  var path_402656867 = newJObject()
  var body_402656868 = newJObject()
  add(path_402656867, "ApplicationId", newJString(ApplicationId))
  add(path_402656867, "EnvironmentId", newJString(EnvironmentId))
  if body != nil:
    body_402656868 = body
  result = call_402656866.call(path_402656867, nil, nil, nil, body_402656868)

var startDeployment* = Call_StartDeployment_402656852(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_StartDeployment_402656853, base: "/",
    makeUrl: url_StartDeployment_402656854, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_402656832 = ref object of OpenApiRestCall_402656038
proc url_ListDeployments_402656834(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "EnvironmentId" in path, "`EnvironmentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/environments/"),
                 (kind: VariableSegment, value: "EnvironmentId"),
                 (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDeployments_402656833(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the deployments for an environment.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID.
  ##   
                                                                        ## EnvironmentId: JString (required)
                                                                        ##                
                                                                        ## : 
                                                                        ## The 
                                                                        ## environment 
                                                                        ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656835 = path.getOrDefault("ApplicationId")
  valid_402656835 = validateParameter(valid_402656835, JString, required = true,
                                      default = nil)
  if valid_402656835 != nil:
    section.add "ApplicationId", valid_402656835
  var valid_402656836 = path.getOrDefault("EnvironmentId")
  valid_402656836 = validateParameter(valid_402656836, JString, required = true,
                                      default = nil)
  if valid_402656836 != nil:
    section.add "EnvironmentId", valid_402656836
  result.add "path", section
  ## parameters in `query` object:
  ##   max_results: JInt
                                  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   
                                                                                                                                                                                                                ## MaxResults: JString
                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                ## limit
  ##   
                                                                                                                                                                                                                        ## NextToken: JString
                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                        ## token
  ##   
                                                                                                                                                                                                                                ## next_token: JString
                                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                ## A 
                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                ## start 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## list. 
                                                                                                                                                                                                                                ## Use 
                                                                                                                                                                                                                                ## this 
                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                ## get 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## next 
                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                ## results.
  section = newJObject()
  var valid_402656837 = query.getOrDefault("max_results")
  valid_402656837 = validateParameter(valid_402656837, JInt, required = false,
                                      default = nil)
  if valid_402656837 != nil:
    section.add "max_results", valid_402656837
  var valid_402656838 = query.getOrDefault("MaxResults")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "MaxResults", valid_402656838
  var valid_402656839 = query.getOrDefault("NextToken")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "NextToken", valid_402656839
  var valid_402656840 = query.getOrDefault("next_token")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "next_token", valid_402656840
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
  var valid_402656841 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Security-Token", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Signature")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Signature", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Algorithm", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Date")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Date", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Credential")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Credential", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656848: Call_ListDeployments_402656832; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the deployments for an environment.
                                                                                         ## 
  let valid = call_402656848.validator(path, query, header, formData, body, _)
  let scheme = call_402656848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656848.makeUrl(scheme.get, call_402656848.host, call_402656848.base,
                                   call_402656848.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656848, uri, valid, _)

proc call*(call_402656849: Call_ListDeployments_402656832;
           ApplicationId: string; EnvironmentId: string; maxResults: int = 0;
           MaxResults: string = ""; NextToken: string = "";
           nextToken: string = ""): Recallable =
  ## listDeployments
  ## Lists the deployments for an environment.
  ##   maxResults: int
                                              ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   
                                                                                                                                                                                                                           ## ApplicationId: string (required)
                                                                                                                                                                                                                           ##                
                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                           ## application 
                                                                                                                                                                                                                           ## ID.
  ##   
                                                                                                                                                                                                                                 ## EnvironmentId: string (required)
                                                                                                                                                                                                                                 ##                
                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                 ## environment 
                                                                                                                                                                                                                                 ## ID.
  ##   
                                                                                                                                                                                                                                       ## MaxResults: string
                                                                                                                                                                                                                                       ##             
                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                                                       ## limit
  ##   
                                                                                                                                                                                                                                               ## NextToken: string
                                                                                                                                                                                                                                               ##            
                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                                               ## token
  ##   
                                                                                                                                                                                                                                                       ## nextToken: string
                                                                                                                                                                                                                                                       ##            
                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                       ## A 
                                                                                                                                                                                                                                                       ## token 
                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                       ## start 
                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                       ## list. 
                                                                                                                                                                                                                                                       ## Use 
                                                                                                                                                                                                                                                       ## this 
                                                                                                                                                                                                                                                       ## token 
                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                       ## get 
                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                       ## next 
                                                                                                                                                                                                                                                       ## set 
                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                       ## results.
  var path_402656850 = newJObject()
  var query_402656851 = newJObject()
  add(query_402656851, "max_results", newJInt(maxResults))
  add(path_402656850, "ApplicationId", newJString(ApplicationId))
  add(path_402656850, "EnvironmentId", newJString(EnvironmentId))
  add(query_402656851, "MaxResults", newJString(MaxResults))
  add(query_402656851, "NextToken", newJString(NextToken))
  add(query_402656851, "next_token", newJString(nextToken))
  result = call_402656849.call(path_402656850, query_402656851, nil, nil, nil)

var listDeployments* = Call_ListDeployments_402656832(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_ListDeployments_402656833, base: "/",
    makeUrl: url_ListDeployments_402656834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656883 = ref object of OpenApiRestCall_402656038
proc url_TagResource_402656885(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656884(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
                                 ##              : The ARN of the resource for which to retrieve tags.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ResourceArn` field"
  var valid_402656886 = path.getOrDefault("ResourceArn")
  valid_402656886 = validateParameter(valid_402656886, JString, required = true,
                                      default = nil)
  if valid_402656886 != nil:
    section.add "ResourceArn", valid_402656886
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
  var valid_402656887 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Security-Token", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Signature")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Signature", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Algorithm", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Date")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Date", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Credential")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Credential", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656893
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

proc call*(call_402656895: Call_TagResource_402656883; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
                                                                                         ## 
  let valid = call_402656895.validator(path, query, header, formData, body, _)
  let scheme = call_402656895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656895.makeUrl(scheme.get, call_402656895.host, call_402656895.base,
                                   call_402656895.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656895, uri, valid, _)

proc call*(call_402656896: Call_TagResource_402656883; body: JsonNode;
           ResourceArn: string): Recallable =
  ## tagResource
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ##   
                                                                                                                                                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                         ## ResourceArn: string (required)
                                                                                                                                                                                                                                                                         ##              
                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                         ## ARN 
                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                         ## resource 
                                                                                                                                                                                                                                                                         ## for 
                                                                                                                                                                                                                                                                         ## which 
                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                         ## retrieve 
                                                                                                                                                                                                                                                                         ## tags.
  var path_402656897 = newJObject()
  var body_402656898 = newJObject()
  if body != nil:
    body_402656898 = body
  add(path_402656897, "ResourceArn", newJString(ResourceArn))
  result = call_402656896.call(path_402656897, nil, nil, nil, body_402656898)

var tagResource* = Call_TagResource_402656883(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/tags/{ResourceArn}", validator: validate_TagResource_402656884,
    base: "/", makeUrl: url_TagResource_402656885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656869 = ref object of OpenApiRestCall_402656038
proc url_ListTagsForResource_402656871(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656870(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the list of key-value tags assigned to the resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
                                 ##              : The resource ARN.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ResourceArn` field"
  var valid_402656872 = path.getOrDefault("ResourceArn")
  valid_402656872 = validateParameter(valid_402656872, JString, required = true,
                                      default = nil)
  if valid_402656872 != nil:
    section.add "ResourceArn", valid_402656872
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
  var valid_402656873 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Security-Token", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Signature")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Signature", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Algorithm", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-Date")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-Date", valid_402656877
  var valid_402656878 = header.getOrDefault("X-Amz-Credential")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-Credential", valid_402656878
  var valid_402656879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656880: Call_ListTagsForResource_402656869;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the list of key-value tags assigned to the resource.
                                                                                         ## 
  let valid = call_402656880.validator(path, query, header, formData, body, _)
  let scheme = call_402656880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656880.makeUrl(scheme.get, call_402656880.host, call_402656880.base,
                                   call_402656880.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656880, uri, valid, _)

proc call*(call_402656881: Call_ListTagsForResource_402656869;
           ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves the list of key-value tags assigned to the resource.
  ##   ResourceArn: string (required)
                                                                   ##              : The resource ARN.
  var path_402656882 = newJObject()
  add(path_402656882, "ResourceArn", newJString(ResourceArn))
  result = call_402656881.call(path_402656882, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656869(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_402656870, base: "/",
    makeUrl: url_ListTagsForResource_402656871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656899 = ref object of OpenApiRestCall_402656038
proc url_UntagResource_402656901(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "ResourceArn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656900(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a tag key and value from an AppConfig resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
                                 ##              : The ARN of the resource for which to remove tags.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ResourceArn` field"
  var valid_402656902 = path.getOrDefault("ResourceArn")
  valid_402656902 = validateParameter(valid_402656902, JString, required = true,
                                      default = nil)
  if valid_402656902 != nil:
    section.add "ResourceArn", valid_402656902
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The tag keys to delete.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656903 = query.getOrDefault("tagKeys")
  valid_402656903 = validateParameter(valid_402656903, JArray, required = true,
                                      default = nil)
  if valid_402656903 != nil:
    section.add "tagKeys", valid_402656903
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
  var valid_402656904 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Security-Token", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Signature")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Signature", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-Algorithm", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-Date")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Date", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Credential")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Credential", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656911: Call_UntagResource_402656899; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a tag key and value from an AppConfig resource.
                                                                                         ## 
  let valid = call_402656911.validator(path, query, header, formData, body, _)
  let scheme = call_402656911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656911.makeUrl(scheme.get, call_402656911.host, call_402656911.base,
                                   call_402656911.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656911, uri, valid, _)

proc call*(call_402656912: Call_UntagResource_402656899; tagKeys: JsonNode;
           ResourceArn: string): Recallable =
  ## untagResource
  ## Deletes a tag key and value from an AppConfig resource.
  ##   tagKeys: JArray (required)
                                                            ##          : The tag keys to delete.
  ##   
                                                                                                 ## ResourceArn: string (required)
                                                                                                 ##              
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## ARN 
                                                                                                 ## of 
                                                                                                 ## the 
                                                                                                 ## resource 
                                                                                                 ## for 
                                                                                                 ## which 
                                                                                                 ## to 
                                                                                                 ## remove 
                                                                                                 ## tags.
  var path_402656913 = newJObject()
  var query_402656914 = newJObject()
  if tagKeys != nil:
    query_402656914.add "tagKeys", tagKeys
  add(path_402656913, "ResourceArn", newJString(ResourceArn))
  result = call_402656912.call(path_402656913, query_402656914, nil, nil, nil)

var untagResource* = Call_UntagResource_402656899(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_402656900,
    base: "/", makeUrl: url_UntagResource_402656901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ValidateConfiguration_402656915 = ref object of OpenApiRestCall_402656038
proc url_ValidateConfiguration_402656917(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ApplicationId" in path, "`ApplicationId` is a required path parameter"
  assert "ConfigurationProfileId" in path,
         "`ConfigurationProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/applications/"),
                 (kind: VariableSegment, value: "ApplicationId"),
                 (kind: ConstantSegment, value: "/configurationprofiles/"),
                 (kind: VariableSegment, value: "ConfigurationProfileId"), (
        kind: ConstantSegment, value: "/validators#configuration_version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ValidateConfiguration_402656916(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Uses the validators in a configuration profile to validate a configuration.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
                                 ##                : The application ID.
  ##   
                                                                        ## ConfigurationProfileId: JString (required)
                                                                        ##                         
                                                                        ## : 
                                                                        ## The 
                                                                        ## configuration 
                                                                        ## profile 
                                                                        ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ApplicationId` field"
  var valid_402656918 = path.getOrDefault("ApplicationId")
  valid_402656918 = validateParameter(valid_402656918, JString, required = true,
                                      default = nil)
  if valid_402656918 != nil:
    section.add "ApplicationId", valid_402656918
  var valid_402656919 = path.getOrDefault("ConfigurationProfileId")
  valid_402656919 = validateParameter(valid_402656919, JString, required = true,
                                      default = nil)
  if valid_402656919 != nil:
    section.add "ConfigurationProfileId", valid_402656919
  result.add "path", section
  ## parameters in `query` object:
  ##   configuration_version: JString (required)
                                  ##                        : The version of the configuration to validate.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `configuration_version` field"
  var valid_402656920 = query.getOrDefault("configuration_version")
  valid_402656920 = validateParameter(valid_402656920, JString, required = true,
                                      default = nil)
  if valid_402656920 != nil:
    section.add "configuration_version", valid_402656920
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
  var valid_402656921 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Security-Token", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Signature")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Signature", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656923
  var valid_402656924 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-Algorithm", valid_402656924
  var valid_402656925 = header.getOrDefault("X-Amz-Date")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-Date", valid_402656925
  var valid_402656926 = header.getOrDefault("X-Amz-Credential")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Credential", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656928: Call_ValidateConfiguration_402656915;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Uses the validators in a configuration profile to validate a configuration.
                                                                                         ## 
  let valid = call_402656928.validator(path, query, header, formData, body, _)
  let scheme = call_402656928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656928.makeUrl(scheme.get, call_402656928.host, call_402656928.base,
                                   call_402656928.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656928, uri, valid, _)

proc call*(call_402656929: Call_ValidateConfiguration_402656915;
           configurationVersion: string; ApplicationId: string;
           ConfigurationProfileId: string): Recallable =
  ## validateConfiguration
  ## Uses the validators in a configuration profile to validate a configuration.
  ##   
                                                                                ## configurationVersion: string (required)
                                                                                ##                       
                                                                                ## : 
                                                                                ## The 
                                                                                ## version 
                                                                                ## of 
                                                                                ## the 
                                                                                ## configuration 
                                                                                ## to 
                                                                                ## validate.
  ##   
                                                                                            ## ApplicationId: string (required)
                                                                                            ##                
                                                                                            ## : 
                                                                                            ## The 
                                                                                            ## application 
                                                                                            ## ID.
  ##   
                                                                                                  ## ConfigurationProfileId: string (required)
                                                                                                  ##                         
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## configuration 
                                                                                                  ## profile 
                                                                                                  ## ID.
  var path_402656930 = newJObject()
  var query_402656931 = newJObject()
  add(query_402656931, "configuration_version", newJString(configurationVersion))
  add(path_402656930, "ApplicationId", newJString(ApplicationId))
  add(path_402656930, "ConfigurationProfileId",
      newJString(ConfigurationProfileId))
  result = call_402656929.call(path_402656930, query_402656931, nil, nil, nil)

var validateConfiguration* = Call_ValidateConfiguration_402656915(
    name: "validateConfiguration", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}/validators#configuration_version",
    validator: validate_ValidateConfiguration_402656916, base: "/",
    makeUrl: url_ValidateConfiguration_402656917,
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